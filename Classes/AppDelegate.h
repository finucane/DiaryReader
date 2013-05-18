//
//  AppDelegate.h
//  diaryreader
//
//  Created by finucane on 1/23/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Library.h"

#define MIN_FONT_SIZE 5
#define MAX_FONT_SIZE 30
#define FAKE_BR_CHAR 0x001e
#define FAKE_P_CHAR 0x001f
#define MIN_TIMEOUT 1
#define MAX_TIMEOUT 200
#define MIN_RETRIES 1
#define MAX_RETRIES 10
#define MIN_MAX_CONNECTIONS 1
#define MAX_MAX_CONNECTIONS 30

#define DEFAULT_RETRIES 5
#define DEFAULT_TIMEOUT 60
#define DEFAULT_MAX_CONNECTIONS 3
#define DEFAULT_RANDOM_FORMAT @"http://www.blogger.com/next-blog?navBar=true&blogID=%@"
extern BOOL testApp;

@class LibraryViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate, UINavigationControllerDelegate>
{
  UIWindow *window;
  Library*library;
  UINavigationController*navigationController;
  LibraryViewController*libraryViewController;
  NSMutableArray*navbarOnStack;
  UIFont*font;
  NSLock*lock;
  volatile BOOL alertDone;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

+(NSString*)home;
-(void)handleLowMemory;
-(void)push:(UIViewController*)vc animated:(BOOL)animated;
-(void)pop:(BOOL)animated;
-(void) flipOff;
-(void) flipOn:(UIViewController*)vc;
-(void) fadeOn:(UIViewController*)vc;
-(void) popBackTo:(UIViewController*)vc;
-(void) popBack;

-(NSTimeInterval)timeout;
-(int)retries;
-(int)maxConnections;
-(void)setTimeout:(NSTimeInterval)timeout;
-(void)setMaxConnections:(int)maxConnections;
-(void)setRetries:(int)retries;

-(UIFont*)getFont;
-(BOOL)getNightOn;
-(BOOL)getIdleTimerOn;
-(void)setFont:(UIFont*)aFont;
-(void)setNightOn:(BOOL)on;
-(void)setIdleTimerOn:(BOOL)on;
-(NSString*)getRandomFormat;
- (void) alertWithTitle:(NSString*)title message:(NSString*)message modal:(BOOL)modal;
-(void)syncLock;
-(void)syncUnlock;
-(void) handleLowMemory;
-(void)forgetCurrentBlog;
@end


@protocol ViewControllerForNavigationController
@optional
-(BOOL)navigationBarHidden;
-(BOOL)toolbarHidden;
-(BOOL)barsTranslucent;

@end
