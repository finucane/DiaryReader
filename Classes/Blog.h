//
//  Blog.h
//  diaryreader
//
//  Created by finucane on 1/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tags.h"

/*this keeps track of where an entry is in the data file*/
@interface Entry : NSObject
{
@public
  unsigned offset;
  unsigned length;
  unsigned gap;
  NSDate*date;
  NSString*title;
};


- (id)initWithOffset:(unsigned) anOffset length:(unsigned) aLength date:(NSDate*)aDate title:(NSString*)aTitle;
- (unsigned) getOffset;
- (unsigned) getLength;
- (NSDate*)getDate;
- (NSString*)getTitle;

@end

@interface Month: NSObject
{
  NSDate*date;
  NSString*label;
@public
  unsigned firstEntry;
  unsigned numEntries;
}
-(id)initWithDate:(NSDate*)date;
-(NSString*)getLabel;
-(NSComparisonResult) compare:(NSDate*)aDate;

@end

@interface Year: NSObject
{
  NSDate*date;
  NSString*label;
  NSMutableArray*months;
}
-(id)initWithDate:(NSDate*)date;
-(void)add:(Month*)month;
-(int)getNumMonths;
-(Month*)getMonth:(int)i;
-(Month*)getLastMonth;
-(NSString*)getLabel;
-(NSComparisonResult) compare:(NSDate*)aDate;

@end

@interface Blog : NSObject
{ 
  NSString*home;
  NSString*blogID;
  NSString*title;
  NSString*subtitle;
  NSString*blogUrl;
  NSFileHandle*textFileHandle;
  NSFileHandle*tempFileHandle;
  NSFileHandle*fetchFileHandle;
  int numFetched;
  NSMutableSet*tempTags;
  NSMutableArray*entries;
  NSMutableArray*tempEntries;
  NSMutableArray*urls;
  NSMutableArray*years;
  NSDate*latestDate;
  Tags*tags;
  BOOL dirty;
  unsigned position;
  unsigned updatePosition;
}

+(NSString*)archivePath:(NSString*)blogPath;

-(id)initWithBlogID:(NSString*)aBlogID path:(NSString*)aPath;
-(NSDate*)getLatestDate;
-(NSString*)getBlogID;
-(NSString*)getPath;
-(NSString*)getTitle;
-(NSString*)getSubtitle;
-(void)setTitle:(NSString*)aTitle;
-(void)setSubtitle:(NSString*)aSubtitle;
-(void)beginUpdate;
-(void)beginFetchUpdate;
-(void)endFetchUpdate;
-(void)updateText:(NSString*)text date:(NSDate*)date title:(NSString*)title url:(NSString*)url;
-(void)updateTagForLastText:(NSString*)word;
-(void)endUpdate;
-(void)failUpdate;
-(void)open;
-(void)close;
-(BOOL)sync;
-(void)encodeWithCoder:(NSCoder*)code;
-(int)getNumYears;
-(unsigned)getPosition;
-(void)setPosition:(unsigned)position;
-(Year*)getYear:(int)i;
-(Month*)getMonth:(int)month inYear:(int)year;
-(Month*)getMonthAtPosition:(unsigned)aPosition;
-(NSIndexPath*)getIndexPathForMonthAtPosition:(unsigned)aPosition;
-(int)getNumTags;
-(Tag*)getTag:(int)i;
-(int)getNumEntries;
-(Entry*)getEntry:(int)i;
-(NSString*)getTextAtPosition:(unsigned)position length:(unsigned)length;
-(void)beginFetchUpdate;
-(void)updateFetch:(NSString*)text;
-(void)getNextFetchDate:(NSDate**)date title:(NSString**)title;
-(void)endFetchUpdate;
-(void)failFetchUpdate;
-(NSString*)getFetchSummary:(int)index;
-(BOOL)hasUrls;
-(NSArray*)getUrls;
- (unsigned)getUpdatePosition;
-(NSString*)getBlogUrl;
-(void)setBlogUrl:(NSString*)url;

@end
