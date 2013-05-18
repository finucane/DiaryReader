//
//  Downloader.m
//  diaryreader
//
//  Created by finucane on 1/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Downloader.h"
#import "StringCategory.h"
#import "insist.h"
#import "GTMNSString+HTML.h"
#import "ScannerCategory.h"


@implementation Downloader
- (id) initWithDelegate:(id)aDelegate timeout:(NSTimeInterval)aTimeout blog:(Blog*)aBlog
{
  self = [super initWithTimeout:aTimeout];
  insist (self);
  
  delegate = aDelegate;
  blog = [aBlog retain];
  buffer = [[NSMutableString alloc] init];
  return self;
}

-(void) dealloc
{
  [blog release];
  [buffer release];
  [pool release];
  [super dealloc];
}

/*selectors to wrap the delegate callbacks in so we can call the callbacks on the main thread.
  for the downloaderFinished callback we don't need a wrapper because it has just 1 argument
  so we can call it w/ performSelectorOnMainThread directly.*/
- (void) reportDownloaderFailed:(NSString*)reason
{
  if (cancelled) return;
  insist (self && delegate);
  [delegate downloaderFailed:self reason:reason];
}

- (void) reportDownloaderStatusChanged:(NSString*)status
{
  if (cancelled) return;
  insist (self && delegate);
  [delegate downloaderStatusChanged:self status:status];
}

- (void) reportDownloaderProgressed:(id)anArgument
{
  if (cancelled) return;
  insist (self && delegate);
  [delegate downloaderProgressed:self value:(double)numEntriesDownloaded / (double)numEntriesExpected];
}

/*this is called in a separate thread to download in the background*/
- (void)download:(id)anArgument
{
  insist (self && blog && delegate);
  
  /*we are on a new thread so we have to set up an autorelease pool*/
  pool = [[NSAutoreleasePool alloc] init];
  insist (pool);
  
  /*make the feed url. first get a date just after the latest date the blog knows*/
  NSDate*date = [[[NSDate alloc]initWithTimeInterval:1 sinceDate:[blog getLatestDate]]autorelease];
  insist (date);

  /*get the components of the international format, year, time, and correction from GMT.
    what google wants is slightly different because of the spaces*/
  NSArray*parts = [[date description] nonEmptyComponentsSeparatedByString:@" "];
  
  insist (parts && [parts count] == 3);
  
  /*now we can make the url for all this*/
  NSString*url = [NSString stringWithFormat:@"http://www.blogger.com/feeds/%@/posts/default?published-min=%@T%@&max-results=10000000&orderby=published",
                  [blog getBlogID], [parts objectAtIndex:0], [parts objectAtIndex:1]];
  insist (url);
  
  /*make the url request*/
  NSURLRequest*request = [self requestWithString:url];
  insist (request);
  [connection release];connection = nil;
  
  /*start loading the url*/
  if (!(connection = [NSURLConnection connectionWithRequest:request delegate:self]))
  {
    [self performSelectorOnMainThread:@selector (reportDownloaderFailed:) withObject:@"Couldn't connect to blog." waitUntilDone:YES];
    [pool release];
    return;
  }
  [connection retain];
  [self setPending:YES];
  [self setTimer];
  [self performSelectorOnMainThread:@selector (reportDownloaderStatusChanged:) withObject:@"Fetching blog entries." waitUntilDone:YES];
  
  numEntriesDownloaded = numEntriesExpected = 0;  

  /*now to keep the thread from exiting right now, we use a runloop. this waits for connection events 
    and dispatches them to our handlers.*/
     done = NO;
  while(!done && !cancelled)
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
 
  [pool release]; pool = nil;
  
}


- (void) didLoadData:(NSData*)data
{
  insist (0);
}

- (void) didFail:(NSError*)error
{
  insist (delegate);
  done = YES;
  
  
  /*when this happens it's because there is no network connection. make the reason string say this
   instead of "invalid argument"*/
  
  [self performSelectorOnMainThread:@selector (reportDownloaderFailed:) withObject:@"Network connectivity problem. Try again or check your Wi-Fi settings." waitUntilDone:YES];
}

+(NSString*)dateToString:(NSDate*)date
{
  insist (date);
  NSDateFormatter*formatter = [[[NSDateFormatter alloc] init] autorelease];
  insist (formatter);
  [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
  [formatter setDateStyle:NSDateFormatterFullStyle];
  [formatter setTimeStyle:NSDateFormatterNoStyle];
  
  return [formatter stringForObjectValue:date];
}

/*take a string from xml and unescape it, remove tags from it and any newlines and shit
  so it can go into a label as best it can*/
- (NSString*)labelString:(NSString*)xml
{
  insist (self && xml);

  /*unescape escaped html*/
  NSString*s = [xml gtm_stringByUnescapingFromHTML];
  insist (s);
  
  /*get rid of any newlines that might be in the string.*/
  s = [s stringByCollapsingWhitespaceAndRemovingNewlines];
  insist (s);
  
  /*get rid of tags and other html shit*/
  return [s flattenHTML];  
}
                                    
                                    
/*remove all tags except <p> and <br>*/
+ (NSString*) removeMostTags:(NSString*)s
{
  insist (s);
  
  NSMutableString*ms = [NSMutableString stringWithCapacity:[s length]];
  insist (ms);
  
  int numChars = [s length];
  BOOL inTag = NO;

  BOOL wasInTag = NO;
  for (int i = 0; i < numChars; i++)
  {
    unichar c = [s characterAtIndex:i];
    wasInTag = inTag;
    
    if (c == '<')
    { 
      NSRange r = [s rangeOfString:@"<p>" options:NSCaseInsensitiveSearch range:NSMakeRange (i, 3)];
      if (r.location == i)
        inTag = NO;
      else
      {
        r = [s rangeOfString:@"<br>" options:NSCaseInsensitiveSearch range:NSMakeRange (i, 4)];
        if (r.location == i)
          inTag = NO;
        else
          inTag = YES;
      }
    }
    else if(c == '>')
      inTag = NO;
    if (!inTag && !wasInTag)
      [ms appendFormat:@"%C", c];
  }
  
	return ms;
}
 
+ (NSString*)prettyPage:(NSString*)content date:(NSDate*)date title:(NSString*)title
{
  insist (content); 
  
#if 0
  /*make a local autorelease pool so we can keep freeing temp string objects*/
  NSAutoreleasePool*inner = [[NSAutoreleasePool alloc] init];
  insist (inner);
#endif
  
  /*make the text html so we can parse it*/
  content = [content gtm_stringByUnescapingFromHTML];
  insist (content);
  
  /*do we really have to do this twice, yes because &*/
  content = [content gtm_stringByUnescapingFromHTML];
  insist (content);
  
  /*get rid of anything involving the style & script tags*/
  content = [content eradicateTag:@"style"];
  
  content = [content eradicateTag:@"script"];
  
  /*get rid of any newlines that might be in the string.*/
  content = [content stringByCollapsingWhitespaceAndRemovingNewlines];
  insist (content);
  
  /*get rid of repeated paragraph marks. first normalize the tags because they can be like <p />*/  

  content = [content replaceTagsOfType:@"p" with:@"<p>"];
  
  content = [content replaceTagsOfType:@"br" with:@"<br>"];
  
  /*make sure that <div tags, which can be used to do line breaks, have whitespace
   around them, so that when we remove the tags the words around them are still separated*/
  
  content = [content stringByReplacingOccurrencesOfString:@"<div" withString:@" <div" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [content length])];
  
  content = [content stringByReplacingOccurrencesOfString:@"<br><br>" withString:@"<p>"];
  content = [Downloader removeMostTags:content];
  
  content = [content stringWithoutRepeatedString:@"<p>" options:NSCaseInsensitiveSearch];
  
  content = [content stringWithoutRepeatedString:@"<br>" options:NSCaseInsensitiveSearch];
  
  content = [content stringWithoutRepeatedString:@" " options:NSCaseInsensitiveSearch];
  
  /*replace paragraph marks*/
  content = [content stringByReplacingOccurrencesOfString:@"<p>" withString:[NSString stringWithFormat:@"%C", FAKE_P_CHAR] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [content length])];
  
  content = [content stringByReplacingOccurrencesOfString:@"<br>" withString:[NSString stringWithFormat:@"%C", FAKE_BR_CHAR] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [content length])];  
  
  /*if a date was supplied then it's a normal content entry and we should format it*/
  if (date)
  {
    NSString*niceDate = [Downloader dateToString:date];
    insist (niceDate);
    /*now make the page.*/
    if (title)
      return [NSString stringWithFormat:@"%@%C%@%C%C%C%@%C%C", niceDate, FAKE_BR_CHAR, title, FAKE_BR_CHAR, FAKE_BR_CHAR, FAKE_P_CHAR, content, FAKE_BR_CHAR, FAKE_BR_CHAR];
    else
      return [NSString stringWithFormat:@"%@%C%C%@%C%C", niceDate, FAKE_BR_CHAR, FAKE_P_CHAR, content, FAKE_BR_CHAR, FAKE_BR_CHAR];
  }
  
  /*it's a summary entry so just save the content, we'll have to make a real entry later*/
  return content;
}

/*doesn't include the http://*/
-(NSString*)findUrl:(NSString*)xml
{
  NSScanner*scanner = [NSScanner scannerWithString:xml];
    
  /*by default scanners are case insensitive*/
  NSString*s = nil;    
  while (![scanner isAtEnd])
  {
  /*do some jumping around to make sure we don't rely on whitespace
    or single quotes around the url*/
    if (![scanner scanPast:@"<link rel="] ||
        ![scanner scanPast:@"alternate" before:@"/>"] ||
        ![scanner scanPast:@"href=" before:@"/>"] ||
        ![scanner scanPast:@"http://" before:@"/>"])
      continue;
    
    if (![scanner scanIntoString:&s upToNearest:@"/>", @" ", @"'", nil])
      continue;
    return s;
  }
  return nil;
}


/*
  return a string that has all the useful stuff out of an xml entry section.
  we strip off all the tags and mostly ignore what they might have meant, only
  trying to preserve paragraph breaks. if the entry is empty return nil.
  the published date is returned in "date", if there is none (it's some error)
  and then nil is returned;
 
  convert the paragraph breaks to special unicode characters so we can layout the
  text.
 
  if the text is summary instead of full content, url is set to the page url.
  we assume that any time a blog is queried w/ the google api, it's either going to give
  us all summaries or all contents.
*/

- (NSString*)plainText:(NSString*)xml date:(NSDate**)date title:(NSString**)title url:(NSString**)url
{
  insist (self && xml && date && title);
  
  /*google's date format is: 2010-10-30T09:55:00.000Z*/
  NSString*s = [xml stringBetweenTags:@"published"];
  if (!s) return nil;

  /*change the format to 2010-10-30 09:55:00 +0000*/
    
  NSMutableString*ms = [NSMutableString stringWithString:s];
  insist (ms);
  
  /*stop parsing after the seconds field and make up a timezone offset*/
  NSRange r = [ms rangeOfString:@"T"];
  if (r.location != NSNotFound && r.location < [ms length] - 9)
  {
    [ms replaceCharactersInRange:r withString:@" "];
    r.location += 9;
    [ms replaceCharactersInRange:NSMakeRange (r.location, [ms length] - r.location) withString:@" +0000"];
    
  }
#if 0
  if ([ms grep:@"Z"])
  {
    /*2007-12-01T12:50:46.605Z*/
    [ms replaceOccurrencesOfString:@"T" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [ms length])];
    [ms replaceOccurrencesOfString:@"." withString:@" +0" options:NSLiteralSearch range:NSMakeRange(0, [ms length])];
    [ms replaceOccurrencesOfString:@"Z" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [ms length])];
  }
  else
  {
    /*2010-02-16T15:35:00.001-08:00*/
    [ms replaceOccurrencesOfString:@"T" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [ms length])];
    
    NSRange r1 = [ms rangeOfString:@"."];
    if (r1.location != NSNotFound && r1.location < [ms length] - 4)
    {
      [ms replaceCharactersInRange:NSMakeRange (r1.location, 4) withString:@" "];
    }
  }
#endif
  *date = [NSDate dateWithString:ms];
  if (!*date) return nil;
  
  /*get the title. there should always be one but if not, don't freak out.*/
  if ((*title = [xml stringBetweenTags:@"title"]))
    *title  = [*title gtm_stringByUnescapingFromHTML];

  
  /*get the posting. there should be one either in content or summary*/
  
  NSString*content = [xml stringBetweenTags:@"content"];
  /*if there's no content look for shit in "summary"*/
  BOOL summary = NO;
  if (!content)
  {
    content = [xml stringBetweenTags:@"summary"];
    
    /*if we can't find the url it's a malformed entry and junk it*/
    NSString*s = [self findUrl:xml];

    if (!content || !s) return nil;
    
    /*fix the url*/
    summary = YES;
    *url = [NSString stringWithFormat:@"http://%@", s];
  }
  
  if (!content) return nil;
  
  /*if it's summary text don't format with at title or date. prettyPage does lots of 
    string operations so wrap it in an autorelease pool.*/

  NSAutoreleasePool*p = [[NSAutoreleasePool alloc] init];
  insist (p);
  
  NSString*pretty = [Downloader prettyPage:content date:summary ? nil: *date title:summary ? nil : *title];
  
  [pretty retain];
  [p release];
  
  return [pretty autorelease];
}

- (void) updateTagsWith:(NSString*)substring
{
  insist (self && substring && blog);
  
  NSScanner*scanner = [NSScanner scannerWithString:substring];
  insist (scanner);

  NSCharacterSet*quotes = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
  insist (quotes);
  
  while ([scanner scanPast:@"<category"])
  {
    /*get to nearly where the tag is going to be*/
    if (![scanner scanPast:@"term=" before:@"/>"])
      continue;
    NSString*s;
    BOOL b = [scanner scanUpToString:@"/>" intoString:&s];
    insist (b);
  
    /*put it into a mutable string so can screw with it*/
    NSMutableString*ms = [NSMutableString stringWithString:s];
    
    /*remove any leading quote*/
    if ([ms startsWith:@"\""] || [ms startsWith:@"'"])
      [ms deleteCharactersInRange:NSMakeRange(0, 1)];

    /*and anything after and including the first quote left, if any*/
    NSRange r = [ms rangeOfCharacterFromSet:quotes];
    if (r.location != NSNotFound)
      [ms deleteCharactersInRange:NSMakeRange(r.location, [ms length] - r.location)];
    
    /*if we have any damn thing left after doing all this shitty code, add it as a tag*/
    if ([ms length])
      [blog updateTagForLastText:[ms gtm_stringByUnescapingFromHTML]];
  }
}

/*wrap an autorelease pool around eating*/
- (void)eatWrapper:(NSString*)s
{
  NSAutoreleasePool*p = [[NSAutoreleasePool alloc] init];
  insist (p);
  [self eat:s];
  [p release];
}
- (void) eat:(NSString*)chunk
{
  insist (self && buffer && chunk);
  insist (delegate);
  insist (blog);

  NSDate*latestDate = [blog getLatestDate];
  insist (latestDate);
  
  /*add the new chunk of xml to our buffer string*/
  [buffer appendString:chunk];
  
  /*go through and process as many <entry> </entry> sections as there are in the string*/
  for (;;)
  {
    /*find where the first <entry is, if any*/
    NSRange r1 = [buffer rangeOfString:@"<entry" options:NSCaseInsensitiveSearch];
    if (r1.location == NSNotFound)
      break;
    
    /*get the range of the rest of the buffer*/
    NSRange remainder = NSMakeRange(r1.location, [buffer length] - r1.location);
    
    /*find where the first </entry is, if any*/
    NSRange r2 = [buffer rangeOfString:@"</entry" options:NSCaseInsensitiveSearch range:remainder];
    if (r2.location == NSNotFound)
      break;
    
    insist (r2.location > r1.location);
    
    /*now we have an <entry ...> </entry ....> pair. process it*/
    NSString*substring = [buffer substringWithRange:NSMakeRange(r1.location, r2.location-r1.location)];
    insist (substring);
    
    if (numEntriesDownloaded == 0)
    {
      /*we are at the start of the buffer. see if we can find how many entries to expect, so we can
        use a progressview*/
      NSString*totalResults = [buffer stringBetweenTags:@"openSearch:totalResults"];
      if (totalResults)
      {
        numEntriesExpected = [totalResults intValue];
        [self performSelectorOnMainThread:@selector(reportDownloaderStatusChanged:) withObject:[NSString stringWithFormat:@"Reading %d blog entries.", numEntriesExpected] waitUntilDone:YES];
      }
      
      /*also look for the title and set that if we can find it*/
      NSString*title = [buffer stringBetweenTags:@"title"];
      if (title)
        [blog setTitle:[self labelString:title]];
      
      /*and the subtitle and set that if we can find it*/
      NSString*subtitle = [buffer stringBetweenTags:@"subtitle"];
      if (subtitle)
        [blog setSubtitle:[self labelString:subtitle]];
      
      /*and the url without the http://*/
      NSString*url = [self findUrl:substring]; 
      if (url)
        [blog setBlogUrl:[url substringToString:@"/"]];
    }
    
    //do something w/ substring here*/
    NSDate*date;
    NSString*title;
    NSString*url = nil;
    //NSLog(@"substring is %@", substring);
    NSString*s = [self plainText:substring date:&date title:&title url:&url];
    
    /*the broken google api will actually not obey our min-date request perfectly so throw out what would be a duplicate*/
    if (s && [date compare:latestDate] == NSOrderedDescending)
    {
      /*add the new entry to the blog's tempEntries stuff*/
      [blog updateText:s date:date title:title?title:@"" url:url];
      
      /*also add any tags we can find*/
      [self updateTagsWith:substring];
      numEntriesDownloaded++;
    }
    if (numEntriesExpected)
      [self performSelectorOnMainThread:@selector (reportDownloaderProgressed:) withObject:nil waitUntilDone:YES];

    /*get rid of that entry and move on to any more entries in the buffer*/
    [buffer deleteCharactersInRange:NSMakeRange(0, r2.location+r2.length)];
  }
}

- (BOOL) cullData:(NSData*)someData
{
  /*first get a string we can use*/
  NSString*s = [self salvageString:someData];
  
  /*if something terrible went wrong, we are screwed, we will handle this when
    the whole download is done. anyway for this chunk, cull it*/
  if (!s) return YES;
  
  /*if this chunk of text has a close entry tag then we can use it*/
  if ([s igrep:@"</entry"])
  {
    [self eatWrapper:s];
    return YES;
  }
  /*nothing's in this data that we can deal w/, let it accumulate*/
  return NO;
}

/*anything left in the download ends up here. this will always be called at the end.*/
- (void) didLoad:(NSScanner*)scanner
{
  insist (scanner);
  insist (delegate);

  [self eatWrapper:[scanner string]];
  done = YES;
  if (!cancelled)
    [delegate performSelectorOnMainThread:@selector(downloaderFinished:) withObject:self waitUntilDone:YES];
}


@end
