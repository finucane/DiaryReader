//
//  StringCategory.m
//  4TrakStudio
//
//  Created by David Finucane on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "StringCategory.h"
#import "insist.h"

@implementation  NSString (StringCategory)


- (NSString *) flattenHTML
{
  NSMutableString*s = [NSMutableString stringWithCapacity:[self length]];
  insist (s);
  
  int numChars = [self length];
  BOOL inTag = NO;
  BOOL inEscape = NO;
  
  for (int i = 0; i < numChars; i++)
  {
    unichar c = [self characterAtIndex:i];
    
    if (c == '<')
      inTag = YES;
    else if(c == '>')
      inTag = NO;
    else if (!inTag && c == '&')
      inEscape = YES;
    else if (!inTag && inEscape && c == ';')
      inEscape = NO;
    else if (!inTag && !inEscape)
      [s appendFormat:@"%C", c];
  }
  
	return s;
}

- (NSString *) removeTags
{
  NSMutableString*s = [NSMutableString stringWithCapacity:[self length]];
  insist (s);
  
  int numChars = [self length];
  BOOL inTag = NO;
  
  for (int i = 0; i < numChars; i++)
  {
    unichar c = [self characterAtIndex:i];
    
    if (c == '<')
      inTag = YES;
    else if(c == '>')
      inTag = NO;
    else if (!inTag)
      [s appendFormat:@"%C", c];
  }
  
	return s;
}

- (NSString *) removeTagsOfType:(NSString*)type
{
  type = [type lowercaseString];
  NSString*other = [NSString stringWithFormat:@"/%@", type];
  insist (other);
  
  NSMutableString*s = [NSMutableString stringWithCapacity:[self length]];
  insist (s);
  
  int numChars = [self length];
  BOOL inTag = NO;
  
  for (int i = 0; i < numChars; i++)
  {
    unichar c = [self characterAtIndex:i];
    
    BOOL wasInTag = inTag;
    
    if (c == '<' && [self length] -i - 2 >= [type length])
    { 
      NSRange r = [self rangeOfString:type options:NSCaseInsensitiveSearch range:NSMakeRange (i+1, [type length])];
      if (r.location == i+1)
        inTag = YES;
      else
      {
        r = [self rangeOfString:other options:NSCaseInsensitiveSearch range:NSMakeRange (i+1, [other length])];
        if (r.location == i+1)
          inTag = YES;
      }
    }
    else if(c == '>')
      inTag = NO;
    if (!inTag && !wasInTag)
      [s appendFormat:@"%C", c];
  }
  
	return s;
}


/*return a string w/out any <tag>... </tag> where tag is of type type*/
- (NSString *) eradicateTag:(NSString*)type
{
  type = [type lowercaseString];
  
  /*make the telomeres*/
  NSString*startTag = [NSString stringWithFormat:@"<%@", type];
  NSString*endTag = [NSString stringWithFormat:@"</%@", type];
  
  
  /*make the string we will build up*/
  NSMutableString*s = [NSMutableString stringWithCapacity:[self length]];
  insist (s);
  
  /*this lets us do nested tags, so we can match up the end tags to their start tags*/
  int depth = 0;
  unsigned pos = 0;
  
  /*save cycles for the phone*/
  unsigned self_length = [self length];
  
  while (pos < self_length)
  {
    /*look for the next start or end tag*/

    NSRange r = NSMakeRange (pos, self_length - pos);
    NSRange sr = [self rangeOfString:startTag options:NSCaseInsensitiveSearch range:r];
    NSRange er = [self rangeOfString:endTag options:NSCaseInsensitiveSearch range:r];

    unsigned location;
    /*if there are no more tags at all, we're done.*/
    if (sr.location == NSNotFound && er.location == NSNotFound)
    {
      /*depth should be 0 if the html is ok. err on the side of not throwing
        information out -- so don't check*/
      [s appendString:[self substringWithRange:r]];
      return s;
    }
    
    /*get the location of the nearest tag*/
    if (sr.location != NSNotFound && er.location != NSNotFound)
      location = sr.location < er.location ? sr.location : er.location;
    else
      location = sr.location != NSNotFound ? sr.location : er.location;
    
    /*if we weren't in a tag pair save the text we just skipped over*/
    if (!depth)
      [s appendString:[self substringWithRange:NSMakeRange(pos, location - pos)]];
    
    /*see if it's an end tag or not*/
    BOOL endTag = [self characterAtIndex:location + 1] == '/';
    
    /*pop or push*/
    depth += endTag ? -1 : 1;
    
    /*advance past the tag*/
    r = [self rangeOfString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(location, self_length - location)];
    
    if (r.location == NSNotFound)
    {
      /*allow garbage*/
      return s;
    }
    pos = r.location + 1;
  }
	return s;
}



- (NSString *) replaceTagsOfType:(NSString*)type with:(NSString*)replacement
{
  insist (self && replacement);
  
  type = [type lowercaseString];
  NSString*other = [NSString stringWithFormat:@"/%@", type];
  insist (other);
  
  NSMutableString*s = [NSMutableString stringWithCapacity:[self length]];
  insist (s);
  
  int numChars = [self length];
  BOOL inTag = NO;
  
  for (int i = 0; i < numChars; i++)
  {
    unichar c = [self characterAtIndex:i];
    
    BOOL wasInTag = inTag;
    
    if (c == '<' && [self length] -i - 2 >= [type length])
    { 
      NSRange r = [self rangeOfString:type options:NSCaseInsensitiveSearch range:NSMakeRange (i+1, [type length])];
      if (r.location == i+1)
        inTag = YES;
      else
      {
        r = [self rangeOfString:other options:NSCaseInsensitiveSearch range:NSMakeRange (i+1, [other length])];
        if (r.location == i+1)
          inTag = YES;
      }
    }
    else if(c == '>')
      inTag = NO;
    if (!inTag && !wasInTag)
      [s appendFormat:@"%C", c];
    else if (!wasInTag && inTag)
      [s appendString:replacement];
  }
  
	return s;
}

- (NSString*)htmlSafe
{
  NSMutableString*s = [NSMutableString stringWithString:self];
  insist (s);
  
  /*order matters here because of the &*/
  [s replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0,[s length])];
  [s replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0,[s length])];
  [s replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0,[s length])];
  return s;
}


- (BOOL) grep:(NSString*)s
{
  NSRange r = [self rangeOfString:s];
  return r.location != NSNotFound;
}

- (BOOL) igrep:(NSString*)s
{
  NSRange r = [self rangeOfString:s options:NSCaseInsensitiveSearch];
  return r.location != NSNotFound;
}

- (BOOL) startsWith:(NSString*)s
{
  NSRange r = [self rangeOfString:s];
  return r.location == 0;
}

/*don't use this it just does the front*/
- (NSString*) stringByTrimmingString:(NSString*)s;
{
  NSMutableString*ms = [NSMutableString stringWithString:self];
  NSCharacterSet*whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  
  int changes;
  do
  {
    changes = 0;
    for (NSRange r = [ms rangeOfCharacterFromSet:whitespace]; !r.location; r = [ms rangeOfCharacterFromSet:whitespace], changes++)
      [ms deleteCharactersInRange:r];
    
    for (NSRange r = [ms rangeOfString:s options:NSCaseInsensitiveSearch]; !r.location; r = [ms rangeOfString:s options:NSCaseInsensitiveSearch], changes++)
      [ms deleteCharactersInRange:r];
    
  } while (changes);
  return ms;
}

- (NSString*) stringByRemovingCharactersInString:(NSString*)s
{
  NSMutableString*ms = [NSMutableString stringWithString:self];
  NSCharacterSet*set = [NSCharacterSet characterSetWithCharactersInString:s];
  
  for (NSRange r = [ms rangeOfCharacterFromSet:set]; r.length; r = [ms rangeOfCharacterFromSet:set])
    [ms deleteCharactersInRange:r];

  return ms;
}

- (NSString *) stringByReplacing:(unichar)original withChar:(unichar)replacement
{
  NSMutableString*s = [NSMutableString stringWithCapacity:[self length]];
  insist (s);
  
  for (int i = 0; i < [self length]; i++)
  {
    unichar c = [self characterAtIndex:i];
    [s appendFormat:@"%C", c == original ? replacement : c];
  }
	return s;
}

- (NSString*) stringByCollapsingWhitespaceAndRemovingNewlines
{
  insist (self);
  
  NSMutableString*ms = [NSMutableString stringWithCapacity:[self length]];
  NSCharacterSet*set = [NSCharacterSet whitespaceAndNewlineCharacterSet];

  unsigned len = 0;
  for (int i = 0; i < [self length]; i++)
  {
    unichar c = [self characterAtIndex:i];
    if ([set characterIsMember:c])
    {
      /*make the character into a space if it was separating words, otherwise drop it*/

      if (len && [ms characterAtIndex:len-1] != ' ')
      {
        [ms appendString:@" "];
        len++;
      }
    }
    else
    {
      [ms appendFormat:@"%C",c];
      len++;
    }
  }
	return ms;
}


- (NSString*) substringAfterString:(NSString*)s
{
  NSRange r = [self rangeOfString:s];
  if (r.location == NSNotFound || r.location == [self length] - 1)
    return nil;
  return [self substringFromIndex:r.location + [s length]];
}

- (NSString*) substringToString:(NSString*)s
{
  insist (s);
  NSRange r = [self rangeOfString:s];
  if (r.location == NSNotFound || r.location == [self length] - 1)
    return self;
  return [self substringToIndex:r.location];
}



- (NSArray*) componentsSeparatedByCharactersInString:(NSString*)s
{
  return [self componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:s]];
}


- (NSString*) stringWithoutRepeatedString:(NSString*)s options:(NSStringCompareOptions)mask
{
  insist (s);
  NSMutableString*ms = [NSMutableString stringWithString:self];
  NSString*pair = [NSString stringWithFormat:@"%@%@", s, s];
  insist (pair);
  
  for (;;)
  {
    NSRange r = [ms rangeOfString:pair options:mask];
    if (r.location == NSNotFound)
      break;
    /*only delete 1/2 of the string*/
    insist (r.length % 2 == 0);
    r.length /= 2;
    [ms deleteCharactersInRange:r];
  } 
  return ms;
}

- (NSArray*) nonEmptyComponentsSeparatedByString:(NSString*)s
{
  NSMutableArray*words = [NSMutableArray arrayWithArray:[self componentsSeparatedByString:s]];
  insist (words);
  
  /*remove empty strings*/
  for (int i = 0; i < [words count]; i++)
  {
    NSString*t = [[words objectAtIndex:i] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([t isEqualToString:@""])
    {
      [words removeObjectAtIndex: i];
      i--;
    }
  }
  return words;
}


- (NSArray*) nonEmptyComponentsSeparatedByCharactersInSet:(NSCharacterSet*)set
{
  NSMutableArray*words = [NSMutableArray arrayWithArray:[self componentsSeparatedByCharactersInSet:set]];
  insist (words);
  
  /*remove empty strings*/
  for (int i = 0; i < [words count]; i++)
  {
    NSString*t = [[words objectAtIndex:i] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([t isEqualToString:@""])
    {
      [words removeObjectAtIndex: i];
      i--;
    }
  }
  return words;
}

- (NSString*)stringBetweenTags:(NSString*)tag
{
  insist (self && tag && [tag length] && ![tag grep:@"<"] && ![tag grep:@">"]);
  
  /*find where the first opening tag is, if any*/
  NSRange r1 = [self rangeOfString:[NSString stringWithFormat:@"<%@", tag] options:NSCaseInsensitiveSearch];
  if (r1.location == NSNotFound)
    return nil;
  
  /*get the range of the rest of the string*/
  NSRange remainder = NSMakeRange(r1.location, [self length] - r1.location);
  
  /*and find where the first close tag is, if any*/
  NSRange r2 = [self rangeOfString:[NSString stringWithFormat:@"</%@", tag] options:NSCaseInsensitiveSearch range:remainder];
  if (r2.location == NSNotFound)
    return nil;
  
  insist (r2.location > r1.location);
  
  /*now we have an <tag ... </tag  pair. get the substring in between*/
  NSString*substring = [self substringWithRange:NSMakeRange(r1.location, r2.location-r1.location)];
  insist (substring);
  
  /*strip off ....> from the front, the rest of the start tag is still in the substring*/
  return [substring substringAfterString:@">"];
}

/*the range will include the start tag but the end tag*/
-(NSRange)rangeOfStringBetweenNestedTagsOfType:(NSString*)type range:(NSRange)range
{
  insist (self && type && [type length] && ![type grep:@"<"] && ![type grep:@">"]);
  
  /*get the start of the open/close tags*/
  NSString*openTag = [NSString stringWithFormat:@"<%@", type];
  NSString*closeTag = [NSString stringWithFormat:@"</%@", type];
                       
  /*find where the first opening tag is, if any*/
  unsigned rangeEnd = range.location + range.length;
  
  NSRange r1 = [self rangeOfString:openTag options:NSCaseInsensitiveSearch range:range];
  if (r1.location == NSNotFound)
    return NSMakeRange (NSNotFound, 0);
  unsigned startLocation = r1.location;
  
  /*get the range of the rest of the string*/
  NSRange remainder = NSMakeRange(r1.location, rangeEnd - r1.location);
  
  /*now search along for each open or close tag, finding the close tag that matches the opening one*/
  int depth = 0;
  NSRange r2;
  for (;;)
  {
    r1 = [self rangeOfString:openTag options:NSCaseInsensitiveSearch range:remainder];
    r2 = [self rangeOfString:closeTag options:NSCaseInsensitiveSearch range:remainder];

    if (r2.location == NSNotFound)
      return NSMakeRange (NSNotFound, 0);
    
    /*close tag came first*/
    if (r1.location == NSNotFound || r1.location > r2.location)
    {
      /*a close tag came first. we are done as long as we are matching w/ the open tag*/
      if (depth == 1)
        return NSMakeRange (startLocation, r2.location - startLocation);
      depth--;
      r2.location += [closeTag length];
      remainder = NSMakeRange(r2.location, rangeEnd - r1.location);
      continue;
    }
    
    /*open tag came first, increase depth*/
    insist (r1.location != NSNotFound);
    depth++;
    r1.location += [openTag length];
    remainder = NSMakeRange (r1.location, rangeEnd - r1.location);
    continue;
  }
  insist (0);
  return NSMakeRange (NSNotFound, 0);
}

@end
