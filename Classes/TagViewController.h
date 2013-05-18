//
//  TagViewController.h
//  diaryreader
//
//  Created by David Finucane on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Blog.h"
#import "Tags.h"
#import "PageViewController.h"

@interface TagViewController : UITableViewController
{
  Tag*tag;
  AppDelegate*appDelegate;
  NSDateFormatter*formatter;
  PageViewController*pageViewController;
  NSIndexPath*selectedIndexPath;
  BOOL goneByBackButton;
}
-(id)initWithTag:(Tag*)aTag appDelegate:(AppDelegate*)anAppDelegate pageViewController:(PageViewController*)aPageViewController;

@end
