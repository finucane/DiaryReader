//
//  AddViewController.h
//  diaryreader
//
//  Created by finucane on 1/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import "Blog.h"
#import "Library.h"
#import "Downloader.h"
#import "UrlChecker.h"
#import "EntryFetcher.h"

@protocol AddViewControllerDelegate;


@interface AddViewController : UIViewController <UITextFieldDelegate>
{
  AppDelegate*appDelegate;
  Library*library;
  Blog*blog;
  Downloader*downloader;
  BlogFetcher*blogFetcher;
  UrlChecker*urlChecker;
  IBOutlet UILabel*activityLabel;
  IBOutlet UIActivityIndicatorView*activityIndicator;
  IBOutlet UIProgressView*progressView;
  IBOutlet UITextField*downloadTextField;
  IBOutlet UIButton*cancelButton;
  id<AddViewControllerDelegate> delegate;
  NSString*url;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil appDelegate:(AppDelegate*)anAppDelegate delegate:(id<AddViewControllerDelegate>)aDelegate library:(Library*)aLibrary url:(NSString*)aUrl;
-(IBAction)download:(id)sender;
-(IBAction)cancel:(id)sender;

@end


@protocol AddViewControllerDelegate <NSObject>
@required
-(void)addViewController:(AddViewController*)controller didAddBlog:(Blog*)blog;
@end
