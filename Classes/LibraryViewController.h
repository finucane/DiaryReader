//
//  LibraryViewController.h
//  diaryreader
//
//  Created by finucane on 1/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Library.h"
#import "AddViewController.h"

@interface LibraryViewController : UITableViewController <ViewControllerForNavigationController, AddViewControllerDelegate>
{
  AppDelegate*appDelegate;
  Library*library;
  UIBarButtonItem*editButton;
  UIBarButtonItem*randomButton;
  Blog*currentBlog;
  NSString*randomBlogID;
}
- (id)initWithAppDelegate:(AppDelegate*)anAppDelegate library:(Library*)aLibrary;
- (IBAction)add:(id)sender;
- (IBAction)edit:(id)sender;
@end
