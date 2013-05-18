//
//  PageViewController.m
//  diaryreader
//
//  Created by finucane on 1/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PageViewController.h"
#import "TocViewController.h"
#import "TagViewController.h"
#import "SettingsViewController.h"
#import "EntryFetcher.h"

#import "insist.h"

#define SHORT_TIME 0.3
#define TURN_TIME 0.3
#define MIN_TURN_TIME 0.2
#define INSET 5
#define SMALL_DISTANCE 8

enum
{
  BACK,
  RESTORE,
  FORWARD
};

enum
{
  DRAWING,
  DRAWING_MIDDLE,
  DRAWING_LEFT,
  DRAWING_RIGHT,
  DRAWING_DONE
};


@implementation PageView

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  insist (self);
  
  /*make a bitmap context*/
  int width = self.bounds.size.width;
  int height = self.bounds.size.height;
  
  int bytesPerRow = 4 * width;
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB ();
  void*data = malloc (bytesPerRow * height);
  insist (data);
  CGContextRef c = CGBitmapContextCreate (data, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaNoneSkipFirst);
  insist (c);
  CGColorSpaceRelease (colorSpace);
  
  /*create the layer from the context*/
  layer = CGLayerCreateWithContext (c, self.bounds.size, nil);
  insist (layer);
  
  /*we don't need the context anymore.*/
  free (data);
  CGContextRelease (c);
  
#if 0
  /*make is so drawing into the context is flipped, this is because bitmaps are flipped from the rest of
   iphone drawing*/
  
  CGContextScaleCTM (context, 1, -1);
  CGContextTranslateCTM (context, 0, -self.bounds.size.height);
#endif
  c = [self getContext];  
  CGContextSetAllowsAntialiasing (c, YES);
  CGContextSetShouldAntialias (c, YES);
  
  return self;
}

- (void) dealloc
{
  CGLayerRelease (layer);
  [super dealloc];
}


- (CGContextRef)getContext
{
  return CGLayerGetContext (layer);
}

- (CGLayerRef)getLayer
{
  return layer;
}
- (void)setLayer:(CGLayerRef)aLayer
{
  layer = aLayer;
}

-(void) clearNightOn:(BOOL)nightOn
{
  insist (self);
  CGContextRef context = [self getContext];
  CGRect bounds = [UIScreen mainScreen].bounds;
  
  if (nightOn)
  {
    CGContextSetRGBFillColor (context, 0, 0, 0, 1);
    CGContextFillRect(context, bounds);
    CGContextSetRGBFillColor (context, 1, 1, 1, 1);
    CGContextSetRGBStrokeColor (context, 1, 1, 1, 1);
  }
  else
  {
    CGContextSetRGBFillColor (context, 1, 1, 1, 1);
    CGContextFillRect(context, bounds);
    CGContextSetRGBFillColor (context, 0, 0, 0, 1);
    CGContextSetRGBStrokeColor (context, 0, 0, 0, 1);
  }
}

- (void)drawRect:(CGRect)rect
{
  insist (self && layer);

  CGContextDrawLayerAtPoint (UIGraphicsGetCurrentContext (), CGPointMake (0, 0), layer); 
}


@end

@implementation PageViewController

-(void) forget
{
  insist (self);
  [middleInfo.paginator release];middleInfo.paginator = nil;
  [leftInfo.paginator release];leftInfo.paginator = nil;
  [rightInfo.paginator release];rightInfo.paginator = nil;

  middleInfo.dirty = rightInfo.dirty = leftInfo.dirty = YES;  
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil appDelegate:(AppDelegate*)anAppDelegate blog:(Blog*)aBlog
{
  insist (aBlog && anAppDelegate);
  
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  insist (self);
  
  appDelegate = anAppDelegate;
  blog = [aBlog retain];
  
  /*we keep these things around to save time, we can free them if they aren't used if we get memory warnings*/
  tocViewController = nil;
  tagsViewController = nil;
  
  /*set up the navigationbar*/
  self.navigationItem.title = [blog getTitle];
  
  /*set up the toolbar*/
  UIBarButtonItem*tocButton = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(toc:)] autorelease];
  UIBarButtonItem*space0 = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
  UIBarButtonItem*tagsButton = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(tags:)]autorelease];
  UIBarButtonItem*space1 = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
  UIBarButtonItem*settingsButton = [[[UIBarButtonItem alloc]initWithImage: [UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStylePlain target:self action:@selector(settings:)]autorelease];
  UIBarButtonItem*space2 = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
  UIBarButtonItem*refreshButton = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)]autorelease];
  
  self.toolbarItems = [NSArray arrayWithObjects:tocButton, space0, tagsButton, space1, refreshButton, space2, settingsButton, nil];
  self.hidesBottomBarWhenPushed = YES;
  
  /*so when we hide the navigation/toolbars we are the right size*/
  self.wantsFullScreenLayout = YES;
  barsVisible = moved = NO;
  
  /*make the 3 rectangles, left, middle, right, for handling touches*/
  
  CGRect bounds = [UIScreen mainScreen].bounds;
  left = CGRectMake(0, 0, bounds.size.width/3.0, bounds.size.height);
  middle = CGRectMake(bounds.size.width/3.0, 0, bounds.size.width/3.0, bounds.size.height);
  right = CGRectMake(2.0 * bounds.size.width/3.0, 0, bounds.size.width/3.0, bounds.size.height);
  pageFrame = CGRectMake (INSET, INSET, bounds.size.width - 2*INSET, bounds.size.height - 2*INSET);
  
  state = DRAWING_DONE;
  
  /*fuck all the auto-resizing crap that is hard to get right. set the paginators before accessing.*/
  leftInfo.paginator = middleInfo.paginator = rightInfo.paginator = nil;
  testSelector = nil;
  tagsViewController = nil;
  self.view.frame = bounds;
  
  return self;
}

-(void)setActivityViewBackgroundColor:(UIColor*)color
{
  insist (activityIndicator && activityView);
  activityView.backgroundColor = color;
  activityIndicator.backgroundColor = color;
  threePageView.backgroundColor = color;
  leftView.backgroundColor = color;
  rightView.backgroundColor = color;
  middleView.backgroundColor = color;
  self.view.backgroundColor = color;
}


-(void) startActivity
{
  insist (activityIndicator && activityView);
  
  /*so we don't have to keep track if we've had to start spinning before*/
  if (![activityIndicator isAnimating])
  {
    [self.view bringSubviewToFront:activityView];
    [activityView setHidden:NO];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [activityIndicator startAnimating];
  }
}

-(void) stopActivity
{
  insist (activityIndicator && activityView);
  [self.view sendSubviewToBack:activityView];
  [activityView setHidden:YES];
  [activityIndicator stopAnimating];
  [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

/*create and fire off a new paginator*/
- (Paginator*) paginate:(unsigned) position
{
  Month*month = [blog getMonthAtPosition:position];
  insist (month);
  
  /*get a paginator and paginate in the background*/
  Paginator*paginator = [[[Paginator alloc] initWithBlog:blog month:month font:[appDelegate getFont] frame:pageFrame delegate:self appDelegate:appDelegate]autorelease];
  insist (paginator);
  
  //actually do not use a thread.
  //[paginator paginate:nil];
  
  [paginator performSelectorOnMainThread:@selector(paginate:) withObject:nil waitUntilDone:NO];
  //[NSThread detachNewThreadSelector:@selector (paginate:) toTarget:paginator withObject:nil];
  return paginator;
}


/*a wrapper around Paginator::drawPageContainingPosition*/
- (BOOL)drawPageWithPaginator:(Paginator*)paginator containingPosition:(unsigned)position pageView:(PageView*)pageView topPosition:(unsigned*)topPosition length:(unsigned*)length failed:(BOOL*)failed
{
  insist (paginator && topPosition && length && pageView);
  
  CGContextRef context = [pageView getContext];

  [pageView clearNightOn:[appDelegate getNightOn]];
    
  if ([paginator drawPageContainingPosition:position context:context topPosition:topPosition length:length failed:failed])
  {
    insist (failed || (position >= *topPosition && position < *topPosition + *length));
    return YES;
  }
  return NO;
}


/*if we are done redrawing return YES, otherwise move onto the next step, when this
 method ends with NO it means we're returning to the runloop and will wake up again from
 a Paginator delegate callback*/
-(BOOL) doneDrawing
{
  BOOL b, failed;
  unsigned aPosition;
  
  switch (state)
  {
    case DRAWING_MIDDLE:
      if (middleInfo.dirty)
      {
        if (!middleInfo.paginator)
        {
          /*get a paginator, start paginating in the background for the current blog position, and remember the paginator*/

          middleInfo.paginator = [[self paginate:[blog getPosition]]retain];
          insist (middleInfo.paginator);
          return NO;
        }

        /*we are done paginating at this point so drawing has to work.*/
        b = [self drawPageWithPaginator:middleInfo.paginator
                     containingPosition:[blog getPosition]
                               pageView:middleView
                            topPosition:&middleInfo.topPosition length:&middleInfo.length failed:&failed];
  
     //   insist (b && !failed);
      }

      /*move onto the left page*/
      middleInfo.dirty = NO;
      state = DRAWING_LEFT;
      return [self doneDrawingWrapper];
      
    case DRAWING_LEFT:
      if (leftInfo.dirty)
      {
        if (!leftInfo.paginator)
        {
          insist (middleInfo.paginator);
          
          /*handle the case where there's no left page*/
          if (middleInfo.topPosition == 0)
          {
            /*this leaves the paginator nil, that's our indication when we turn pages
              that there's nothing in this page and we'll disallow turns*/
            state = DRAWING_RIGHT;
            leftInfo.dirty = NO;
            return [self doneDrawingWrapper];
          }
          
          /*get any position known to be in the left page*/
          aPosition = middleInfo.topPosition - 1;
          
          /*try drawing with the middle paginator*/
          b = [self drawPageWithPaginator:middleInfo.paginator containingPosition:aPosition pageView:leftView
                              topPosition:&leftInfo.topPosition length:&leftInfo.length failed:&failed];
          
          if (b && !failed)
          {
            /*the left page is in the same chapter as the middle page, so we are done with this page*/
            leftInfo.paginator = [middleInfo.paginator retain];
            state = DRAWING_RIGHT;
            leftInfo.dirty = NO;
            return [self doneDrawingWrapper];
          }
          
          /*the left page is in a different chapter. fire up a background paginator for it...*/
          
          leftInfo.paginator = [[self paginate:aPosition] retain];
          return NO;
        }
        
        /*we are done paginating at this point so drawing has to work.*/
        
        aPosition = middleInfo.topPosition - 1;
        b = [self drawPageWithPaginator:leftInfo.paginator containingPosition:aPosition pageView:leftView
                            topPosition:&leftInfo.topPosition length:&leftInfo.length failed:&failed];
        insist (b && !failed);
      }
      /*move onto the right page*/
      leftInfo.dirty = NO;
      state = DRAWING_RIGHT;
      return [self doneDrawingWrapper];
      
    case DRAWING_RIGHT:
      if (rightInfo.dirty)
      {
        if (!rightInfo.paginator)
        {
          insist (middleInfo.paginator);
          
          /*handle the case where there's no right page. first we have to figure out where the hell the blog ends*/
          Entry*lastEntry = [blog getEntry:[blog getNumEntries] -1];
          insist (lastEntry);
       
          
          /*get any position known to be in the right page. first convert to local space and add a local length*/
          unsigned localPosition = [middleInfo.paginator fileOffsetToLocalPosition:middleInfo.topPosition];
          localPosition += middleInfo.length;
          
          /*then blow the local back up to global*/
          aPosition = [middleInfo.paginator localPositionToFileOffset:localPosition];
          if (aPosition >= lastEntry->offset+lastEntry->length)
          {
            /*no right page, we're done*/
            state = DRAWING_DONE;
            rightInfo.dirty = NO;
            return YES;
          }
          
          /*try drawing with the middle paginator*/
          b = [self drawPageWithPaginator:middleInfo.paginator containingPosition:aPosition pageView:rightView
                              topPosition:&rightInfo.topPosition length:&rightInfo.length failed:&failed];

          if (b && !failed)
          {
            /*the right page is in the same chapter as the current page, so we are done with this page*/
            rightInfo.paginator = [middleInfo.paginator retain];
            state = DRAWING_DONE;
            rightInfo.dirty = NO;
            return YES;
          }
          
          /*the right page is in a different chapter. set up a paginator for it...*/
          rightInfo.paginator = [[self paginate:aPosition] retain];
          return NO;
        }
        
        /*we are done paginating at this point so drawing has to work.*/
        
        /*get any position known to be in the right page. first convert to local space and add a local length*/
        unsigned localPosition = [middleInfo.paginator fileOffsetToLocalPosition:middleInfo.topPosition];
        localPosition += middleInfo.length;
        
        /*then blow the local back up to global*/
        aPosition = [middleInfo.paginator localPositionToFileOffset:localPosition];
        
        b = [self drawPageWithPaginator:rightInfo.paginator containingPosition:aPosition pageView:rightView
                            topPosition:&rightInfo.topPosition length:&rightInfo.length failed:&failed];

        if (!(b && !failed))
        {
          NSLog(@"here");
        }
      //  insist (b && !failed);
  
       }
      /*done*/
      rightInfo.dirty = NO;
      state = DRAWING_DONE;
      return YES;
  }
  insist (0);
  return NO;
}
 


-(BOOL)doneDrawingWrapper
{
  if ([self doneDrawing])
  {
    /*slide the threePageFrame back so that the middle page is visible*/
    CGRect frame = threePageView.frame;
    CGRect screen = self.view.frame;
    frame.origin.x = -screen.size.width;
    threePageView.frame = frame;

    /*any page that's empty needs to be cleared*/
    BOOL nightOn = [appDelegate getNightOn];
    if (!leftInfo.paginator)
      [leftView clearNightOn:nightOn];
    if (!rightInfo.paginator)
        [rightView clearNightOn:nightOn];
    
    [leftView setNeedsDisplay];
    [middleView setNeedsDisplay];
    [rightView setNeedsDisplay];    

    if (testSelector)
    {
      if (testSelector == @selector(rand:))
        [self performSelector:testSelector withObject:nil afterDelay:1.0];
      else
        [self performSelectorOnMainThread:testSelector withObject:nil waitUntilDone:NO];

      testSelector = nil;
    }

    return YES;
  }
  return NO;
}

/*we jump around across threads to prevent the user interface from blocking when we start
  a redraw*/

-(void)startRedrawingOnMainThread:(id)anArgument
{
  /*if we can draw immediately it means we had all the paginators we needed already and could just
  draw. not sure if this would ever really happen in practice.*/
  
  if ([self doneDrawingWrapper])
    [self stopActivity];
}
-(void)startRedrawingInBackground:(id)anArgument
{
  [self performSelectorOnMainThread:@selector (startRedrawingOnMainThread:) withObject:nil waitUntilDone:NO];
}

/*call this when the font has changed or initially, it will throw out
 any existing paginators and start all over*/
-(void) redrawJustColors:(BOOL)justColors
{
  insist (blog);
  
  /*this can be called when it's not supposed to because viewDidAppear can
    be called twice (no idea why). so no op if we are in the middle of drawing*/
  if (state != DRAWING_DONE) return;
  
  [self startActivity];
  
  if (!justColors)
  {
    /*get rid of any old paginators*/
    [middleInfo.paginator release];middleInfo.paginator = nil;
    [leftInfo.paginator release];leftInfo.paginator = nil;
    [rightInfo.paginator release];rightInfo.paginator = nil;
  }
  middleInfo.dirty = rightInfo.dirty = leftInfo.dirty = YES;
  
  /*start by drawing the current page*/
  state = DRAWING_MIDDLE;
  [self performSelectorInBackground:@selector(startRedrawingInBackground:) withObject:nil];
//  [self performSelectorOnMainThread:@selector(startRedrawing:) withObject:nil waitUntilDone:NO];
}


/*this is called whenever a paginator is finished.*/
-(void) paginatorStopped:(Paginator*)aPaginator
{
  if (state >= DRAWING && state < DRAWING_DONE)
  {
    /*move onto the next stage of drawing*/
    if ([self doneDrawingWrapper])
      [self stopActivity];
  }
}

/*since we are always waiting for pagination to finish before trying to draw a page these should never be called.*/
-(void) pageDrawnByPaginator:(Paginator*)aPaginator topPosition:(unsigned)topPosition length:(unsigned)length
{
  insist (0);
}

-(void) pageFailedByPaginator:(Paginator*)aPaginator
{
  insist (0);
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.view.frame = [UIScreen mainScreen].bounds;
  [self setActivityViewBackgroundColor:[appDelegate getNightOn] ? [UIColor blackColor] : [UIColor whiteColor]];
}

-(void) setBarsVisible:(BOOL)visible
{
  if (visible)
  {
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    barsVisible = YES;
  }
  else
  {
    [self.navigationController setToolbarHidden:YES animated:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    barsVisible = NO;
  }
}

-(void) toggleBarsVisible
{
  [self setBarsVisible:!barsVisible];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  
  /*free any viewControllers that aren't in use*/
  if (tocViewController && !tocViewController.parentViewController)
  {
    [tocViewController release];
    tocViewController = nil;
  }
  if (tagsViewController && !tagsViewController.parentViewController)
  {
    [tagsViewController release];
    tagsViewController = nil;
  }
}

- (void)viewDidUnload
{
}

- (void)dealloc
{
  [appDelegate forgetCurrentBlog];
  [blog release];
  [tocViewController release];
  [tagsViewController release];
  [leftInfo.paginator release];
  [middleInfo.paginator release];
  [rightInfo.paginator release];
  [activityIndicator release];
  [threePageView release];
  [leftView release];
  [middleView release];
  [rightView release];
  [tagViewController release];
  [super dealloc];
}

-(IBAction)toc:(id)sender
{
  insist (self);
  
  [self forget];
  
  /*if we don't have a tocViewController for this page, make it*/
  if (!tocViewController)
    tocViewController = [[TocViewController alloc] initWithAppDelegate:appDelegate pageViewController:self];
  insist (tocViewController);
  [appDelegate flipOn:tocViewController];
}

-(IBAction)tags:(id)sender
{
  [self forget];
  
  /*if we have a TagsViewController already then try to push the last tag controller as well*/
  if (tagsViewController)
  {
    if (tagViewController)
    {
      [appDelegate push:tagsViewController animated:NO];
      [appDelegate flipOn:tagViewController];
      return;
    }
  }
  else 
  {
    tagsViewController = [[TagsViewController alloc] initWithAppDelegate:appDelegate pageViewController:self];
    insist (tagsViewController);
  }

  [appDelegate flipOn:tagsViewController];
}

-(IBAction)settings:(id)sender
{
  SettingsViewController*sv = [[SettingsViewController alloc] initWithNibName:@"Settings" bundle:nil appDelegate:appDelegate pageViewController:self];
  insist (sv);
  [appDelegate flipOn:sv];
  [sv release];
}


-(IBAction)refresh:(id)sender
{
  insist (blog);
  [self setBarsVisible:NO];
#if 0
  to debug refresh
  verbose=1;
#endif
  /*now make a downloader to download into the blog. we retain it and will free it when the downloading ends*/
  Downloader*downloader = [[Downloader alloc] initWithDelegate:self timeout:[appDelegate timeout] blog:blog];
  insist (downloader);  
  
  /*blog is already open, make it ready for update*/
  [blog beginUpdate];
 
  //[downloader performSelectorOnMainThread:@selector(download:) withObject:nil waitUntilDone:NO];

  [NSThread detachNewThreadSelector:@selector (download:) toTarget:downloader withObject:nil];

  [self startActivity];
}


- (void) downloaderStatusChanged:(Downloader*)downloader status:(NSString*)status
{
  
}

- (void) downloaderProgressed:(Downloader*)downloader value:(double)value
{
}

- (void) downloaderFailed:(Downloader*)downloader reason:(NSString*)reason
{
  [appDelegate alertWithTitle:@"Couldn't Get Entries from Blog" message:reason modal:NO];
  
  [blog failUpdate];
  [downloader release];
  
  [self stopActivity];
}

- (void) downloaderFinished:(Downloader*)downloader
{
  /*check to see if the downloaded had summaries. in this case we need to do more work before we can do all the endUpdate stuff.*/
  if ([blog hasUrls])
  {
    NSArray*urls = [blog getUrls];
    insist (urls);
    int count = [urls count];
    insist (count > 0);
    
    /*get the blog ready for a fetch update*/
    [blog beginFetchUpdate];
    
    /*get a blogFetcher*/
    BlogFetcher*blogFetcher = [[BlogFetcher alloc] initWithUrls:urls blog:blog delegate:self maxThreads:[appDelegate maxConnections] timeout:[appDelegate timeout] retryCount:[appDelegate retries]];
    insist (blogFetcher);
    
    /*fire it off*/
    [blogFetcher go];
    return;
  }
  
  /*commit all the new entries to the blog*/
  
  [appDelegate syncLock];
  [blog endUpdate];
  [blog sync];
  [appDelegate syncUnlock];
  
  /*free the downloader*/
  [downloader release];
  [self stopActivity];
  
  /*if we got any new text advance the book to the start of it*/
  unsigned position = [blog getUpdatePosition];
  if (position)
  {
    [blog setPosition:position];
    [self redrawJustColors:NO];
  }
}

- (void) blogFetcherFailed:(BlogFetcher*)fetcher reason:(NSString*)reason
{
  insist (self && blog && fetcher);
  [self stopActivity];
  
  /*put the blog in an ok state*/
  [blog failFetchUpdate];
  [blog failUpdate];
  [fetcher release];
}

- (void) blogFetcherFinished:(BlogFetcher*)fetcher
{
  insist (fetcher && fetcher);
  
  [appDelegate syncLock];
  [blog endFetchUpdate];
  [blog endUpdate];
  [blog sync];
  [appDelegate syncUnlock];
  
  [self stopActivity];
  [fetcher release];
  
  /*if we got any new text advance the book to the start of it*/
  unsigned position = [blog getUpdatePosition];
  if (position)
  {
    [blog setPosition:position];
    [self redrawJustColors:NO];
  }
  
}

- (void) blogFetcherProgressed:(BlogFetcher*)fetcher value:(double)value
{
  
}


-(BOOL)navigationBarHidden
{
  return YES;
}
-(BOOL)toolbarHidden
{
  return YES;
}
-(BOOL)barsTranslucent
{
  return YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  /*get how far the finger has moved in the x direction so far*/
  UITouch*touch = [touches anyObject];
  CGPoint point = [touch locationInView:self.view];
  CGFloat d = point.x - startPoint.x;
  
  moved = YES;
  
  /*move the sliding frame to where it should be now*/
  
  CGRect frame = threePageView.frame;
  frame.origin.x = startThreePageViewX + d;
  threePageView.frame = frame;
}


/*the current page is in either the left or the right page now, slide things
 over to put the threePageView back so that the current page is in the middle
 and that there are valid pages before and after*/

-(void)fixThreePageView:(int)how
{
  insist (self && how == FORWARD || how == BACK);

  if (how == FORWARD)
  {
    /*slide over the page information*/
    [leftInfo.paginator release];
    leftInfo = middleInfo;
    middleInfo = rightInfo;

    /*slide over the pageView contexts (in a circle)*/
    CGLayerRef layer = [leftView getLayer];
    [leftView setLayer:[middleView getLayer]];
    [middleView setLayer:[rightView getLayer]];
    [rightView setLayer:layer];
    
    /*invalidate rightView*/
    rightInfo.paginator = nil;
    rightInfo.dirty = YES;
    state = DRAWING_RIGHT;
  }
  else
  {
    /*slide over the page information*/
    [rightInfo.paginator release];
    rightInfo = middleInfo;
    middleInfo = leftInfo;
    
    /*slide over the pageView contexts (in a circle)*/
    CGLayerRef layer = [rightView getLayer];
    [rightView setLayer:[middleView getLayer]];
    [middleView setLayer:[leftView getLayer]];
    [leftView setLayer:layer];
  
    /*invalidate rightView*/
    leftInfo.paginator = nil;
    leftInfo.dirty = YES;
    state = DRAWING_LEFT;
    
  }
  
#if 0
  /*slide the threePageFrame back so that the middle page is visible*/
  CGRect frame = threePageView.frame;
  CGRect screen = self.view.frame;
  frame.origin.x = -screen.size.width;
  threePageView.frame = frame;
#endif
  
  if (!middleInfo.paginator)
  {
    state = DRAWING_MIDDLE;
    middleInfo.dirty = rightInfo.dirty = leftInfo.dirty = YES;
    [rightInfo.paginator release]; rightInfo.paginator = nil;
    [leftInfo.paginator release]; leftInfo.paginator = nil;
  }
  
  /*force the new page to redraw*/
  [self startActivity];
  if ([self doneDrawingWrapper])
    [self stopActivity];   
    
}

-(void)turnAnimationDidStop:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context
{
  int how = (int)context;
  [[UIApplication sharedApplication] endIgnoringInteractionEvents];

  /*if we moved, fix the 3 page view so that the visible page is the middle view
   and that there are valid pages before and after*/
  if (how != RESTORE)
    [self fixThreePageView:how];
}

/*slide the container view right or left by one page
 make it take a realistic amount of time depending on how far
 it has to move
 */

- (void) turn:(int)how
{
  insist (self && threePageView);
  
  /*anytime a page turns we make sure the bars are gone*/
  [self setBarsVisible:NO];
  
  CGRect screen = self.view.frame;
  CGRect frame = threePageView.frame;
  CGFloat x;
  
  /*if we are turning to a page not in the blog, cancel the turn*/
  if (how == FORWARD && !rightInfo.paginator || how == BACK && !leftInfo.paginator)
    how = RESTORE;
  
  if (how == FORWARD)
  {
    x = -2 * screen.size.width;
    [blog setPosition:rightInfo.topPosition];
  }
  else if (how == RESTORE)
  {
    x = -screen.size.width;
  }
  else
  {
    x = 0;
    [blog setPosition:leftInfo.topPosition];
  }
  
  CGFloat d = fabs (frame.origin.x - x);
  CGFloat scale = d / screen.size.width;
  frame.origin.x = x;
  
  /*make sure the movement takes at least some time*/
  NSTimeInterval duration = TURN_TIME * scale;
  if (duration < MIN_TURN_TIME)
    duration = MIN_TURN_TIME;

  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  
  [UIView beginAnimations:nil context:(void*)how];
  [UIView setAnimationDuration:duration];
  
  threePageView.frame = frame;
  startThreePageViewX = frame.origin.x;  
  
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(turnAnimationDidStop:finished:context:)];
  [UIView commitAnimations];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch*touch = [touches anyObject];
  CGPoint stopPoint = [touch locationInView:self.view];
  NSTimeInterval stopTime = [touch timestamp];
  
  /*if the event occured quick and didn't involve much movement, treat it as a press*/
  CGFloat d = stopPoint.x - startPoint.x;
  NSTimeInterval dt = stopTime - startTime;
  
  //moved = fabs (d) > SMALL_DISTANCE;
  if (!moved && dt < SHORT_TIME)
  {
    /*depending on where the touch ended, turn the page or toggle the controls*/
    if (CGRectContainsPoint(left, stopPoint))
      [self turn:BACK];
    else if (CGRectContainsPoint(right, stopPoint))
      [self turn:FORWARD];
    else
      [self toggleBarsVisible];
    return;
  }
  
  /*otherwise turn the page if the movement was significant in the direction of the movement,
   of if the movement was not that much, then towards where-ever the touch ended*/
  if (fabs(d) <= SMALL_DISTANCE)
    [self turn:RESTORE];
  else
    [self turn:d < 0 ? FORWARD :BACK];
}

-(Blog*)getBlog
{
  return blog;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event
{
  UITouch*touch = [touches anyObject];
  startPoint = [touch locationInView:self.view];
  CGRect frame = threePageView.frame;
  startThreePageViewX = frame.origin.x;
  
  startTime = [touch timestamp];
  moved = NO;
}

/*it is safe to jump to random file offsets so long as they are entry offsets*/

-(void)rand:(id)anArgument
{
  if (testRandomCount > 200) return;//done w/ test
    
  unsigned max = [blog getNumEntries];
  
  Entry*entry = [blog getEntry:rand () % max];
  insist (entry);
  
  [blog setPosition:entry->offset];
  testSelector = @selector (rand:);
  [self redrawJustColors:NO];
  testRandomCount++;
}

/*for testing*/
-(void)back:(id)anArgument
{
  
  /*if we are back to page 1 move onto random pages*/
  if (middleInfo.paginator && middleInfo.topPosition == 0)
  {
    [self performSelectorOnMainThread:@selector(rand:) withObject:nil waitUntilDone:NO];
    return;
  }
  testSelector = @selector (back:);
  [self turn:BACK];
}

-(void)next:(id)anArgument
{
  /*if we are a the end of the book go back*/
  if (middleInfo.paginator)
  {
    /*handle the case where there's no right page. first we have to figure out where the hell the blog ends*/
    Entry*lastEntry = [blog getEntry:[blog getNumEntries] -1];
    insist (lastEntry);
  
    /*get any position known to be in the right page. first convert to local space and add a local length*/
    unsigned localPosition = [middleInfo.paginator fileOffsetToLocalPosition:middleInfo.topPosition];
    localPosition += middleInfo.length;
    
    /*then blow the local back up to global*/
    unsigned aPosition = [middleInfo.paginator localPositionToFileOffset:localPosition];

    if (aPosition >= lastEntry->offset+lastEntry->length)
    {
      state = DRAWING_MIDDLE;
      [self performSelectorOnMainThread:@selector(back:) withObject:nil waitUntilDone:NO];
      return;
    }
  }

  testSelector = @selector (next:);
  [self turn:FORWARD];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
  [[UIApplication sharedApplication] setIdleTimerDisabled:![appDelegate getIdleTimerOn]];

  [super viewDidAppear:animated];

  if (testApp)
  {
    testApp = NO;
    srand (time (0));
    testRandomCount = 0;
    [self performSelector:@selector(next:) withObject:nil afterDelay:5.0];
  }
  
  /*draw the page whereever the blog position is, and the page before and after*/
  [self redrawJustColors:NO];
}                            
     
/*this is to keep track of the tagsViewController that sends us back to reading.
  when a tagViewController view is backed off from, instead of used to change
  the position in the text, this is called with nil.
 */
-(void)setTagViewController:(TagViewController*)controller
{
  insist (self);
  [controller retain];
  [tagViewController release];
  tagViewController = controller;
}

@end
