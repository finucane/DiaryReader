//
//  AddViewController.m
//  diaryreader
//
//  Created by finucane on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AddViewController.h"
#import "UrlChecker.h"
#import "Downloader.h"
#import "insist.h"
#import "Library.h"

@implementation AddViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil appDelegate:(AppDelegate*)anAppDelegate delegate:(id<AddViewControllerDelegate>)aDelegate library:(Library*)aLibrary url:(NSString*)aUrl
{
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
  {
    appDelegate = anAppDelegate;
    library = [aLibrary retain];
    delegate = aDelegate;
    blog = nil;
    urlChecker = nil;
    downloader = nil;
    blogFetcher = nil;
    url = [aUrl retain];//can be nil
  }
  return self;
}


/*if there was a url specified, set it*/
- (void)viewDidLoad
{
  [super viewDidLoad];
  insist (downloadTextField);
  if (url)
  {
    downloadTextField.text = url;
    [downloadTextField becomeFirstResponder];   
  }
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (void)dealloc
{
  [library release];
  [blog release];
  [urlChecker release];
  [downloader release];
  [blogFetcher release];
  [url release];
  [activityIndicator release];
  [progressView release];
  [downloadTextField release];
  [cancelButton release];
  [super dealloc];
}


- (void) startAnimating
{
  [activityIndicator setHidden:NO];
  [activityIndicator startAnimating];

  /*disable the textfield so the user can't bring up the keyboard and press go button to start another download during the current download*/
  [downloadTextField setEnabled:NO];
  
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
- (void) stopAnimating
{
  [activityIndicator setHidden:YES];
  [activityIndicator stopAnimating];
  [activityLabel setText:@""];  
  [downloadTextField setEnabled:YES];
  [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (IBAction)download:(id)sender
{
  insist (downloadTextField);
  
  [downloadTextField resignFirstResponder];
  NSString*s = downloadTextField.text;
  
  if ([s isEqualToString:@"testapp"])
  {
    testApp = YES;
    [delegate addViewController:self didAddBlog:nil];
    return;
  }
  /*start downloading, the first step is verifying the URL*/
  
  urlChecker = [[UrlChecker alloc] initWithDelegate:self timeout:[appDelegate timeout]];
  insist (urlChecker);  
  
  [blog release];
  blog = nil;
  [self startAnimating];
  [urlChecker checkUrl:s];
}

/*stop whatever's running. this might take a while but in the meantime this whole viewcontroller will be released*/
-(IBAction)cancel:(id)sender
{
  if (downloader)
    [downloader cancel];
  if (urlChecker)
    [urlChecker cancel];
  if (blogFetcher)
  {
    [blogFetcher retain]; //keep it around, it will free itself when it's done cancelling
    [blogFetcher cancel];
  }

  [self stopAnimating];
  [delegate addViewController:self didAddBlog:nil];
}

- (void) urlCheckerStatusChanged:(UrlChecker*)urlChecker status:(NSString*)status
{
  insist (self && activityLabel);
  [activityLabel setText:status];
}

- (void) urlCheckerFailed:(UrlChecker*)checker reason:(NSString*)reason
{
  insist (self && activityIndicator && urlChecker && urlChecker == checker);
  [self stopAnimating];
  [appDelegate alertWithTitle:@"Not a Valid Blog" message:reason modal:YES];
  [urlChecker release];
  urlChecker = nil;
  [downloadTextField becomeFirstResponder];
  
  [self stopAnimating];
}

- (void) urlCheckerFinished:(UrlChecker*)checker
{
  insist (self && activityIndicator && urlChecker && urlChecker == checker);
  [activityLabel setText:@""];  
  
  /*we now have a valid blogID. if it already exists, tell the user*/
  NSString*blogID = [urlChecker getBlogID];
  insist (blogID);
  
  insist (library);
  Blog*b;
  if ((b = [library getBlogWithID:blogID]))
  {
    [appDelegate alertWithTitle:@"Blog already in Library" message:[NSString stringWithFormat:@"The blog for this URL is already in your library as \"%@\".", [b getTitle]] modal:YES];
    [urlChecker release];
    urlChecker = nil;
    [self stopAnimating];
    return;
  }

  /*now we have a good blogID. use it to download the blog*/
  
  /*first make sure there are no pieces this blog from some corruption previously*/
  [Library wipeFromDisk:blogID];

  /*first make an empty blog*/
  blog = [[Blog alloc] initWithBlogID:blogID path:[Library pathForBlogID:blogID]];
  insist (blog);
  
  /*set the default title to be the url*/
  [blog setTitle: [downloadTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];

  /*get ready to write into it*/
  [blog open];
  [blog beginUpdate];
  
  /*don't need the urlChecker anymore*/
  [urlChecker release];
  urlChecker = nil;
  
  /*now make a downloader to download into the blog*/
  downloader = [[Downloader alloc] initWithDelegate:self timeout:[appDelegate timeout] blog:blog];
  insist (downloader);  
  
  /*start downloading*/
  [NSThread detachNewThreadSelector:@selector (download:) toTarget:downloader withObject:nil];
}

- (void) downloaderStatusChanged:(Downloader*)downloader status:(NSString*)status
{
  insist (self && activityLabel);
  [activityLabel setText:status];
}

- (void) downloaderFailed:(Downloader*)aDownloader reason:(NSString*)reason
{
  insist (self && activityIndicator && downloader && downloader == aDownloader);
  [self stopAnimating];
  //[progressView setHidden:YES];

  [appDelegate alertWithTitle:@"Couldn't Get Entries from Blog" message:reason modal:YES];
  [downloader release]; downloader = nil;

  /*leave the window up in case it's a timeout or something, so the user can just try again*/
  [blog failUpdate];
  [self stopAnimating];
  [downloadTextField becomeFirstResponder];
}


- (void) downloaderFinished:(Downloader*)aDownloader
{
  insist (self && activityIndicator && downloader && downloader == aDownloader && blog);
  insist (library);
  
  /*commit all the new entries to the blog*/
  [progressView setProgress:1.0];
  
  /*check to see if the downloaded had summaries. in this case we need to do more work before we can do all the endUpdate stuff.*/
  if ([blog hasUrls])
  {
    NSArray*urls = [blog getUrls];
    insist (urls);
    int count = [urls count];
    insist (count > 0);
    
    [appDelegate alertWithTitle:@"Summary Only Blog"
                        message:@"This blog does not share content with the Google Blogger API. Downloading will be slow." modal:YES];
     
    if (count != 1)
      [activityLabel setText:[NSString stringWithFormat:@"Fetching %d blog entries.", count]];
    else 
      [activityLabel setText:[NSString stringWithFormat:@"Fetching one blog entry."]];
    
    /*get the blog ready for a fetch update*/
    [blog beginFetchUpdate];
    
    /*get a blogFetcher*/
    [blogFetcher release];blogFetcher = nil;
    blogFetcher = [[BlogFetcher alloc] initWithUrls:urls blog:blog delegate:self maxThreads:[appDelegate maxConnections] timeout:[appDelegate timeout] retryCount:[appDelegate retries]];
    insist (blogFetcher);

    [progressView setProgress:0];

    /*fire it off*/
    [blogFetcher go];
    return;
  }
  
  /*done with the regular download*/
  [appDelegate syncLock];
  [blog endUpdate];
  [appDelegate syncUnlock];
  [self stopAnimating];
  
  [delegate addViewController:self didAddBlog:blog];
}

- (void) downloaderProgressed:(Downloader*)downloader value:(double)value
{
  insist (progressView && activityIndicator);
  
  /*make sure we aren't using the activity indicator anymore*/
  [activityIndicator setHidden:YES];
  [activityIndicator stopAnimating];
  
  /*make sure the progress indicatior is visible*/
  [progressView setHidden:NO];
  [progressView setProgress:value];
}

- (void) blogFetcherFailed:(BlogFetcher*)fetcher reason:(NSString*)reason
{
  insist (self && activityIndicator && fetcher && fetcher == blogFetcher);
  [self stopAnimating];
  
  [appDelegate alertWithTitle:@"Couldn't Fetch Entries for Blog" message:reason modal:YES];

  /*put the blog in an ok state*/
  [blog failFetchUpdate];
  [blog failUpdate];
  [downloadTextField becomeFirstResponder];
  [blogFetcher release]; blogFetcher = nil;
}

- (void) blogFetcherFinished:(BlogFetcher*)fetcher
{
  insist (fetcher && fetcher == blogFetcher);

  [appDelegate syncLock];
  [blog endFetchUpdate];
  [blog endUpdate];
  [library sync];
  [appDelegate syncUnlock];

  [self stopAnimating];
  [blogFetcher release]; blogFetcher = nil;
  [delegate addViewController:self didAddBlog:blog];
}

- (void) blogFetcherProgressed:(BlogFetcher*)fetcher value:(double)value
{
  [self downloaderProgressed:nil value:value];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];  
  [self download:textField];
  return YES;
}

@end
