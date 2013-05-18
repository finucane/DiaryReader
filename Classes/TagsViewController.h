//
//  TagsViewController.h
//  diaryreader
//
//  Created by David Finucane on 1/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Blog.h"
#import "AppDelegate.h"
#import "PageViewController.h"

@class PageViewController;
@interface TagsViewController : UITableViewController
{
  AppDelegate*appDelegate;
  PageViewController*pageViewController;
}
- (id) initWithAppDelegate:(AppDelegate*)anAppDelegate pageViewController:(PageViewController*)aPageViewController;
@end
