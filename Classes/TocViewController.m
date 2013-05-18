//
//  TocViewController.m
//  diaryreader
//
//  Created by David Finucane on 1/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TocViewController.h"
#import "insist.h"

@implementation TocViewController

- (id)initWithAppDelegate:(AppDelegate*)anAppDelegate pageViewController:(PageViewController*)aPageViewController
{
  insist (anAppDelegate && aPageViewController);
  
  self = [super initWithStyle:UITableViewStyleGrouped];
  insist (self);

  
  appDelegate = anAppDelegate;
  pageViewController = aPageViewController;

  Blog*blog = [pageViewController getBlog];
  insist (blog);
  
  /*get the month where the current text position is, so we can do the checkmark*/
  selectedIndexPath = [[blog getIndexPathForMonthAtPosition:[blog getPosition]] retain];
  
  /*set up the navigationbar*/
  self.navigationItem.title = @"Table of Contents";
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Read" style:UIBarButtonItemStylePlain target:self action:@selector(back:)]autorelease];

  /*we have no button bar*/
  self.hidesBottomBarWhenPushed = YES;
  
  return self;
}
  
-(void)back:(id)sender
{
  /*nothing happened, just go back to the pageview*/
  [appDelegate flipOff];
}


/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


 - (void)viewDidLoad
{
  insist (self.tableView && selectedIndexPath);
  [super viewDidLoad];
  
  /*check the row for where the book is currently being read*/
  UITableViewCell*cell = [self.tableView cellForRowAtIndexPath:selectedIndexPath];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  
  [self.tableView reloadData];
  [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
  [self.tableView scrollToRowAtIndexPath:selectedIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
}
 

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


-(void) dealloc
{
  [selectedIndexPath release];
  [super dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  insist (self && pageViewController);
  Blog*blog = [pageViewController getBlog];
  return [blog getNumYears];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  insist (self && pageViewController);
  Blog*blog = [pageViewController getBlog];
  
  insist (section >= 0 && section < [blog getNumYears]);
  Year*year = [blog getYear:section];
  insist (year);
  return [year getNumMonths];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  insist (self && pageViewController);
  
  Blog*blog = [pageViewController getBlog];
  insist (section >= 0 && section < [blog getNumYears]);
  
  return [[blog getYear:section] getLabel];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  insist (self && pageViewController);
  
  Blog*blog = [pageViewController getBlog];
  
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
  
  /*get the month that was selected*/
  int section = [selectedIndexPath section];
  int row = [selectedIndexPath row];
  
  insist (section >= 0 && section < [blog getNumYears]);
  Year*year = [blog getYear:section];
  insist (year);
  Month*month = [year getMonth:row];
  insist (month);
  
  /*get the first entry of the month*/
  Entry*entry = [blog getEntry:month->firstEntry];
  insist (entry);
  
  /*set the blog to that position*/
  [blog setPosition: entry->offset];
  [appDelegate popBack];
  [pageViewController redrawJustColors:NO];
}
 
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
}

static NSString*cellString = @"normal";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  insist (self && tableView && indexPath && pageViewController);

  Blog*blog = [pageViewController getBlog];
  insist (blog);
  
  Month*month = [blog getMonth:[indexPath row] inYear:[indexPath section]];
  insist (month);
  
  UITableViewCell*cell = [tableView dequeueReusableCellWithIdentifier:cellString];
  if (!cell)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellString]autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.showsReorderControl = YES;
  }

  if (selectedIndexPath && [indexPath compare:selectedIndexPath] == NSOrderedSame)
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  
  cell.textLabel.text =[month getLabel];
  return cell;
}

@end
