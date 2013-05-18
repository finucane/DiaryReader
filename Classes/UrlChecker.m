//
//  UrlChecker.m
//  diaryreader
//
//  Created by finucane on 1/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UrlChecker.h"
#import "ScannerCategory.h"
#import "StringCategory.h"
#import "insist.h"

@implementation UrlChecker

-(id) initWithDelegate:(id)aDelegate timeout:(NSTimeInterval)timeout
{
  self = [super initWithTimeout:timeout];
  insist (self);
  delegate = aDelegate;
  return self;
}
- (void) dealloc
{
  [blogID release];
  [super dealloc];
}

-(void) checkUrl:(NSString*)url
{
  insist (url);
  
  /*first clean up url and add http:// if necessary*/
  url = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  if (![url startsWith:@"http://"])
    url = [NSString stringWithFormat:@"http://%@", url];
  
  /*if there's no domain section add .blogspot.com*/
  if (![url grep:@"."])
    url = [url stringByAppendingString:@".blogspot.com"];
  
  NSURLRequest*request = [self requestWithString:url];
  insist (request);
  [connection release];
  
  /*start loading the url*/
  if (!(connection = [NSURLConnection connectionWithRequest:request delegate:self]))
  {
    [delegate urlCheckerFailed:self reason:@"Couldn't connect to blog."];
    return;
  }
  [connection retain];
  [self setPending:YES];
  [self setTimer];
  [delegate urlCheckerStatusChanged:self status:@"Connecting to blog"];
}

-(NSString*)getBlogID
{
  return blogID;
}

- (void) didLoad:(NSScanner*)scanner
{
  insist (scanner);
  insist (delegate);
  
  [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
  
  NSString*s;
  while ([scanner scanPast:@"targetBlogID="] && [scanner scanUpToString:@"&" intoString:&s])
  {
    insist (s);
    /*sanity check*/
    if ([s length] > 200 || [s grep:@">"] || [s grep:@"<"])
      continue;

    [blogID release];
    blogID = [s retain];
    [delegate urlCheckerFinished:self];
    [delegate urlCheckerStatusChanged:self status:[NSString stringWithFormat:@"BlogID is %@", blogID]];
    return;
  }
  [delegate urlCheckerFailed:self reason:@"Not a Google Blogger page (no blogID)."];
}

- (void) didLoadData:(NSData*)data
{
  insist (0);
}

- (void) didFail:(NSError*)error
{
  insist (delegate);
  
  /*when this happens it's because there is no network connection. make the reason string say this
    instead of "invalid argument"*/
  
  [delegate urlCheckerFailed:self reason:@"Network connectivity problem. Try again or check your Wi-Fi settings."];
}


@end
