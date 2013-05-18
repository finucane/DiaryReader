//
//  Blog.m
//  diaryreader
//
//  Created by finucane on 1/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Blog.h"
#import "insist.h"

#define SECONDS_PER_YEAR 31557600.0
#define BLOG_FMT @"%@/blog_archive"
#include "AppDelegate.h"

@implementation Entry

-(id)initWithCoder:(NSCoder*)coder
{
  insist (coder);
  self = [super init];
  insist (self);
  offset = (unsigned) [coder decodeIntForKey:@"offset"];
  length = (unsigned) [coder decodeIntForKey:@"length"];
  gap = (unsigned) [coder decodeIntForKey:@"gap"];
  date = [[coder decodeObjectForKey:@"date"] retain];
  title = [[coder decodeObjectForKey:@"title"] retain];
  return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
  insist (self && coder);

  [coder encodeInt:(int) offset forKey:@"offset"];
  [coder encodeInt:(int) length forKey:@"length"];
  [coder encodeInt:(int) gap forKey:@"gap"];
  [coder encodeObject:date forKey:@"date"];
  [coder encodeObject:title forKey:@"title"];
}

- (id)initWithOffset:(unsigned) anOffset length:(unsigned) aLength date:(NSDate*)aDate title:(NSString*)aTitle
{
  self = [super init];
  insist (self);
  offset = anOffset;
  length = aLength;
  date = [aDate retain];
  title = [aTitle retain];
  gap = 0;
  return self;
}
- (unsigned) getOffset
{
  return offset;
}
- (unsigned) getLength
{
  return length;
}
- (NSDate*)getDate
{
  return date;
}
- (NSString*)getTitle
{
  return title;
}

- (void) dealloc
{
  [date release];
  [super dealloc];
}

@end

@implementation Month

-(id)initWithCoder:(NSCoder*)coder
{
  insist (coder);
  self = [super init];
  insist (self);
  firstEntry = (unsigned) [coder decodeIntForKey:@"firstEntry"];
  numEntries = (unsigned) [coder decodeIntForKey:@"numEntries"];
  insist (numEntries);
  date = [[coder decodeObjectForKey:@"date"] retain];
  insist (date);
  label = nil;
  return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
  insist (self && coder);

  [coder encodeInt:(int) firstEntry forKey:@"firstEntry"];
  [coder encodeInt:(int) numEntries forKey:@"numEntries"];
  [coder encodeObject:date forKey:@"date"];
  insist (numEntries);
}

-(id)initWithDate:(NSDate*)aDate
{
  insist (aDate);
  self = [super init];
  insist (self);
  
  date = [aDate retain];
  insist (date);
  
  label = nil;
  return self;
}

-(void) dealloc
{
  [label release];
  [date release];
  [super dealloc];
}

-(NSString*)getLabel
{
  if (label) return label;
  
  /*get a formwat that results in just the full month name"*/
  NSDateFormatter*formatter = [[[NSDateFormatter alloc] init] autorelease];
  insist (formatter);
  [formatter setDateFormat:@"MMMM"];
  
  /*save the label*/
  label =   [[formatter stringForObjectValue:date] retain];
  insist (label);
  
  return label;
}

/*if the receiver is in a more recent month than aDate's month return NSOrderedDescending*/
-(NSComparisonResult) compare:(NSDate*)aDate
{
  insist (aDate && self && date);
  NSCalendar*calendar = [NSCalendar currentCalendar];
  insist (calendar);
  
  NSDateComponents*c1 = [calendar components:NSMonthCalendarUnit fromDate:date];
  NSDateComponents*c2 = [calendar components:NSMonthCalendarUnit fromDate:aDate];
  insist (c1 && c2);
  if (c1.month > c2.month)
    return NSOrderedDescending;
  if (c1.month < c2.month)
    return NSOrderedAscending;
  return NSOrderedSame;
}

@end

@implementation Year

-(id) initWithDate:(NSDate*)aDate
{
  insist (aDate);
  
  self = [super init];
  insist (self);
  months = [[NSMutableArray alloc] init];
  insist (months);
  
  date = [aDate retain];
  insist (date);
  label = nil;
  
  return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
  self = [super init];
  insist (self);
  months = [[coder decodeObjectForKey:@"months"] retain];
  insist (months);
  date = [[coder decodeObjectForKey:@"date"] retain];
  insist (date);

  /*get a formwat that results in just the full year"*/
  NSDateFormatter*formatter = [[[NSDateFormatter alloc] init] autorelease];
  insist (formatter);
  [formatter setDateFormat:@"yyyy"];
  
  /*save the label*/
  label =   [[formatter stringForObjectValue:date] retain];
  insist (label);
  
  insist (label);
  return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
  insist (self && coder);
  [coder encodeObject:months forKey:@"months"];
  [coder encodeObject:date forKey:@"date"];
}

-(void) dealloc
{
  [months release];
  [label release];
  [date release];
  [super dealloc];
}

-(NSString*)getLabel
{
  if (label) return label;
  
  /*get a formwat that results in just the full year"*/
  NSDateFormatter*formatter = [[[NSDateFormatter alloc] init] autorelease];
  insist (formatter);
  [formatter setDateFormat:@"yyyy"];
  
  /*save the label*/
  label =   [[formatter stringForObjectValue:date] retain];
  insist (label);
  return label;
}

/*if the receiver is in a more recent year than aDate's year return NSOrderedDescending*/
-(NSComparisonResult) compare:(NSDate*)aDate
{
  insist (aDate && self && date);
  NSCalendar*calendar = [NSCalendar currentCalendar];
  insist (calendar);
  
  NSDateComponents*c1 = [calendar components:NSYearCalendarUnit fromDate:date];
  NSDateComponents*c2 = [calendar components:NSYearCalendarUnit fromDate:aDate];
  insist (c1 && c2);
  if (c1.year > c2.year)
    return NSOrderedDescending;
  if (c1.year < c2.year)
    return NSOrderedAscending;
  return NSOrderedSame;
}

-(void)add:(Month*)month
{
  insist (self && months && month);
  [months addObject:month];
}

-(int)getNumMonths
{
  insist (self && months);
  return [months count];
}

-(Month*)getMonth:(int)i;
{
  insist (self && months);
  insist (i >= 0 && i < [months count]);
  return [months objectAtIndex:i];
}

-(Month*)getLastMonth
{
  insist (self && months);
  return [months lastObject];
}


@end



@implementation Blog

+(NSString*)archivePath:(NSString*)blogPath
{
  insist (blogPath);
  return [NSString stringWithFormat:BLOG_FMT, blogPath];
}

/*load an existing blog from disk. do not open the text file.*/

-(id)initWithCoder:(NSCoder*)coder
{
  insist (coder);
  self = [super init];
  insist (self);
  
  entries = [[coder decodeObjectForKey:@"entries"] retain];
  latestDate = [[coder decodeObjectForKey:@"latestDate"] retain];
  home =  [[coder decodeObjectForKey:@"home"] retain];
  title =  [[coder decodeObjectForKey:@"title"] retain];
  subtitle =  [[coder decodeObjectForKey:@"subtitle"] retain];
  blogID =  [[coder decodeObjectForKey:@"blogID"] retain];
  years = [[coder decodeObjectForKey:@"years"] retain];
  position = (unsigned) [coder decodeIntForKey:@"position"];
  blogUrl = [[coder decodeObjectForKey:@"blogUrl"] retain];

  insist (years);

  tags = [[coder decodeObjectForKey:@"tags"] retain];
  insist (tags);
  
  /*we just always have this around for updates, it's never stored to disk*/
  tempTags = [[NSMutableSet alloc] init];
  insist (tempTags);
  tempEntries = [[NSMutableArray alloc] init];
  insist (tempEntries);
  
  urls = [[NSMutableArray alloc]init];
  insist (urls);
  
  textFileHandle = nil;
  dirty = NO;
  
  return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
  insist (self && coder);

  [coder encodeObject:entries forKey:@"entries"];
  [coder encodeObject:latestDate forKey:@"latestDate"];
  [coder encodeObject:home forKey:@"home"];
  [coder encodeObject:title forKey:@"title"];
  [coder encodeObject:subtitle forKey:@"subtitle"];
  [coder encodeObject:blogID forKey:@"blogID"];
  [coder encodeObject:years forKey:@"years"];
  [coder encodeInt:(int)position forKey:@"position"];
  [coder encodeObject:tags forKey:@"tags"];
  [coder encodeObject:blogUrl forKey:@"blogUrl"];
  
}

-(BOOL)sync
{
  insist (self && home && [home length]);

  if (dirty)
    dirty = ![NSKeyedArchiver archiveRootObject:self toFile:[Blog archivePath:home]];
  return !dirty;
}

/*make a new blog, it doesn't exist on disk yet (but an empty directory will be made for it, this
  directory won't represent a valid blog until the blog is synced*/

-(id)initWithBlogID:(NSString*)aBlogID path:(NSString*)aPath;
{
  insist (aBlogID);
  self = [super init];
  insist (self);
  
  blogID = [aBlogID retain];

  /*make a default date of jan 1 1991, this is before any blogs were around*/
  latestDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:-10*SECONDS_PER_YEAR];
  insist (latestDate);
  
  home = [aPath retain];

  textFileHandle = fetchFileHandle = nil;
  dirty = YES;
  
  /*make sure the directory exists*/
  BOOL b = [[NSFileManager defaultManager] createDirectoryAtPath:home
                                     withIntermediateDirectories:YES
                                                      attributes:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePosixPermissions, [NSNumber numberWithInt:0x777], nil]
                                                           error:nil];
  insist (b);
  
  /*make entries array, also the temp array for updating*/
  entries = [[NSMutableArray alloc] init];
  tempEntries = [[NSMutableArray alloc] init];
  
  insist (entries && tempEntries);
  
  tempFileHandle = nil;
  
  /*default empty title and subtitle, the title at least is going to be set for real by the parser*/
  title = [@"" retain];
  subtitle = [@"" retain];
  blogUrl = [@"" retain];
  
  /*make an empty years array*/
  years = [[NSMutableArray alloc] init];
  insist (years);
  
  /*we just always have this around for updates*/
  tempTags = [[NSMutableSet alloc] init];
  insist (tempTags);
  
  /*this is used for blogs that just export summaries*/
  urls = [[NSMutableArray alloc]init];
  insist (urls);
  
  /*and a new empty tags object*/
  tags = [[Tags alloc] init];
  insist (tags);
  position = 0;

  
  return self;
}

-(void)dealloc
{
  [textFileHandle release];
  [tempFileHandle release];
  [fetchFileHandle release];
  [tempEntries release];
  [blogID release];
  [tempTags release];
  [urls release];
  [latestDate release];
  [home release];
  [entries release];
  [title release];
  [subtitle release];
  [years release];
  [tags release];
  [blogUrl release];
  [super dealloc];
}


-(NSString*)getPath
{
  return home;
}

-(NSString*)getTitle
{
  return title;
}

-(void)setTitle:(NSString*)aTitle
{
  [title release];
  title = [aTitle retain];
}
-(NSString*)getSubtitle
{
  return subtitle;
}

-(void)setSubtitle:(NSString*)aSubtitle
{
  [subtitle release];
  subtitle = [aSubtitle retain];
}

-(NSDate*)getLatestDate
{
  return latestDate;
}

-(NSString*)getBlogID
{
  return blogID;
}

/*get rid of temporary objects. this is called after updating ends.*/
-(void)clearTempData
{
  [tempEntries removeAllObjects];
  [tempTags removeAllObjects];
  [urls removeAllObjects];
}


/*make a file, setting to one of our member variables passed by references*/
- (BOOL) readyTempFile:(NSFileHandle**)fileHandle path:(NSString*)path
{
  insist (self && fileHandle && path);

  /*make sure the file is closed*/
  if (*fileHandle)
  {
    [*fileHandle closeFile];
    [*fileHandle release];
    *fileHandle = nil;
  }

  BOOL r = [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePosixPermissions, [NSNumber numberWithInt:0x777], nil]];
  if (!r)
    return NO;

  *fileHandle = [[NSFileHandle fileHandleForUpdatingAtPath:path] retain];
  if (!*fileHandle)
    return NO;

  /*make sure the file is empty*/
  [*fileHandle truncateFileAtOffset:0];
  [*fileHandle seekToEndOfFile];
  return YES;
}

/*these are called between between beginUpdate and endUpdate to prepare the blog
  for dowloads page by page*/

/*just make sure we have a fresh fetchFileHandle to write to*/
-(void)beginFetchUpdate
{
  insist (urls && [urls count] && [urls count] == [tempEntries count]);
  BOOL r = [self readyTempFile:&fetchFileHandle path:[NSString stringWithFormat:@"%@/fetch", home]];
  insist (r && fetchFileHandle);  
  
  /*this is to keep track of which entry we'll be modifying when updateFetch is called
    for each tempEntry*/
  numFetched = 0;
}

/*this is called in order for every entry in the tempEntries array, text
  is the full entry content, we write this to the fetchFile and change
  the entry values to point to offsets in this file instead of the temp file*/

-(void)updateFetch:(NSString*)text
{
  insist (self && fetchFileHandle && tempEntries);
  insist (entries && urls);
  insist (numFetched >= 0 && numFetched < [tempEntries count]);
  
  NSData*data = [text dataUsingEncoding:NSUTF8StringEncoding];
 
  insist (data);
  
  /*the order of these next calls is so we have a valid offsets for the text here*/
  [fetchFileHandle seekToEndOfFile];
  Entry*entry = [tempEntries objectAtIndex:numFetched];
  insist (entry);
  entry->offset = [fetchFileHandle offsetInFile];
  entry->length = [data length];

  /*keep track of the unicode gap*/
  insist (entry->length >= [text length]);
  entry->gap = entry->length - [text length];
  
  [fetchFileHandle writeData:data];
  
  numFetched++;
}

/*this is so the blogFetcher can format an entry with a date and a title.*/
-(void)getNextFetchDate:(NSDate**)date title:(NSString**)aTitle
{
  insist (date && aTitle);
  insist (numFetched >= 0 && numFetched < [tempEntries count]);
  Entry*entry = [tempEntries objectAtIndex:numFetched];
  insist (entry);
  *date = entry->date;
  *aTitle = entry->title;
}

/*the fetchFile now contains all the text and the tempEntries have already been updated to
  point to positions there. just replace the tempFile with the fetchFile.*/
-(void)endFetchUpdate
{
  insist (tempFileHandle && fetchFileHandle && urls);

  /*first close the files*/
  [tempFileHandle release]; tempFileHandle = nil;
  [fetchFileHandle release]; fetchFileHandle = nil;
  
  NSString*tempPath = [NSString stringWithFormat:@"%@/temp", home];
  NSString*fetchPath = [NSString stringWithFormat:@"%@/fetch", home];

  /*remove the temp file*/
  BOOL r = [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
  insist (r);
  
  /*rename the fetch file the temp file*/
  r = [[NSFileManager defaultManager] moveItemAtPath:fetchPath toPath:tempPath error:nil];
  insist (r);
  
  /*open the new temp file*/
  tempFileHandle = [[NSFileHandle fileHandleForUpdatingAtPath:tempPath] retain];
  insist (tempFileHandle);
  
  /*don't need this anymore*/
  [urls removeAllObjects];
}


/*called when fetch updating fails, to empty the fetchFile*/
-(void) failFetchUpdate
{
  /*empty the fetch file, no need to delete it*/
  [fetchFileHandle truncateFileAtOffset:0];
  [fetchFileHandle closeFile];
  [fetchFileHandle release];
  fetchFileHandle = nil;  
}

/*set up a series of updateText calls by creating a temp file and a temp entries array*/
-(void)beginUpdate
{
  insist (self && tempEntries);
  insist (tempTags && urls);
  
  /*empty tempTags, tempEntries etc arrays.*/
  [self clearTempData];
  
  /*get the temp file ready*/
  BOOL r = [self readyTempFile:&tempFileHandle path:[NSString stringWithFormat:@"%@/temp", home]];
  insist (r && tempFileHandle);

  /*this keeps track of the first position in an update, so when we do
    refresh we can tell where to skip to.*/
  updatePosition = 0;
}

/*write an entry to the end of the temp file and keep track of where it is in the temp entries array.
  if this is a summary only blog then url is non-nil and will be added to the urls array for use
  in a the second phase of actually fetching the blog content.*/
-(void)updateText:(NSString*)text date:(NSDate*)date title:(NSString*)aTitle url:(NSString*)url
{
  insist (self && tempFileHandle && tempEntries && text && date);
  insist (entries && urls);
  
  dirty = YES;
  
  NSData*data = [text dataUsingEncoding:NSUTF8StringEncoding];
  insist (data);

  /*the order of these next 3 calls is so we have a valid offset in the entries array for the text here*/
  [tempFileHandle seekToEndOfFile];
  Entry*entry = [[Entry alloc] initWithOffset:[tempFileHandle offsetInFile] length:[data length] date:date title:aTitle];
  [tempEntries addObject:entry];
  [tempFileHandle writeData:data];
  [entry release];
  
  /*keep track of the unicode gap*/
  insist (entry->length >= [text length]);
  entry->gap = entry->length - [text length];
  
  if (url)
    [urls addObject:url];
}


/*add a tag to the tempTags set for the latest entry added to the tempEntries array*/
-(void)updateTagForLastText:(NSString*)word
{
  insist (self && word && tempTags);
  Tag*match;
  insist ([tempEntries count]);
  
  /*make a tag from the word*/
  Tag*tag = [[[Tag alloc] initWithWord:word] autorelease];
  insist (tag);
  
  /*if the tag exists just add the new entry number to it*/
  if ((match = [tempTags member:tag]))
    [match addEntry:[tempEntries count]-1];
  else
  {
    /*otherwise add the tag and add the entry number for the tag*/
    [tempTags addObject:tag];
    [tag addEntry:[tempEntries count]-1];
  }
}

/*called when updating fails, to free up the temp resources*/
-(void) failUpdate
{
  /*empty the temp file, no need to delete it*/
  [tempFileHandle truncateFileAtOffset:0];
  [tempFileHandle closeFile];
  [tempFileHandle release];
  tempFileHandle = nil;  
  
  /*empty the temp arrays*/
  [self clearTempData];
}

/*write the temp entries/text to the end of the entries array and the text file in reverse order
  because the google api returns shit in reverse chronological order.
  also update the entries array and the years array. also add all the new tags to our tags object.*/

-(void)endUpdate
{
  insist (self && textFileHandle && tempFileHandle && tempEntries);
  
  /*make sure we are at the end of the file we are going to append to*/
  [textFileHandle seekToEndOfFile];
  
  /*go through the temp entries in reverse order, writing their data out*/

  /*get the last year in our list of years, and the last month in that year. these can
    both be nil if we are updating an empty blog*/
  
  Year*lastYear = [years lastObject];
  Month*lastMonth = lastYear ? [lastYear getLastMonth] : nil;
  int numNewEntries = [tempEntries count];
  int numOldEntries = [entries count];

#if 0
  to debug refresh
  if (numOldEntries == 0)
  {
    [tempEntries removeObjectAtIndex:0];
    numNewEntries--;
  }
#endif
  
  for (int i = numNewEntries - 1; i >= 0; i--)
  {
    /*awkward but we have to make sure autorelease data objects don't stack up in this
    loop, because they can be taking up large chunks of memeory.*/
    
    NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
    
    Entry*entry = [tempEntries objectAtIndex:i];
    insist (entry);

    /*get the chunk of data*/
    [tempFileHandle seekToFileOffset:[entry getOffset]];
    NSData*data = [tempFileHandle readDataOfLength:[entry getLength]];
    insist (data);
    
    /*we have to make a new entry because the offset will be different in the regular file*/
    NSDate*date = [entry getDate];
    Entry*newEntry = [[Entry alloc] initWithOffset:[textFileHandle offsetInFile] length:[entry getLength] date:date title:[entry getTitle]];
    newEntry->gap = entry->gap;
    [entries addObject:newEntry];
    [newEntry release];
    
    /*if the date is for a new month, add it to our month/year */
    BOOL firstEver = NO;
     
    /*just handle special case of this being the first blog entry ever*/
    if (!lastMonth)
    {
      insist (!numOldEntries);
      insist (!lastYear);
      firstEver = YES;
      lastYear = [[[Year alloc] initWithDate:date] autorelease];
      insist (lastYear);
      lastMonth = [[[Month alloc] initWithDate:date] autorelease];
      insist (lastMonth);
      [lastYear add:lastMonth];
      [years addObject:lastYear];
      lastMonth->firstEntry = numOldEntries + (numNewEntries - 1 - i);
      lastMonth->numEntries = 1;
    }
    else
    {
      insist (lastYear && lastMonth);
      NSComparisonResult cYear = [lastYear compare:date];
      NSComparisonResult cMonth = [lastMonth compare:date];
      insist (cYear != NSOrderedDescending);
      
      if (cYear == NSOrderedAscending || cMonth == NSOrderedAscending)
      {
        /*we increase the month, either by increasing the year or increasing the month in the same year*/
        
        /*later on we can relax these assertions, which depend on google not being fucked up*/
        insist (cMonth != NSOrderedDescending || cYear == NSOrderedAscending);
        
        if (cYear == NSOrderedAscending)
        {
          /*new year*/
          lastYear = [[[Year alloc] initWithDate:date] autorelease];
          insist (lastYear);
          [years addObject:lastYear];
        }
        
        /*new month*/
        lastMonth = [[[Month alloc] initWithDate:date] autorelease];
        insist (lastMonth);
        [lastYear add:lastMonth];
        lastMonth->firstEntry = numOldEntries + (numNewEntries - 1 - i);
        lastMonth->numEntries = 1;
      }
      else
        lastMonth->numEntries++;
    }
    
    /*write the data*/
    
    /*but if this is the first entry ever, add a preface saying what the blog title and URL are.*/
    if (firstEver)
    {
      /*remember where the start is so we can recompute the length*/
      unsigned offset = [textFileHandle offsetInFile];
      
      /*get the data back into a string, all of these variables were set up above where the month/year crap is*/
      NSString*s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
      
      /*now make the new entry. take care to make empty strings if they don't exist*/
      NSString*aTitle = title ? title : @"";
      NSString*aBlogUrl = blogUrl ? blogUrl : @"";
      
      NSString*newText;
      if (subtitle && [subtitle length])
        newText = [NSString stringWithFormat:@"%@%C%@%C%@%C%C%C%C%@", aTitle, FAKE_BR_CHAR, subtitle, FAKE_BR_CHAR, aBlogUrl, FAKE_BR_CHAR, FAKE_BR_CHAR, FAKE_BR_CHAR,FAKE_BR_CHAR, s];
      else
        newText = newText = [NSString stringWithFormat:@"%@%C%@%C%C%C%C%@", aTitle, FAKE_BR_CHAR, aBlogUrl, FAKE_BR_CHAR, FAKE_BR_CHAR, FAKE_BR_CHAR, FAKE_BR_CHAR, s];

      insist (newText);
      NSData*newData = [newText dataUsingEncoding:NSUTF8StringEncoding];
      insist (newData);
      
      [textFileHandle writeData:newData];
      
      /*correct the entry*/
      newEntry->length = [textFileHandle offsetInFile] - offset;
 
    }
    else
      [textFileHandle writeData:data];
    
    [pool release];
  }
   
  if (numNewEntries)
  {
    /*keep track of the start of the update text*/
    Entry*entry = [entries objectAtIndex:numOldEntries];
    insist (entry);
    updatePosition = entry->offset;
  }
  /*if there were any new entries then the first one should be the new latest date*/
  if ([tempEntries count])
  {
    NSDate*date = [[tempEntries objectAtIndex:0] getDate];
    insist (date);
    
    /*sanity checks*/
    NSComparisonResult r = [latestDate compare:date];
    insist (r != NSOrderedDescending);
    insist (lastYear && lastMonth && [lastMonth compare:date] == NSOrderedSame && [lastYear compare:date] == NSOrderedSame);
    
    [latestDate release];
    latestDate = [date retain];
    
    /*also here we notice that shit did change, so if we are ever asked to sync we will do the right thing*/
    dirty = YES;
  }
  
  /*empty the temp file. no need to actually delete the damn thing, we are going to use it every time we update.
    rather than using a global temp file for this we reserve one per blog, in case we ever wanted to do this
    shit multithreaded. the iphone flash doesn't care.
  */
  [tempFileHandle truncateFileAtOffset:0];
  [tempFileHandle closeFile];
  [tempFileHandle release];
  tempFileHandle = nil;  
  
  /*now go and correct every entry number in the tempTags, since they were reversed and they also need to be offset*/
  NSEnumerator*enumerator = [tempTags objectEnumerator];
  insist (enumerator);
  Tag*tag;
  while ((tag = [enumerator nextObject]))
  {
    for (int j = 0; j < [tag->entries count]; j++)
    {
      NSNumber*n = [tag->entries objectAtIndex:j];
      int intValue = [n intValue];
#if 0
      to debug refresh
      if (intValue == numNewEntries)continue;//debug
#endif
      insist (intValue >= 0 && intValue < numNewEntries);
      
      NSNumber*nn = [NSNumber numberWithInt:numNewEntries - 1 - intValue + numOldEntries];
      [tag->entries replaceObjectAtIndex:j withObject:nn];
    }
  }

  /*finally add the tempTags to the permament tags object*/
  insist (![tempTags count] || dirty);
  [tags addTags:tempTags];

  [self clearTempData];
}

-(int)getNumYears
{
  insist (self && years);
  return [years count];
}

-(Year*)getYear:(int)i
{
  insist (self && years && i >= 0 && i < [years count]);
  return [years objectAtIndex:i];
}

-(Month*)getMonth:(int)month inYear:(int)year
{
  insist (self && years);
  insist (year >= 0 && year < [years count]);
  
  Year*y = [years objectAtIndex:year];
  insist (y && month >= 0 && month < [y getNumMonths]);
  return [y getMonth:month];
}

-(void)open
{
  if (textFileHandle) return;
  
  insist (home);
  NSString*textPath = [NSString stringWithFormat:@"%@/text", home];
  insist (textPath);
  
  /*if we can't open the file create if first. lame semantics*/
  if (!(textFileHandle = [[NSFileHandle fileHandleForUpdatingAtPath:textPath] retain]))
  {
    BOOL r = [[NSFileManager defaultManager] createFileAtPath:textPath contents:[[[NSData alloc] init] autorelease] attributes:[NSDictionary dictionaryWithObjectsAndKeys:NSFilePosixPermissions, [NSNumber numberWithInt:0x777], nil]];
    insist (r);
    textFileHandle = [[NSFileHandle fileHandleForUpdatingAtPath:textPath] retain];
  }

  insist (textFileHandle);
}

-(NSString*)getTextAtPosition:(unsigned)aPosition length:(unsigned)length
{
  /*get the chunk of data*/
  [textFileHandle seekToFileOffset:aPosition];
  NSData*data = [textFileHandle readDataOfLength:length];
  insist (data);
  return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

/*we don't need locks around this or any of the fetch calls because the
  fetchers all serialize by calling their delegate methods on the main thread*/

-(NSString*)getFetchSummary:(int)index
{
  insist (self && tempFileHandle);
  insist (index >= 0 && index < [tempEntries count]);

  Entry*entry = [tempEntries objectAtIndex:index];
  insist (entry);
  
  [tempFileHandle seekToFileOffset:[entry getOffset]];
  NSData*data = [tempFileHandle readDataOfLength:[entry getLength]];
  insist (data);
  return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}
  

-(void) close
{
  if (textFileHandle)
  {
    [textFileHandle closeFile];
    [textFileHandle release];
    textFileHandle = nil;
  }

  /*just in case do this, it's normally done in endUpdate*/
  if (tempFileHandle)
  {
    [tempFileHandle closeFile];
    [tempFileHandle release];
    tempFileHandle = nil;
  }
}

-(unsigned)getPosition
{
  return position;
}
-(void)setPosition:(unsigned)aPosition
{
  Entry*entry = [entries lastObject];
  insist (aPosition < entry->offset + entry->length);
  position = aPosition;
  dirty = YES;
}

/*search through the years/months lists and find which month the current position falls in*/
-(Month*)getMonthAtPosition:(unsigned)aPosition
{
  NSIndexPath*indexPath = [self getIndexPathForMonthAtPosition:aPosition];

  Year*year = [years objectAtIndex:[indexPath section]];
  insist (year);
  return [year getMonth:[indexPath row]];
}

-(NSIndexPath*)getIndexPathForMonthAtPosition:(unsigned)aPosition
{
  insist (self && years && entries);
  
  for (int i = 0; i < [years count]; i++)
  {
    Year*year = [years objectAtIndex:i];
    insist (year);
    
    /*first see if the position is in this year*/
    
    /*these can be the same if there's just one month in the year. that's fine*/
    Month*firstMonth = [year getMonth:0];
    Month*lastMonth = [year getLastMonth];
    insist (firstMonth && lastMonth);
    
    Entry*firstEntry = [entries objectAtIndex:firstMonth->firstEntry];
    Entry*lastEntry = [entries objectAtIndex:lastMonth->firstEntry + lastMonth->numEntries - 1];
    insist (firstEntry && lastEntry);
    
    unsigned firstPosition = [firstEntry getOffset];
    unsigned lastPosition = [lastEntry getOffset] + [lastEntry getLength] - 1;
    
    if (aPosition >= firstPosition && aPosition <= lastPosition)
    {
      /*it is in this year. find out which month*/
      for (int j = 0; j < [year getNumMonths]; j++)
      {
        Month*month = [year getMonth:j];
        insist (month);
        firstEntry = [entries objectAtIndex:month->firstEntry];
        lastEntry = [entries objectAtIndex:month->firstEntry + month->numEntries - 1];
        insist (firstEntry && lastEntry);
        
        firstPosition = [firstEntry getOffset];
        lastPosition = [lastEntry getOffset] + [lastEntry getLength] - 1;
        if (aPosition >= firstPosition && aPosition <= lastPosition)
        {
          NSUInteger buffer[2];
          buffer [0] = i;
          buffer [1] = j;
          return [NSIndexPath indexPathWithIndexes:buffer length:2];
        }
      }
    }
  }
  return nil;
}


-(int)getNumTags
{
  insist (self && tags && tags->tags);
  return [tags->tags count];
}

-(Tag*)getTag:(int)i
{
  insist (self && tags && tags->tags);
  insist (i >= 0 && i < [tags->tags count]);
  return [tags->tags objectAtIndex:i];
}


-(int)getNumEntries
{
  insist (self && entries);
  return [entries count];
}
-(Entry*)getEntry:(int)i
{
  insist (self && i >=0 && i < [entries count]);
  return [entries objectAtIndex:i];
}

-(BOOL)hasUrls
{
  insist (urls);
  return [urls count] > 0;
}
-(NSArray*)getUrls
{
  return urls;
}
- (unsigned)getUpdatePosition
{
  return updatePosition;
}

-(NSString*)getBlogUrl
{
  return blogUrl;
}
-(void)setBlogUrl:(NSString*)url
{
  [blogUrl release];
  blogUrl = [url retain];
}
@end
