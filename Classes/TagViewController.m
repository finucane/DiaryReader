//
//  TagViewController.m
//  diaryreader
//
//  Created by David Finucane on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TagViewController.h"
#import "insist.h"

@implementation TagViewController

-(id)initWithTag:(Tag*)aTag appDelegate:(AppDelegate*)anAppDelegate pageViewController:(PageViewController*)aPageViewController
{
  insist (aTag && anAppDelegate && aPageViewController);
  self = [super initWithStyle:UITableViewStylePlain];
  insist (self);
  tag = [aTag retain];

  appDelegate = anAppDelegate;
  pageViewController = aPageViewController;
  
  /*set up a formatter so we can display dates*/
  
  formatter = [[NSDateFormatter alloc] init];
  [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
  [formatter setDateStyle:NSDateFormatterFullStyle];
  [formatter setTimeStyle:NSDateFormatterNoStyle];

  /*set up the navigationbar*/
  self.navigationItem.title = tag->word;
  
  selectedIndexPath = nil;
  
  return self;
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
  insist (tag);
  return [tag->entries count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  insist (tag && pageViewController);
  Blog*blog = [pageViewController getBlog];
  insist (blog);
  
  int row = [indexPath row];
  insist (row >= 0 && row < [tag->entries count]);
  
  static NSString *CellIdentifier = @"Cell";
    
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier]autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.showsReorderControl = NO;
  }     
  
  if (selectedIndexPath && [indexPath compare:selectedIndexPath] == NSOrderedSame)
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  
  // Set up the cell...
  int i = [[tag->entries objectAtIndex:row] intValue];
  Entry*entry = [blog getEntry:i];
  insist (entry);
  cell.textLabel.text = [formatter stringForObjectValue: [entry getDate]];
  cell.detailTextLabel.text = [entry getTitle];

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{ 
  insist (self && tag && pageViewController);
  int row = [indexPath row];
  insist (row >= 0 && row < [tag->entries count]);

  if (selectedIndexPath)
  {
    [tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
    UITableViewCell*cell = [tableView cellForRowAtIndexPath:selectedIndexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    [selectedIndexPath release];
  }
  
  UITableViewCell*cell = [tableView cellForRowAtIndexPath:indexPath];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  selectedIndexPath = [indexPath retain];
  
  Blog*blog = [pageViewController getBlog];
  insist (blog);
  
  /*set the blog to the tag's position*/
  int i = [[tag->entries objectAtIndex:row] intValue];
  Entry*entry = [blog getEntry:i];
  insist (entry);
  
  [blog setPosition: entry->offset];
  [pageViewController redrawJustColors:NO];
  
  /*tell the pageViewController remember us. this also keeps us alive after the popback 
    because we are being retained. the pageViewController will automatically pop us back
    on when the tags button is pressed.*/
  goneByBackButton = NO;
  [pageViewController setTagViewController:self];
  
  [appDelegate popBackTo:pageViewController];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  insist (self && pageViewController);
  
  if (goneByBackButton)
  {
    /*tell the pageViewController not to care about us anymore*/
    [pageViewController setTagViewController:nil];
  }
}

/*every time we come up we keep track of how we disappeared*/
-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  insist (self);
  goneByBackButton = YES;
}

- (void)dealloc
{
  [tag release];
  [formatter release];
  [selectedIndexPath release];
  [super dealloc];
}


@end

