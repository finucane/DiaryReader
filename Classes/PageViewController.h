//
//  PageViewController.h
//  diaryreader
//
//  Created by finucane on 1/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Blog.h"
#import "TocViewController.h"
#import "TagsViewController.h"
#import "Downloader.h"
#import "Paginator.h"


@interface PageView: UIView
{
  CGLayerRef layer;
}
- (id)initWithCoder:(NSCoder *)decoder;
- (CGContextRef)getContext;
- (CGLayerRef)getLayer;
- (void)setLayer:(CGLayerRef)aLayer;
- (void)clearNightOn:(BOOL)nightOn;

@end

typedef struct _PageInfo
{
  Paginator*paginator;
  unsigned topPosition; //in global space
  unsigned length;      //in local space
  BOOL dirty;
}PageInfo;

@class TocViewController;
@class TagsViewController;
@class TagViewController;

@interface PageViewController : UIViewController <ViewControllerForNavigationController>
{
  Blog*blog;
  AppDelegate*appDelegate;
  TocViewController*tocViewController;
  TagsViewController*tagsViewController;
  IBOutlet UIActivityIndicatorView*activityIndicator;
  IBOutlet UIView*threePageView;
  IBOutlet UIView*activityView;
  IBOutlet PageView*leftView;
  IBOutlet PageView*middleView;
  IBOutlet PageView*rightView;
  BOOL barsVisible, moved;
  CGRect left, middle, right;
  CGRect pageFrame;
  PageInfo leftInfo, middleInfo, rightInfo;
  CGPoint startPoint;
  CGFloat startThreePageViewX;
  NSTimeInterval startTime;
  int state;
  int testRandomCount;
  SEL testSelector;
  TagViewController*tagViewController;
}
-(BOOL)doneDrawingWrapper;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil appDelegate:(AppDelegate*)anAppDelegate blog:(Blog*)aBlog;
-(IBAction)toc:(id)sender;
-(IBAction)tags:(id)sender;
-(IBAction)settings:(id)sender;
-(IBAction)refresh:(id)sender;
-(void) redrawJustColors:(BOOL)justColors;
-(void)setActivityViewBackgroundColor:(UIColor*)color;
-(Blog*)getBlog;
-(void)setTagViewController:(TagViewController*)controller;
@end
