//
//  main.m
//  diaryreader
//
//  Created by finucane on 1/27/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


int main(int argc, char *argv[])
{    
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  int retVal;
  
  /*there is no way to report exceptions correctly on iphone os so just do
   something quick and dirty with NSLog.*/
  
  @try
  {
    retVal = UIApplicationMain(argc, argv, nil, nil);
  }
  @catch (NSException*exception)
  {
    NSLog (@"%@%@", [exception name], [exception reason]);
  }
  [pool release];
  return retVal;
}
