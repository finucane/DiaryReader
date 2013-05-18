//
//  TagsViewController.m
//  diaryreader
//
//  Created by David Finucane on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TagsViewController.h"
#import "TagViewController.h"
#import "insist.h"

@implementation TagsViewController

- (id) initWithAppDelegate:(AppDelegate*)anAppDelegate pageViewController:(PageViewController*)aPageViewController
{
  insist (anAppDelegate && aPageViewController);
  self = [super initWithStyle:UITableViewStylePlain];
  insist (self);

  appDelegate = anAppDelegate;
  pageViewController = aPageViewController;
  
  /*set up the navigationbar*/
  self.navigationItem.title = @"Tags";

  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Read" style:UIBarButtonItemStylePlain target:self action:@selector(back:)]autorelease];

  return self;
}

-(void)back:(id)sender
{
  /*nothing happened, just go back to the pageview*/
  [appDelegate flipOff];
}

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning]; 
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  insist (self && tableView && pageViewController);
  Blog*blog = [pageViewController getBlog];
  return [blog getNumTags];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
    
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.showsReorderControl = NO;
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  Blog*blog = [pageViewController getBlog];
  insist (blog);
  
  Tag*tag = [blog getTag:[indexPath row]];
  insist (tag);
  
  // Set up the cell...
  cell.textLabel.text = tag->word;

  return cell;
}


/*push tableView for tag*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  insist (self && pageViewController);
  Blog*blog = [pageViewController getBlog];
  Tag*tag = [blog getTag:[indexPath row]];
  insist (tag);
  
  TagViewController*vc = [[TagViewController alloc] initWithTag:tag appDelegate:appDelegate pageViewController:pageViewController];
  insist (vc);
  [appDelegate push:vc animated:YES];
  [vc release];
}

- (void)dealloc
{
  [super dealloc];
}

@end

