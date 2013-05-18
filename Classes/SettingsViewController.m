//
//  SettingsViewController.m
//  diaryreader
//
//  Created by finucane on 1/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "insist.h"

@implementation SettingsViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil appDelegate:(AppDelegate*)anAppDelegate pageViewController:(PageViewController*)aPageViewController
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  insist (self);
  appDelegate = anAppDelegate;
  pageViewController = aPageViewController;
  
  /*collect all the font names*/
  
  fontNames = [[NSMutableArray alloc] init];
  insist (fontNames);
  
  NSArray*families = [UIFont familyNames];
  insist (families);
  for (int i = 0; i < [families count]; i++)
  {
    /*for each family ...*/
    NSArray*names = [UIFont fontNamesForFamilyName:[families objectAtIndex:i]];
    insist (names);
    
    for (int j = 0; j < [names count]; j++)
      [fontNames addObject:[names objectAtIndex:j]];
  }
  selectedIndexPath = nil;
  
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)]autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]autorelease];
  
  /*set up the navigationbar*/
  self.navigationItem.title = @"Settings";
  
  return self;
}

/*return the settings.*/
-(void)getSelectedFont:(UIFont**)font night:(BOOL*)night timeout:(NSTimeInterval*)timeout retries:(int*)retries maxConnections:(int*)maxConnections
{
  insist (selectedIndexPath);
  int row = [selectedIndexPath row];
  int size = (int)fontSizeSlider.value;
  *font = [UIFont fontWithName:[fontNames objectAtIndex:row] size:size];
  *night = nightSwitch.on;
  *timeout = timeoutSlider.value;
  *retries = (int)retriesSlider.value;
  *maxConnections = (int)maxConnectionsSlider.value;
}

/*if the settings changed tell the pageViewController it has to redraw its pages*/
-(void)save:(id)sender
{
  insist (pageViewController);
  
  /*get the current settings*/
  UIFont*font,*currentFont;
  BOOL night;
  NSTimeInterval timeout;
  int retries, maxConnections;
  [self getSelectedFont:&font night:&night timeout:&timeout retries:&retries maxConnections:&maxConnections];
  currentFont = [appDelegate getFont];
  
  /*even though font objects are reused don't trust just doing font != currentFont*/
  
  /*save the defaults, we have to do this before we tell the page view to redraw*/
  BOOL nightChanged = night != [appDelegate getNightOn];
  [appDelegate setFont:font];
  [appDelegate setNightOn:night];
  [appDelegate setTimeout:timeout];
  [appDelegate setRetries:retries];
  [appDelegate setMaxConnections:maxConnections];
  [appDelegate setIdleTimerOn:idleTimerSwitch.on];
  [[UIApplication sharedApplication] setIdleTimerDisabled:![appDelegate getIdleTimerOn]];
  
  /*set the color of the blank screen view we use when we have to wait to flip a page*/
  if (nightChanged)
    [pageViewController setActivityViewBackgroundColor:night? [UIColor blackColor] : [UIColor whiteColor]];
  
  if (currentFont.pointSize != font.pointSize || ![currentFont.fontName isEqualToString:font.fontName])
    [pageViewController redrawJustColors:NO];
  else if (nightChanged)
    [pageViewController redrawJustColors:YES];  

  [appDelegate flipOff];
}

- (void)cancel:(id)sender
{
  [appDelegate flipOff];
}

- (void) redrawText
{
  insist (self && textView);
  
  BOOL night;
  UIFont*font;
  
  /*get current settings*/
  NSTimeInterval timeout;
  int retries, maxConnections;
  [self getSelectedFont:&font night:&night timeout:&timeout retries:&retries maxConnections:&maxConnections];
  
  textView.font = font;
  
  if (night)
  {
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
  }
  else
  {
    textView.backgroundColor = [UIColor whiteColor];
    textView.textColor = [UIColor blackColor];
  }
}

/*initialize the settings to their current values*/


-(IBAction)fontSizeSiderChanged:(id)sender
{
  /*redraw the text*/
  [self redrawText];
}

-(IBAction)nightChanged:(id)sender
{
  [self redrawText];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  insist (self && appDelegate);
  insist (fontSizeSlider && nightSwitch);
  
  /*set the night switch*/
  nightSwitch.on = [appDelegate getNightOn];
  idleTimerSwitch.on = [appDelegate getIdleTimerOn];
  
  /*set the font name and size*/
  UIFont*font = [appDelegate getFont];
  insist (font);
  NSString*fontName = font.fontName;
  
  /*find which row has the current font*/
  int row;
  for (row = 0; row < [fontNames count] && ![fontName isEqualToString:[fontNames objectAtIndex:row]]; row++);
  
  /*we should always find a font, but if not, just make the first font the current one. we don't want our baby to crash.*/
  if (row == [fontNames count])
  {
    UIFont*correction = [UIFont fontWithName:[fontNames objectAtIndex:0] size:font.pointSize];
    [appDelegate setFont:correction];
    row = 0;
  }
  NSUInteger them [2];
  them [0] = 1;
  them [1] = row;
  
  selectedIndexPath = [[NSIndexPath alloc] initWithIndexes:them length:2];
  /*check the row for the current font*/
  UITableViewCell*cell = [tableView cellForRowAtIndexPath:selectedIndexPath];
  cell.accessoryType = UITableViewCellAccessoryCheckmark;
  
  [tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  [tableView reloadData];
  
  fontSizeSlider.minimumValue = MIN_FONT_SIZE;
  fontSizeSlider.maximumValue = MAX_FONT_SIZE;
  fontSizeSlider.value = font.pointSize;
  timeoutSlider.minimumValue = MIN_TIMEOUT;
  timeoutSlider.maximumValue = MAX_TIMEOUT;
  timeoutSlider.value = [appDelegate timeout];
  retriesSlider.minimumValue = MIN_RETRIES;
  retriesSlider.maximumValue = MAX_RETRIES;
  retriesSlider.value = [appDelegate retries];
  maxConnectionsSlider.minimumValue = MIN_MAX_CONNECTIONS;
  maxConnectionsSlider.maximumValue = MAX_MAX_CONNECTIONS;
  maxConnectionsSlider.value = [appDelegate maxConnections];
  
  /*redraw the sample text*/
  [self redrawText];
  
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 3;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  insist (self && fontNames);
  switch (section)
  {
    case 0:
      return 3;
    case 1:
      return [fontNames count];
    case 2:
      return 3;
  }
  return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  insist (self);
  switch (section)
  {
    case 0:
      return @"";
    case 1:
      return @"Font";
    case 2:
      return @"Connection";
  }
  return @"";
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";

  int section = [indexPath section];
  int row = [indexPath row];
  
  /*handle the static cells first*/
  if (section == 0)
  {
    if (row == 0)
      return nightCell;
    if (row == 1)
      return fontSizeCell;
    if (row == 2)
      return idleTimerCell;
  }else if (section == 2)
  {
    if (row == 0)
      return timeoutCell;
    if (row == 1)
      return retriesCell;
    if (row == 2)
      return maxConnectionsCell;
  }
  
  /*it's a font name cell, deal with it*/
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier]autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.showsReorderControl = NO;
  }
  if (selectedIndexPath && [indexPath compare:selectedIndexPath] == NSOrderedSame)
  {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    selectedIndexPath = [indexPath retain];
  }
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  
  // Set up the cell...
  cell.textLabel.text = [fontNames objectAtIndex:row];
  
  return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  int section = [indexPath section];
  if (section == 0) return;
  
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
  
  [self redrawText];
}


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

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc
{
  [fontNames release];
  [selectedIndexPath release];
  [textView release];
  [tableView release];
  [nightCell release];
  [fontSizeCell release];
  [timeoutCell release];
  [retriesCell release];
  [maxConnectionsCell release];
  [timeoutSlider release];
  [retriesSlider release];
  [super dealloc];
}



@end
