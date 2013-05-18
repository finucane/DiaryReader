//
//  DFWebReader.m
//  MyMySpaceMail
//
//  Created by David Finucane on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "DFWebReader.h"
#import "insist.h"
#import "DFError.h"

@implementation DFWebReader

static NSMutableSet*pendingReaders;
static NSLock*pendingLock;

- (id) initWithTimeout:(NSTimeInterval)aTimeout;
{
  [super init];
  
  if (!pendingLock) pendingLock = [[NSLock alloc] init];
  if (!pendingReaders) pendingReaders = [[NSMutableSet alloc] init];
  cancelled = NO;
  timeout = aTimeout;
  return self;
}


- (void) dealloc
{
  [data release];
  [connection release];
  if (timer)
  {
    [timer invalidate];
    [timer release];
    timer = nil;
  }
  data = nil;
  connection = nil;
  [super dealloc];
} 

- (void) timeout:(NSTimer*)timer
{
  if (connection)
  {
    [connection cancel];
    if (!cancelled)
      [self connection:connection didFailWithError: [DFError errorWithDescription:@"timeout"]];
    /*seem to have to do this ourselves*/
  }
}

- (void) setTimer
{
  if (!timer)
    timer = [[NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(timeout:) userInfo:nil repeats:NO] retain];
}

- (void) clearTimer
{
  if (timer)
  {
    [timer invalidate];
    [timer release];
    timer = nil;
  }
}

- (void) setPending:(BOOL)pending
{
  insist (pendingReaders);
  
  [pendingLock lock];
  if (pending)
  {
    insist (![pendingReaders containsObject:self]);
    [pendingReaders addObject:self];
  }
  else
  {
    insist ([pendingReaders containsObject:self]);
    [pendingReaders removeObject:self];
  }
  [pendingLock unlock];
}

- (void) cancel
{
  cancelled = YES;
  if (connection)
    [connection cancel];
  [self clearTimer];
}

-(NSCachedURLResponse *) connection:(NSURLConnection*) connection willCacheResponse:(NSCachedURLResponse*) cachedResponse
{
  return nil;
}

- (void) connection:(NSURLConnection*) aConnection didReceiveResponse:(NSURLResponse*) response
{ 
  [self clearTimer];
  [self setTimer];
  
  if (!data)
      data = [[NSMutableData data] retain];
  
  insist (data);
  [data setLength:0];
}

- (NSString*) salvageString:(NSData*)someData
{
  NSString*s = [[NSString alloc] initWithBytes:(void*)[someData bytes] length:[someData length] encoding:NSUTF8StringEncoding];
  if (!s)
    s = [[NSString alloc] initWithBytes:(void*)[someData bytes] length:[someData length] encoding:NSASCIIStringEncoding];
  return [s autorelease];
}

- (void) connectionDidFinishLoading:(NSURLConnection*) aConnection
{
  [self clearTimer];
  [self setPending:NO];
  [connection release];
  connection = nil;
  
  if ([self isBinary])
    [self didLoadData:data];
  else
  {
    NSString*s = [self salvageString:data];
    if (!s)
    { 
      [self didFail:[DFError errorWithDescription:@"Unexpected Encoding"]];
      [data release]; data = nil;
      return;
    }
    //NSLog ([NSString stringWithFormat:@"%@", s]);
    NSScanner*scanner = [[NSScanner alloc] initWithString:s];
    [self didLoad:scanner];
    [scanner release];
    [data release]; data = nil;
  }
}

- (void) connection:(NSURLConnection*) aConnection didFailWithError:(NSError*) error
{
  [self clearTimer];
  [self setPending:NO];
  [connection release];connection = nil;
  [data release]; data = nil;
  [self didFail:error];
}

- (void) connection:(NSURLConnection*) aConnection didReceiveData:(NSData*) someData
{
  [self clearTimer];
  
  if (!data)
  {
    NSLog(@"no data");
    data = [[NSMutableData data] retain];
   }
  
  insist (data);
  [data appendData:someData];

  if ([self cullData:data])
    [data setLength:0];
  
  [self setTimer];
}

- (NSURLRequest*)requestWithString:(NSString*)s
{
  insist (s);
  return [NSURLRequest requestWithURL:[NSURL URLWithString:s] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
}

- (NSMutableURLRequest*)mutableRequestWithString:(NSString*)s
{
  insist (s);
  return [NSMutableURLRequest requestWithURL:[NSURL URLWithString:s] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
}

-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
  return request;
}

- (void) didLoad:(NSScanner*)scanner
{
  insist (0);
}

- (void) didLoadData:(NSData*)data
{
  insist (0);
}

- (void) didFail:(NSError*)error
{
  insist (0);
}

- (BOOL) isBinary
{
  return NO;
}

- (BOOL) cullData:(NSData*)someData
{
  return NO;
}
@end
