//
//  Tags.m
//  diaryreader
//
//  Created by David Finucane on 1/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Tags.h"
#import "insist.h"

@implementation Tag

-(id) initWithWord:(NSString*)aWord
{
  self = [super init];
  insist (aWord);
  word = [aWord retain];
  entries = [[NSMutableArray alloc] init];
  insist (entries);
  return self;
}
-(id)initWithCoder:(NSCoder*)coder
{
  insist (coder);
  self = [super init];
  insist (self);
  word = [[coder decodeObjectForKey:@"word"] retain];
  entries = [[coder decodeObjectForKey:@"entries"] retain];
  return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
  insist (coder);

  [coder encodeObject:word forKey:@"word"];
  [coder encodeObject:entries forKey:@"entries"];
}

-(void)dealloc
{
  [word release];
  [entries release];
  [super dealloc];
}
 
/*find where an entry number is for this tag, if one, otherwise where it should go*/
-(int)find:(NSNumber*)entry matched:(BOOL*)matched
{
  insist (self && entry && matched);
  int a = 0;
  int b = [entries count] -1;
  
  *matched = NO;
  
  while (a <= b)
  {
    int c = (a + b) / 2;

    insist (c >= 0 && c < [entries count]);
    NSNumber*n = [entries objectAtIndex:c];
    NSComparisonResult r = [n compare:entry];
    if (r == NSOrderedDescending)
      b = c-1;
    else if (r == NSOrderedAscending)
      a = c+1;
    else
    {
      *matched = YES;
      return c;
    }
  }
  return a;
}

/*add an entry if it doesn't already exist*/
-(void)addEntry:(int)entry
{
  NSNumber*n = [NSNumber numberWithInt:entry];
  insist (n);
  
  /*find if/where it is in our entries array*/
  BOOL matched;
  [self find:n matched:&matched];
  
  /*if it's unique, insert it at the start of the list, because blogs are backwards chronologically*/
  if (!matched)
    [entries insertObject:n atIndex:0];
}

/*add otherTags's unique entries to self*/
-(void)addEntries:(Tag*)otherTag
{
  insist ([word isEqualToString:otherTag->word]);
  
  /*go throughe each of the other tag's entries*/
  for (int i = 0; i < [otherTag->entries count]; i++)
  {
    /*find if/where it is in our entries array*/
    BOOL matched;
    NSNumber*n = [entries objectAtIndex:i];
    insist (n);
    int i = [self find:n matched:&matched];
    
    /*if it's unique, insert it*/
    if (!matched)
      [entries insertObject:n atIndex:i];
  }
}

- (BOOL)isEqual:(id)anObject
{
  return [word isEqualToString:((Tag*)anObject)->word];
}

-(NSUInteger)hash
{
  return [word hash];
}

@end
  
@implementation Tags
  
- (id) init
{
  self = [super init];
  tags = [[NSMutableArray alloc] init];
  insist (tags);
  return self;
}

-(id)initWithCoder:(NSCoder*)coder
{
  insist (coder);
  self = [super init];
  insist (self);
  tags = [[coder decodeObjectForKey:@"tags"] retain];
  return self;
}

-(void)encodeWithCoder:(NSCoder*)coder
{
  insist (coder);
  [coder encodeObject:tags forKey:@"tags"];
}

-(void)dealloc
{
  [tags release];
  [super dealloc];
}

/*use a binary search to find position where word exists or, if it doesn't exist, where it should go*/
-(int) find:(NSString*)word matched:(BOOL*)matched
{
  insist (self && word );
  
  int a = 0;
  int b = [tags count] - 1;
  
  *matched = NO;
  
  while (a <= b)
  {
    int c = (a + b) / 2;
    insist (c >= 0 && c < [tags count]);
    Tag*tag = [tags objectAtIndex:c];
    NSComparisonResult r = [tag->word compare:word];
    if (r == NSOrderedDescending)
      b = c-1;
    else if (r == NSOrderedAscending)
      a = c+1;
    else
    {
      *matched = YES;
      return c;
    }
  }
  return a;
}

/*go through each item in someTags and add them to our tags array, either by merging entries from existing tags, or
  by adding entire new tags*/

-(void)addTags:(NSSet*)someTags
{
  insist (self && someTags);
  NSEnumerator*enumerator = [someTags objectEnumerator];
  insist (enumerator);
  Tag*tag;
  
  while ((tag = [enumerator nextObject]))
  {
    BOOL matched;
    int i = [self find:tag->word matched:&matched];
    if (matched)
    {
      /*the tag's word already exists*/
      insist (i >= 0 && i < [tags count]);
      /*take entries off the tag and add them to the existing tag's entries*/
      Tag*myTag = [tags objectAtIndex:i];
      insist (myTag && [myTag->word isEqualToString:tag->word]);
      [myTag addEntries:tag];
    }
    else
    {
      /*it is a new word, add the tag*/
      [tags insertObject:tag atIndex:i];
    }
  }
}

    
@end
