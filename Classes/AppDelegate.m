//
//  AppDelegate.m
//  diaryreader
//
//  Created by finucane on 1/23/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "insist.h"
#import "AppDelegate.h"
#import "LibraryViewController.h"
#import "Blog.h"
#import "TargetConditionals.h"

#define FONT_NAME_KEY @"fontName"
#define FONT_SIZE_KEY @"fontSize"
#define NIGHT_KEY @"night"
#define RETRIES_KEY @"retries"
#define TIMEOUT_KEY @"timeout"
#define MAX_CONNECTIONS_KEY @"maxConnections"
#define RANDOM_FORMAT_KEY @"randomFormat"
#define IDLE_TIMER_KEY @"idleTimer"

@implementation AppDelegate
BOOL testApp;
BOOL verbose;

@synthesize window;


+(NSString*)home
{
  return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
}

- (void) registerDefaults
{
  NSMutableDictionary*defaults = [NSMutableDictionary dictionary];
  insist (defaults);
  
  UIFont*aFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
  
  [defaults setObject:aFont.fontName forKey:FONT_NAME_KEY];
  [defaults setObject: [NSNumber numberWithInt:(int)aFont.pointSize] forKey:FONT_SIZE_KEY];
  [defaults setObject:[NSNumber numberWithBool:NO] forKey:NIGHT_KEY];
  [defaults setObject:[NSNumber numberWithBool:NO] forKey:IDLE_TIMER_KEY];
  [defaults setObject:[NSNumber numberWithInt:DEFAULT_RETRIES] forKey:RETRIES_KEY];
  [defaults setObject:[NSNumber numberWithDouble:DEFAULT_TIMEOUT] forKey:TIMEOUT_KEY];
  [defaults setObject:[NSNumber numberWithInt:DEFAULT_MAX_CONNECTIONS] forKey:MAX_CONNECTIONS_KEY];
  [defaults setObject: DEFAULT_RANDOM_FORMAT forKey:RANDOM_FORMAT_KEY];

  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

-(UIFont*)getFont
{
  return font;
}

-(BOOL)getNightOn
{
  return [[NSUserDefaults standardUserDefaults]boolForKey:NIGHT_KEY];
}

-(BOOL)getIdleTimerOn
{
  return [[NSUserDefaults standardUserDefaults]boolForKey:IDLE_TIMER_KEY];
}

-(void)setFont:(UIFont*)aFont
{
  [font release];
  font = [aFont retain];

  [[NSUserDefaults standardUserDefaults] setObject:font.fontName forKey:FONT_NAME_KEY];
  [[NSUserDefaults standardUserDefaults] setInteger:(int)font.pointSize forKey:FONT_SIZE_KEY];
}

-(void)setNightOn:(BOOL)on
{
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:on] forKey:NIGHT_KEY];
}

-(void)setIdleTimerOn:(BOOL)on
{
  [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:on] forKey:IDLE_TIMER_KEY];
}


-(NSTimeInterval)timeout
{
  return [[NSUserDefaults standardUserDefaults]doubleForKey:TIMEOUT_KEY];
}
-(int)retries
{
  return [[NSUserDefaults standardUserDefaults]integerForKey:RETRIES_KEY];
}
-(int)maxConnections
{
  return [[NSUserDefaults standardUserDefaults]integerForKey:MAX_CONNECTIONS_KEY];
}
-(void)setTimeout:(NSTimeInterval)timeout
{
  insist (timeout >= MIN_TIMEOUT && timeout <= MAX_TIMEOUT);
  [[NSUserDefaults standardUserDefaults] setDouble:timeout forKey:TIMEOUT_KEY];
}
-(void)setMaxConnections:(int)maxConnections
{
  insist (maxConnections >= MIN_MAX_CONNECTIONS && maxConnections <= MAX_MAX_CONNECTIONS);
  [[NSUserDefaults standardUserDefaults] setInteger:maxConnections forKey:MAX_CONNECTIONS_KEY];
}
-(void)setRetries:(int)retries
{
  insist (retries >= MIN_RETRIES && retries <= MAX_RETRIES);
  [[NSUserDefaults standardUserDefaults] setInteger:retries forKey:RETRIES_KEY];
}

-(NSString*)getRandomFormat
{
  return [[NSUserDefaults standardUserDefaults]stringForKey:RANDOM_FORMAT_KEY];
}

- (void)applicationDidFinishLaunching:(UIApplication*)applicationh
{    
  testApp = NO;
  lock = [[NSLock alloc] init];
  insist (lock);
  
  /*hide status bar*/
  [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
  
  [self registerDefaults];
  
  /*get the font default which we are sort of caching*/
  font = [UIFont fontWithName:
            [[NSUserDefaults standardUserDefaults] stringForKey:FONT_NAME_KEY]
                         size:[[NSUserDefaults standardUserDefaults] integerForKey:FONT_SIZE_KEY]];
  
  
  insist (font);
  
  /*make the library, this will be either an empty library or whatever exists on disk*/
  library = [[Library alloc] init];
  insist (library);
  
  /*make the library view controller*/
  libraryViewController = [[LibraryViewController alloc] initWithAppDelegate:self library:library];
  insist (libraryViewController);
  
  /*make the navigation controller, this will manage every view in the whole app. the root view is the library.*/
  
  navigationController = [[UINavigationController alloc] initWithRootViewController:libraryViewController];
  insist (navigationController);
  
  /*we track things going onto the nav controller so we can set how the details look per view*/
  navigationController.delegate = self;
  navigationController.navigationBar.barStyle = UIBarStyleBlack;
  navigationController.toolbar.barStyle = UIBarStyleBlack;
  window.rootViewController = navigationController;
  
  [window addSubview:navigationController.view];
  [window makeKeyAndVisible];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  alertDone = YES;
}

- (void) alertWithTitle:(NSString*)title message:(NSString*)message modal:(BOOL)modal
{
  UIAlertView*alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
  insist (alert);
  alertDone = NO;
  [alert show];
  
  if (modal)
  {
    /*wait for the alert to be dismissed*/
    while(!alertDone)
      [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
  }
  [alert release];
}


- (void)dealloc
{
  [lock release];
  [window release];
  [library release];
  [libraryViewController release];
  [navigationController release];
  [super dealloc];
}

-(UINavigationController*)getNavigationController
{
  return navigationController;
}

-(void)syncLock
{
  [lock lock];
}

-(void)syncUnlock
{
  [lock unlock];
}

-(void) handleLowMemory
{
  [self alertWithTitle:@"Low on Memory" message:@"Save memory by reducing the Max Connection slider under Settings, or by removing some blogs from the library." modal:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  insist (self && library);
  
  /*dump library state to disk*/
  [self syncLock];
  [library sync];
  [self syncUnlock];
}

-(void)push:(UIViewController*)vc animated:(BOOL)animated
{
  [navigationController pushViewController:vc animated:animated];
}

-(void)pop:(BOOL)animated
{
  [navigationController popViewControllerAnimated:animated];
}

-(void) flipOn:(UIViewController*)vc
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: 0.50];
	
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:navigationController.view cache:NO];
  [navigationController pushViewController:vc animated:NO];
	[UIView commitAnimations];
}

-(void) flipOff
{
  [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: 0.50];
	
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:navigationController.view cache:NO];
  [navigationController popViewControllerAnimated:NO];
	[UIView commitAnimations];
}

-(void) fadeOn:(UIViewController*)vc
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: 1.50];
	
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:navigationController.view cache:NO];
  [navigationController pushViewController:vc animated:NO];
	[UIView commitAnimations];
}
 
-(void) popBackTo:(UIViewController*)vc
{
  /*
  [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: 0.50];
   */
	
//	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:navigationController.view cache:NO];
  [navigationController popToViewController:vc animated:NO];
//	[UIView commitAnimations];
}

-(void) popBack
{
  [navigationController popViewControllerAnimated:NO];
}

-(void)navigationController:(UINavigationController *)aNavigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  /*set up the details of the navigation controlled depending on what the viewcontroller about to be topmost wants*/
  
  /*shut up compiler warnings*/
  id vc = viewController;
  
  if ([vc respondsToSelector:@selector(navigationBarHidden)])
    [navigationController setNavigationBarHidden:[vc navigationBarHidden] animated:NO];
  else
    [navigationController setNavigationBarHidden:NO animated:NO];
  
  if ([vc respondsToSelector:@selector(toolbarHidden)])
    [navigationController setToolbarHidden:[vc toolbarHidden] animated:NO];
  else
    [navigationController setToolbarHidden:YES animated:NO];
  
  if ([vc respondsToSelector:@selector(barsTranslucent)])
    navigationController.toolbar.translucent = navigationController.navigationBar.translucent = [vc barsTranslucent];
  else
    navigationController.toolbar.translucent = navigationController.navigationBar.translucent = NO;
}

-(void)forgetCurrentBlog
{
  insist (self && library);
  [library setCurrentBlog:nil];
}

@end
