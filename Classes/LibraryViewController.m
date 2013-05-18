//
//  LibraryViewController.m
//  diaryreader
//
//  Created by finucane on 1/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LibraryViewController.h"
#import "AddViewController.h"
#import "PageViewController.h"
#import "insist.h"

@implementation LibraryViewController

- (id)initWithAppDelegate:(AppDelegate*)anAppDelegate library:(Library*)aLibrary;
{
  self = [super initWithStyle:UITableViewStylePlain];
  insist (self);
  
  appDelegate = anAppDelegate;
  library = [aLibrary retain];
  
  /*set up the navigationbar*/
  self.navigationItem.title = @"Blogs";
  
  /*set up the toolbar*/
  UIBarButtonItem*addButton = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)] autorelease];
  UIBarButtonItem*space = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
  insist (space);
  space.width = 108;
  
  randomButton = [[[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"dice.png"] style:UIBarButtonItemStylePlain target:self action:@selector(random:)] autorelease];
  UIBarButtonItem*space2 = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
  
  editButton = [[UIBarButtonItem alloc]initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(edit:)];
  self.toolbarItems = [NSArray arrayWithObjects:addButton, space, randomButton, space2, editButton, nil];
  editButton.possibleTitles = [NSSet setWithObjects:@"Edit", @"Done", nil];

  /*only enable the edit button if there are any blogs*/
  [editButton setEnabled:[library getNumBlogs] != 0];

  currentBlog = nil;
  randomBlogID = [[library anyBlogID] retain];//may be nil
  return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


/*we only create a LibraryViewController once, when the app is started. so here's where
  we load blog automatically if the user had quit the app previously while reading*/
- (void)viewDidLoad
{
  insist (self && appDelegate && randomButton);
  [super viewDidLoad];
  
  insist (library);
  if ((currentBlog = [library getCurrentBlog]))
  {
    [currentBlog open];
    /*make a new page view and pop it onto the app's navigation controller*/
    PageViewController*pv = [[PageViewController alloc] initWithNibName:@"Page" bundle:nil appDelegate:appDelegate blog:currentBlog];
    [appDelegate push:pv animated:NO];
    [pv release];
  }
  
  [randomButton setEnabled:[library anyBlogID] != nil || randomBlogID];
}


- (void)viewDidAppear:(BOOL)animated
{
  insist (library && appDelegate);
  [super viewDidAppear:animated];
  
  if ([library wasCorrupted])
  {
    [appDelegate alertWithTitle:@"Corrupted Blog Files" message:@"Some blogs in your Library were corrupted. You might have to add them again." modal:NO];
    [library clearCorrupted];
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  [appDelegate handleLowMemory];
}


- (void)dealloc
{
  [library release];
  [editButton release];
  [randomButton release];
  [randomBlogID release];
  [super dealloc];
}

- (IBAction)add:(id)sender
{
  insist (self && sender && self.tableView);
  
  /*bring up the window to add a blog*/
  AddViewController*av = [[AddViewController alloc] initWithNibName:@"Add" bundle:nil appDelegate:appDelegate delegate:self library:library url:nil];
  insist (av);
  [self presentModalViewController:av animated:YES];
  [av release];
}

/*return yes if the string start w/ http:// and has exactly 1 formating sequence, %@*/
- (BOOL)checkRandomFormat:(NSString*)s
{
  insist (self && s);
  NSRange r = [s rangeOfString:@"%@"];

  if (![s hasPrefix:@"http://"])
    return NO;
  
  if (r.location == NSNotFound)
    return NO;

  r.location += r.length;
  r = [s rangeOfString:@"%@" options:0 range:NSMakeRange(r.location, [s length] - r.location)];
  if (r.location != NSNotFound)
    return NO;
  
  r = [s rangeOfString:@"%"];
  r.location += r.length;
  
  r = [s rangeOfString:@"%" options:0 range:NSMakeRange(r.location, [s length] - r.location)];
  if (r.location != NSNotFound)
    return NO;
  
  return YES;
}

- (IBAction)random:(id)sender
{
  insist (self && sender && self.tableView);
  
  /*get a hopefully known good blogID*/
  NSString*blogID = [library anyBlogID];

  if (!blogID)
    blogID = randomBlogID;

  if (!blogID)
    return;
  
  /*get the random format and make sure it's plausible*/
  NSString*fmt = [appDelegate getRandomFormat];
  insist (fmt);

  if (![self checkRandomFormat:fmt])
  {
    [appDelegate alertWithTitle:@"Bad Random Format"
                        message:[NSString stringWithFormat:@"\"%@\" is not a valid random format", fmt]
                          modal:YES];
    return;
  }

  /*bring up the window to add a blog, with the url already set to the random blog url*/
  AddViewController*av = [[AddViewController alloc] initWithNibName:@"Add" bundle:nil appDelegate:appDelegate
                                                            delegate:self library:library
                                                                 url:[NSString stringWithFormat:fmt,blogID]];
  insist (av);
  [self presentModalViewController:av animated:YES];
  [av release];
}


-(void)addViewController:(AddViewController*)controller didAddBlog:(Blog*)blog
{
  insist (self && controller);
  /*if there's a blog, the a new one was successfully created. add it to the library*/
  if (blog)
  {
    
    /*test the empty blog case which our pagination can't handle*/
    if ([blog getNumEntries] == 0)
    {
      [appDelegate alertWithTitle:@"Empty Blog"
                          message:@"This blog has no contents, so it was not added to the library."
                            modal:YES];
      return;
    }
    [library add: blog];
    [appDelegate syncLock];
    [library sync];
    [appDelegate syncUnlock];

    [self.tableView reloadData];
    [editButton setEnabled:YES];
    [randomButton setEnabled:YES];
    [randomBlogID release];
    randomBlogID = [[blog getBlogID]retain];

    /*make sure it's visible*/
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0]-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
  }
  
  /*this frees the modal viewController*/
  [self dismissModalViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  insist (self && library);
  return [library getNumBlogs];
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  insist (self && library && tableView && fromIndexPath && toIndexPath);
  
  int from = [fromIndexPath row];
  int to = [toIndexPath row];

  insist (from >= 0 && from < [library getNumBlogs]);
  insist (to >= 0 && to < [library getNumBlogs]);
  
  [library moveBlogFrom:from to:to];
  
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  insist (self && indexPath && library);

  int row = [indexPath row];
  insist (row >= 0 && row < [library getNumBlogs]);
  
  /*if we are deleting the current blog make sure we remove our reference to it too*/
  if ([library getBlog:row] == currentBlog)
    currentBlog = nil;
  
  [library removeBlogAtIndex:row];
  
  /*if there are no more blogs, disable the edit button and toggle the table view out of edit mode*/
  if ([library getNumBlogs] == 0)
  {
    [editButton setEnabled:NO];
    [self edit:editButton];
  }
  [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  [randomButton setEnabled:[library anyBlogID] != nil || randomBlogID];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  int row = [indexPath row];
  insist (row >= 0 && row < [library getNumBlogs]);
  Blog*blog = [library getBlog:row];
  insist (blog);
  
  if (currentBlog)
    [currentBlog close];
  currentBlog = blog;
  [currentBlog open];
  [library setCurrentBlog:currentBlog];
  
  /*make a new page view and pop it onto the app's navigation controller*/
  PageViewController*pv = [[PageViewController alloc] initWithNibName:@"Page" bundle:nil appDelegate:appDelegate blog:blog];
  [appDelegate push:pv animated:NO];
  [pv release];
}

static NSString*cellString = @"normal";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  int row = [indexPath row];
  
  insist (row >= 0 && row < [library getNumBlogs]);
    
  UITableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:cellString];
  if (!cell)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellString]autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.showsReorderControl = YES;
    
  }
  
  Blog*blog = [library getBlog:row];
  insist (blog);
  cell.textLabel.text =[blog getTitle];
  cell.detailTextLabel.text = [blog getSubtitle];
  return cell;
}


/*toggle editing mode in the tableview*/
- (IBAction)edit:(id)sender
{
  insist (self && self.tableView && randomButton);
  insist (sender == editButton);
  
  if (self.tableView.editing)
  {
    [self.tableView setEditing:NO animated:YES];
    [sender setTitle:@"Edit"];
    [sender setStyle:UIBarButtonItemStyleBordered];
  }
  else
  {
    [self.tableView setEditing:YES animated:YES];
    [sender setTitle:@"Done"];
    [sender setEnabled:YES];
    [sender setStyle:UIBarButtonItemStyleDone];
  }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
}

-(BOOL)toolbarHidden
{
  return NO;
}


@end
