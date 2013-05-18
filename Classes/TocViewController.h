//
//  TocViewController.h
//  diaryreader
//
//  Created by David Finucane on 1/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "Blog.h"
#import "PageViewController.h"

@class PageViewController;
@interface TocViewController : UITableViewController
{
  AppDelegate*appDelegate;
  NSIndexPath*selectedIndexPath;
  PageViewController*pageViewController;
}

- (id)initWithAppDelegate:(AppDelegate*)anAppDelegate pageViewController:(PageViewController*)aPageViewController;

@end
