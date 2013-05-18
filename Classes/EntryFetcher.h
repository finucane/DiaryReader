//
//  EntryFetcher.h
//  diaryreader
//
//  Created by finucane on 2/6/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EntryFetcher : NSObject
{
  NSString*url;
  NSString*text;
  id delegate;
  NSTimeInterval timeout;
  int retryCount;
@public
  int recoveryAttempts;
  BOOL done;
}

-(id) initWithUrl:(NSString*)aUrl delegate:(id)aDelegate timeout:(NSTimeInterval)aTimeout retryCount:(int)aRetryCount;
-(id) initWithFetcher:(EntryFetcher*)fetcher;
-(void)go:(id)anArgument;
-(void)reset;
-(NSString*)getText;
@end

@interface NSObject (EntryFetcherDelegate)
- (void) entryFetcherFinished:(EntryFetcher*)fetcher;
- (void) entryFetcherFailed:(EntryFetcher*)fetcher reason:(NSString*)excuse;
@end

@class Blog;
@interface BlogFetcher : NSObject
{
  Blog*blog;
  NSArray*urls;
  NSMutableArray*pendingFetchers;
  int maxThreads;
  int retryCount;
  int numFetched;
  id delegate;
  BOOL cancelled;
  NSTimeInterval timeout;
}

-(NSString*)findContent:(NSString*)text position:(unsigned*)position;
-(NSString*)findContentDesperate:(NSString*)text position:(unsigned*)position;

-(id)initWithUrls:(NSArray*)somUrls blog:(Blog*)blog delegate:(id)aDelegate maxThreads:(int)theMaxThreads timeout:(NSTimeInterval)aTimeout retryCount:(int)aRetryCount;
-(void)go;
-(void)cancel;
@end

@interface NSObject (BlogFetcherDelegate)
- (void) blogFetcherFailed:(BlogFetcher*)fetcher reason:(NSString*)reason;
- (void) blogFetcherFinished:(BlogFetcher*)fetcher;
- (void) blogFetcherProgressed:(BlogFetcher*)fetcher value:(double)value;
@end
