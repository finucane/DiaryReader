//
//  SettingsViewController.h
//  diaryreader
//
//  Created by finucane on 1/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "PageViewController.h"

@interface SettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
  AppDelegate*appDelegate;
  IBOutlet UITextView*textView;
  IBOutlet UITableView*tableView;
  IBOutlet UITableViewCell*nightCell;
  IBOutlet UISwitch*nightSwitch;
  IBOutlet UITableViewCell*idleTimerCell;
  IBOutlet UISwitch*idleTimerSwitch;
  IBOutlet UITableViewCell*fontSizeCell;
  IBOutlet UITableViewCell*timeoutCell;
  IBOutlet UITableViewCell*retriesCell;
  IBOutlet UITableViewCell*maxConnectionsCell;
  IBOutlet UISlider*fontSizeSlider;
  IBOutlet UISlider*maxConnectionsSlider;
  IBOutlet UISlider*timeoutSlider;
  IBOutlet UISlider*retriesSlider;
  NSMutableArray*fontNames;
  NSIndexPath*selectedIndexPath;
  PageViewController*pageViewController;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil appDelegate:(AppDelegate*)anAppDelegate pageViewController:(PageViewController*)aPageViewController;
-(IBAction)fontSizeSiderChanged:(id)sender;
-(IBAction)nightChanged:(id)sender;

@end
