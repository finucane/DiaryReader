//
//  EntryFetcher.m
//  diaryreader
//
//  Created by finucane on 2/6/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "EntryFetcher.h"
#import "insist.h"
#import "Blog.h"
#import "Downloader.h"
#import "ScannerCategory.h"
#import "StringCategory.h"

#define SUBSTRING_MATCH_LENGTH 10

@implementation EntryFetcher


-(id) initWithUrl:(NSString*)aUrl delegate:(id)aDelegate timeout:(NSTimeInterval)aTimeout retryCount:(int)aRetryCount;
{
  insist (aRetryCount >= 0);
  
  self = [super init];
  insist (self);
  url = [aUrl retain];
  delegate = aDelegate;
  timeout = aTimeout;
  retryCount = aRetryCount;
  
  text = nil;
  recoveryAttempts = 0;
  return self;
}

-(id) initWithFetcher:(EntryFetcher*)fetcher
{
  insist (fetcher);
  
  self = [super init];
  insist (self);
  url = [fetcher->url retain];
  delegate = fetcher->delegate;
  timeout = fetcher->timeout;
  retryCount = fetcher->retryCount;
  text = nil;
  recoveryAttempts = 0;
  
  return self;
}

-(NSString*)getText
{
  return text;
}
-(void) dealloc
{
  [url release];
  [text release];
  [super dealloc];
}


- (void) reportEntryFetcherFailed:(NSString*)reason
{
  insist (self && delegate);
  [delegate entryFetcherFailed:self reason:reason];
}

- (NSURLRequest*)requestWithString:(NSString*)s
{
  insist (s);
  return [NSURLRequest requestWithURL:[NSURL URLWithString:s] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout];
}

- (NSString*) salvageString:(NSData*)someData
{
  NSString*s = [[NSString alloc] initWithBytes:(void*)[someData bytes] length:[someData length] encoding:NSUTF8StringEncoding];
  if (!s)
    s = [[NSString alloc] initWithBytes:(void*)[someData bytes] length:[someData length] encoding:NSASCIIStringEncoding];
  return [s autorelease];
}

/*put the fetcher back into a state where it can go again*/
-(void)reset
{
  [text release]; text = nil;
}

/*fetch an entry page synchronously and get the raw content entry text out of it.
  we do this on a separate thread but callback to the deleage on the main thread,
  for 2 reasons, one because the last callback will eventually trigger some user
  interface stuff, and 2ndly because this serializes access to BlogFetcher's
  data structures, so we don't need locks. return YES if the fetch worked.*/
-(BOOL)goWithError:(NSString**)error
{
  insist (error);
  
  insist (self && url && delegate);
  
  /*get the page*/
  NSURLRequest*request = [self requestWithString:url];
  if (!request)
  {
    *error = @"bad url";
    return NO;
  }
  
  insist (request);
  NSURLResponse*response;
  NSError*anError;
  NSData*data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&anError];
  
  if (!data)
  {
    /*failed*/
    *error = [anError localizedDescription];
    return NO;
  }
  
  /*get the string for the data*/
  NSString*s = [self salvageString:data];
  if (!s)
  {
    *error = @"Unexpected encoding";
    return NO;
  }
  /*get rid of anything involving the style and script tags*/

  s = [s eradicateTag:@"style"];
  text = [[s eradicateTag:@"script"] retain];
  return YES;
}

/*wrapper around the main thread routine to allow retries*/
-(void)go:(id)anArgument
{
  done = NO;
   /*we are on a thread*/
  NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
  insist (pool);
  
  NSString*error;
  for (int i = 0; i <= retryCount; i++)
  {
    /*if it worked, we are done*/
    if ([self goWithError:&error])
    {
      [pool release];
      [delegate performSelectorOnMainThread:@selector(entryFetcherFinished:) withObject:self waitUntilDone:YES];
      return;
    }
    [pool release]; 
    pool = [[NSAutoreleasePool alloc] init];
    insist (pool);
  }
  [self reportEntryFetcherFailed:error];
  [pool release];
}

@end

@implementation BlogFetcher

-(id)initWithUrls:(NSArray*)someUrls blog:(Blog*)aBlog delegate:(id)aDelegate maxThreads:(int)theMaxThreads timeout:(NSTimeInterval)aTimeout retryCount:(int)aRetryCount
{
  insist (someUrls && aDelegate && theMaxThreads > 0 && aBlog);
  
  self = [super init];
  insist (self);
  delegate = aDelegate;
  urls = [someUrls retain];
  blog = [aBlog retain];
  timeout = aTimeout;
  maxThreads = theMaxThreads;
  retryCount = aRetryCount;
  pendingFetchers = [[NSMutableArray arrayWithCapacity:maxThreads]retain];
  insist (pendingFetchers);
  cancelled = NO;
  return self;
}

-(void) dealloc
{
  [urls release];
  [pendingFetchers release];
  [blog release];
  [super dealloc];
}

- (void) fetchMore
{
  insist (self && urls && [urls count] && numFetched >= 0 && numFetched <= [urls count]);
  insist (maxThreads > 0);
  
  if (numFetched == [urls count] || cancelled && [pendingFetchers count] == 0)
  {
    /*done*/
    if (!cancelled)
      [delegate blogFetcherFinished:self];
    else
      [self release];//we were orphaned, kill ourselves now
    return;
  }
  
  /*if we're cancelled don't queue up more work*/
  if (cancelled) return;

  /*we have more work to do, start up as many new fetchers as we can*/
  int urlIndex;
  while ([pendingFetchers count] < maxThreads && (urlIndex = [pendingFetchers count] + numFetched) < [urls count])
  {
    EntryFetcher*fetcher = [[EntryFetcher alloc] initWithUrl:[urls objectAtIndex:urlIndex] delegate:self timeout:timeout retryCount:retryCount];
    insist (fetcher);
    [pendingFetchers addObject:fetcher];
    [fetcher release];
    [NSThread detachNewThreadSelector:@selector (go:) toTarget:fetcher withObject:nil];
  }
}

/*this is run on the main thread*/
-(void)go
{  
  insist (self && delegate && urls);
  insist (pendingFetchers);
 
  cancelled = NO;
  [self fetchMore];
}

- (void) entryFetcherFinished:(EntryFetcher*)fetcher
{
  insist (self && fetcher && delegate && blog);
  
  /*a fetcher finished.*/
  fetcher->done = YES;

  /*process all the finished fetchers from 0 ... to the first not yet done fetcher.
    this way we give the results to our delegate in order*/
  while ([pendingFetchers count])
  {
    EntryFetcher*pending = [pendingFetchers objectAtIndex:0];
    insist (pending);
    if (!pending->done)
      break;
    
    /*get the content part of the html, based on the start tag. if we couldn't find any context
      then we'll let the delegate handle it -- nothing we can do.
     
      we try getting content using 2 heuristics and if both work we'll guess which answer
      to pick.*/
    unsigned p1, p2;
    NSString*text = [pending getText];
    NSString*s = nil;
    NSString*s1 = [self findContent:text position:&p1];
    NSString*s2 = [self findContentDesperate:text position:&p2];
    
    /*tell the delegate and release the fetcher. if we're cancelled don't do this,
      but continue processing finished fetchers. we'll report the cancellation as
      done when all the outstanding fetchers have completed.*/
    
    numFetched++;
 
    if (!cancelled)      
    {
      /*format the contents into a page*/
      if (!s1 && !s2)
      {
        /*it might be a page truncated by google throttling us or some such shit.*/
          
        if (fetcher->recoveryAttempts < retryCount)
        {
          /*reduce maxTheads which we are calling maxConnections in the settings*/
          if (maxThreads > 2)
            maxThreads /= 2;
          numFetched--;
          [NSThread sleepForTimeInterval:0.1];
          EntryFetcher*newFetcher = [[EntryFetcher alloc] initWithFetcher:fetcher];
          insist (newFetcher);
          newFetcher->recoveryAttempts = fetcher->recoveryAttempts + 1;
          [pendingFetchers replaceObjectAtIndex:0 withObject:newFetcher];
          [newFetcher release];
          [NSThread detachNewThreadSelector:@selector (go:) toTarget:newFetcher withObject:nil];

          return;
        }
        s = @"(Couldn't fetch blog page.)";
      }
      else
      {
        /*break ties by picking contents earlier in the page. this is because most of a blog
          page is comments and these always follow the content*/
        
        if (s1 && s2)
          s = p1 < p2 ? s1 : s2;
        else
          s = s1?s1:s2;
      }
            
      NSDate*date;
      NSString*title;
      [blog getNextFetchDate:&date title:&title];
      NSString*page = [Downloader prettyPage:s date:date title:title];
      
      /*give the page to the blog*/
      [blog updateFetch:page];
      [delegate blogFetcherProgressed:self value:(double)numFetched / (double)[urls count]];
    }

    [pendingFetchers removeObjectAtIndex:0];

  }
  
  /*check for more work*/
  [self fetchMore];
}

-(void)cancel
{
  cancelled = YES;
}


/*search a page of html for the blog entry and return it.
  the heuristic is: search the page for text between <div> and </div> tags
  and pick the first chunk that has more than 50% of the words in the summary text.
 
  we assume any content doesn't itself contain <div> so we
  only look between <div> and the next <div> or </div>.
*/
-(NSString*)findContent:(NSString*)text position:(unsigned*)position
{
  insist (self && blog && text && position);
 
  /*get the summary for this page. it should not contain any html tags*/
  NSString*summary = [blog getFetchSummary:numFetched];
  insist (summary);
  
  NSCharacterSet*whitespace = [NSCharacterSet characterSetWithCharactersInString:
                               [NSString stringWithFormat:@"%C%C \n\t\r", FAKE_P_CHAR, FAKE_BR_CHAR]];
  insist (whitespace);
  
  NSArray*words = [summary nonEmptyComponentsSeparatedByCharactersInSet:whitespace];
  if (!words || [words count] == 0)
    return nil;

  NSScanner*scanner = [NSScanner scannerWithString:text];
  insist (scanner);
  
  NSAutoreleasePool*inner = nil;
  
  while ([scanner scanPast:@"<div"] && [scanner scanPast:@">"])
  {
    [inner release];
    inner = [[NSAutoreleasePool alloc] init];
    insist (inner);
        
    /*we might be right at a </div in which case scanUpToString would fail since nothing moved.
      check for that first*/
    if ([scanner scanString:@"<div" intoString:nil] || [scanner scanString:@"</div" intoString:nil])
      continue;
    
    *position = [scanner scanLocation];
    /*grab the stuff between div tags*/
    NSString*s;
    if (![scanner scanIntoString:&s upToNearest:@"<div", @"</div", nil])
      break;//malformed html
    
    insist (s);
    
    /*get rid of all the tags*/
    NSString*contents = [s removeTags];
    insist (s);
    
    /*our baby test is to go down the list of words in the summary and count how many are found in this section.
      we don't care about making sure duplicated words in the summary are also duplicated in the text, or about
      order, though it wouldn't be hard to add this restriction. it shouldn't matter, we're using this test
      mainly to exclude <div> sections that are obviously noise, not to pick out a div section, basically the
      first div section that has any human text specific to the summary in it is going to be the blog content.
      we are case sensitive but that shouldn't matter either.*/
    
    int numMatches = 0;
    for (int i = 0; i < [words count]; i++)
    {
      NSRange r = [contents rangeOfString:[words objectAtIndex:i]];
      if (r.location != NSNotFound)
        numMatches++;
    }
    if ((double)numMatches / (double)[words count] > 0.5)
    {
      /*move the answer to the outer autorelease pool*/
      [s retain]; [inner release]; [s autorelease];
      return s; //found it!
    }
  }
  [inner release];
  return nil;
}


/*search a page of html for the blog entry and return it.
 the heuristic is: search for the first set of non tag words that matches some series of
 words in the summary text at least 10 words long. decide that that's where the content is,
 the go backwards and fowards to find the closest <div> </div> pair and grab everything in between
 
 position is returned as where in the text the content was.
 */

-(NSString*)findContentDesperate:(NSString*)text position:(unsigned*)position
{
  insist (self && blog && text);
  
  /*get the summary for this page. it should not contain any html tags*/
  NSString*summary = [blog getFetchSummary:numFetched];
  insist (summary);
  
  NSCharacterSet*whitespace = [NSCharacterSet characterSetWithCharactersInString:
                               [NSString stringWithFormat:@"%C%C \n\t\r", FAKE_P_CHAR, FAKE_BR_CHAR]];
  insist (whitespace);
  
  NSArray*words = [summary nonEmptyComponentsSeparatedByCharactersInSet:whitespace];
  if (!words || [words count] == 0)
    return nil;
  
  NSScanner*scanner = [NSScanner scannerWithString:text];
  insist (scanner);
  
  NSAutoreleasePool*inner = nil;
  int matchRequirement = [words count] < SUBSTRING_MATCH_LENGTH ? [words count] : SUBSTRING_MATCH_LENGTH;
  
  while ([scanner scanPast:@"<"] && [scanner scanPast:@">"])
  {
    [inner release];
    inner = [[NSAutoreleasePool alloc] init];
    insist (inner);
            
    /*we are at the end of a tag. remember the start*/
    unsigned location = [scanner scanLocation];
    *position = location;
    
    /*grab the blob of text from where we are now to the start of the next tag that's not <p or <br*/
    NSString*blob = nil;
    BOOL escape = NO;
    while (![scanner isAtEnd])
    {
      if (![scanner scanUpToString:@"<" intoString:nil])
      {
        escape = YES;
        break;
      }
      if (![scanner scanString:@"<p " intoString:nil] &&
          ![scanner scanString:@"<p>" intoString:nil] &&
          ![scanner scanString:@"<br>" intoString:nil] &&
          ![scanner scanString:@"<br " intoString:nil])
        break;
    }
    if ([scanner isAtEnd])
      break;
    if (escape) continue;
    blob = [text substringWithRange:NSMakeRange(location, [scanner scanLocation] - location)];
    insist (blob);
    
    /*dump any of the tags, these will be just p and br*/
    blob = [blob removeTags];
    
    /*get all the words from the blob of text*/
    NSArray*blobWords = [blob nonEmptyComponentsSeparatedByCharactersInSet:whitespace];
    if (!blobWords || [blobWords count] < matchRequirement)
      continue;
    
    /*try to find a substring match*/
    for (int i = 0; i < [blobWords count] && !escape ; i++)
    {
      NSString*blobWord = [blobWords objectAtIndex:i];
      insist (blobWord);
      for (int j = 0; j < [words count] && !escape; j++)
      {
        NSString*word = [words objectAtIndex:j];
        insist (word);
        
        if (![blobWord isEqualToString:word])
          continue;
        
        /*we have a possible start of a substring match. try counting out matchRequirement matches*/          
        int k;

        for (k = 1; k < matchRequirement && j+k < [words count] && i+k < [blobWords count]; k++)
        {
          if (![[words objectAtIndex:j+k] isEqualToString:[blobWords objectAtIndex:i+k]])
            break;
        }
        if (k == matchRequirement)
        {
          /*found it. now search backwards for the nearest <div>. include a search for a space to try to find a nonempty div,
            also make sure the div's close tag is after the start of our blob*/
          
          NSRange r = NSMakeRange(0, location);
          for (;;)
          {
            NSRange r1 = [text rangeOfString:@"<div " options:NSCaseInsensitiveSearch | NSBackwardsSearch range:r];
            if (r1.location == NSNotFound)
            {
              /*we aren't in a usable div somehow. give up on this whole blob of text*/
              escape = YES;
              break;
            }
            /*now look forward and find what matches this div*/
            NSRange r2 = [text rangeOfStringBetweenNestedTagsOfType:@"div" range:NSMakeRange(r1.location, [text length] - r1.location)];
            if (r2.location == NSNotFound)
            {
              escape = YES;
              break;
            }
            /*check to make sure the close div is after the start of the blob*/

            if (r2.location + r2.length >= location)
            {
              /*get off the inner pool*/
              [inner release];
              
              /*we have the range of the actual contents (hopefully)*/
              return [text substringWithRange:r2];              
            }
            r = NSMakeRange(0, r1.location);
          }
        }
        if (escape) break;
      }
    }
  }
  [inner release];
  return nil;
}



@end



