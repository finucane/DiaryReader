//
//  Paginator.m
//  diaryreader
//
//  Created by finucane on 1/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Paginator.h"
#import "AppDelegate.h"
#import "insist.h"


@implementation Paginator

-(id) initWithBlog:(Blog*)aBlog month:(Month*)aMonth font:(UIFont*)aFont frame:(CGRect)aFrame delegate:(id)aDelegate appDelegate:(AppDelegate*)anAppDelegate;
{
  insist (aBlog && aMonth && aFont && aDelegate && anAppDelegate);
  self = [super init];
  insist (self);
  
  pageLengths = [[NSMutableArray alloc] init];
  blog = [aBlog retain];
  month = [aMonth retain];
  font = [aFont retain];
  frame = aFrame;
  
  /*never retain delegates is my new rule, to avoid retain cycles. the assumption is all delegates own their delegees*/
  delegate = aDelegate;
  appDelegate = anAppDelegate;
  
  lock = [[NSLock alloc] init];
  insist (lock);
  
  pendingContext = 0;
  
  /*we set this here to avoid race conditions. we assume it's an error to call paginate more than once etc*/
  shouldStop = stopped = NO;
  return self;
}

/*draw a page worth of text starting at position and return how many characters 
  worth of text we got past in the drawing. the number isn't the same as what we actually draw
  but that doesn't matter. if context is nil it we don't actually draw, this is for when we
  are paginating.
 */

- (unsigned)layoutFrom:(unsigned) textPosition context:(CGContextRef)context
{
  insist (text);
  
  BOOL startOfLine = YES;
  BOOL startOfPage = YES;
  unsigned startPosition = textPosition;

  CGPoint point = frame.origin;
  
  /*the text drawing routines draw to the current context*/
  if (context)
    UIGraphicsPushContext(context);
  
  /*compute some metrics that we'll use for our layout*/
  CGSize size = [@"Xy" sizeWithFont:font];
  CGFloat lineHeight = size.height * 1.0; /*20% more for leading*/
  /*get various widths*/
  size = [@"mn" sizeWithFont:font];
  CGFloat indentWidth = size.width;
  
  size = [@"  " sizeWithFont:font];
  CGFloat widthBetweenSentences = size.width;
  
  size = [@" " sizeWithFont:font];
  CGFloat widthBetweenWords = size.width;
  
  /*the characters that separate words are our 2 fake paragraphing characters that Downloader inserted, space, and tab*/
  NSCharacterSet*whitespace = [NSCharacterSet characterSetWithCharactersInString:
                               [NSString stringWithFormat:@"%C%C \n\t\r", FAKE_P_CHAR, FAKE_BR_CHAR]];
  unsigned textLength = [text length];
  

  /*in case we had to cut a word, this tells us where to do it at the start of the loop*/
  NSUInteger cutLocation = NSNotFound;
  
  /*keep track of how many newlines in a row we have, never allow more than 1.*/
  int numNewLines = 0;
  /*big nasty state machine, don't pretend we understand it enough to have any loop conditions*/
  for (;;)
  {
    NSString*word;
    
    /*if we've run off the page then move point down a line.
      either we are already below the bottom of the page, and code below
      will detect this, or we just ran out off the right and there's still
      room at the bottom. we might up eating lots of whitespace and newlines
      between pages. this is because we never draw whitespace so we don't have
      boxes to test with.*/
    
    if (!CGRectContainsPoint (frame, point))
    {
      point.x = frame.origin.x;
      point.y += lineHeight;
    }
    
    /*if we've run out of text we are done*/
    if (textPosition >= textLength)
      break;
    
    /*get the next possible word boundary -- whitespace*/
    NSRange r;
    if (cutLocation != NSNotFound)
    {
      r = NSMakeRange(cutLocation, 1);
      cutLocation = NSNotFound;
    }
    else
      r = [text rangeOfCharacterFromSet:whitespace options:0 range:NSMakeRange(textPosition, textLength-textPosition)];
    
    /*if we are already at a whitespace*/
    if (r.location == textPosition)
    {
      unichar c = [text characterAtIndex:textPosition];
      if (c == FAKE_P_CHAR)
      {
        if (numNewLines <= 2)
        {
          /*we are at a new paragraph. move down a line*/
          if (numNewLines < 2 && !startOfLine && !startOfPage)
          {
            point.y += lineHeight;
            numNewLines++;
          }
          /*no matter what, indent for a paragraph*/
          point.x = frame.origin.x + indentWidth;
        }
        /*move past the character*/
        textPosition++;
        startOfLine = startOfPage = NO;
        continue;
      }
      else if (c == FAKE_BR_CHAR)
      {
        /*we are at a newline, move down a line no matter what (well sort of)*/
        if (numNewLines < 2)
        {
          point.y += lineHeight;
          numNewLines++;
        }
        startOfPage = NO;
        startOfLine = YES;
        point.x = frame.origin.x;
        textPosition++;

        continue;
      }
      /*it's whitespace separating words. ignore it*/
      textPosition++;
      continue;
    }
    unsigned newTextPosition;
    if (r.location == NSNotFound)
    {
      /*no more whitespace, the next word to draw is whatever's left*/
      word = [text substringWithRange:NSMakeRange(textPosition, textLength - textPosition)];
      insist (word);
      newTextPosition = textLength;
    }
    else
    {
      word = [text substringWithRange:NSMakeRange(textPosition, r.location - textPosition)];
      insist (word);
      newTextPosition = r.location;
    }
    numNewLines = 0;
    /*now we have a point inside the frame where we can draw to, and a word to draw.
      first see how much space it will take up*/
    size = [word sizeWithFont:font];
    CGRect box = CGRectMake(point.x, point.y, size.width, size.height);
    
    if (CGRectContainsRect (frame, box))
    {
      /*there's room for the word, sweet. just draw it (if we are in drawing mode)*/

      if (context)
        [word drawAtPoint:point withFont:font];
      
      /*if the word ends in a . assume it's the end of the sentence, otherwise we need to make space for the next word.*/
      point.x += size.width + ([word hasSuffix:@"."] ? widthBetweenSentences : widthBetweenWords);
      startOfPage = startOfLine = NO;

      textPosition = newTextPosition;
      
      /*check to see if we ran off the edge of the page*/
      if (!CGRectContainsPoint (frame, point))
      {
        /*move down a line. this might still run off but this is checked at the top of the loop*/
        point.x = frame.origin.x;
        point.y += lineHeight;
        startOfLine = YES;
      }
      continue;
    }
    
    /*we didn't fit inside the frame. see if we ran off the bottom of the page first.
     this could already have happened if the point was inside the frame but not box,
     so we're checking again now that we have box*/
    if (box.origin.y + box.size.height > frame.origin.y + frame.size.height)
      break;
    
    /*we ran off the right edge of the page. there are 2 cases now, the hard case is the word won't even fit on a line
     all by itself. check for that first*/
    
    if (size.width > frame.size.width)
    {
      /*this should just not happen unless the user is an asshole and has a huge font.
       so don't waste any blood trying to be fast. just go along and find out how much of the word does fit
       and chop the word there.*/
      int len;
      for (len = 0; len < [word length]; len++)
      {
        NSString*s = [word substringToIndex:len+1];
        size = [s sizeWithFont:font];
        if (size.width > frame.size.width)
          break;
      }
      /*i don't care how big the font is, at least 1 character has to fit*/
      insist (len);
      
      /*set the cutLocation, this is the start of the second part of the cut word.*/
      cutLocation = textPosition + len;
      continue;
    }
    /*the word will fit on a line, so we don't have to cut, just move down a line*/
    point.x = frame.origin.x;
    point.y += lineHeight;
    startOfLine = YES;
    startOfPage = NO;
  }

  if (context)
    UIGraphicsPopContext ();
  
  return textPosition - startPosition;
}

/*correct a global offset into this month by taking into account
  all the gaps in entries before whatever entry position is in*/
-(unsigned)fileOffsetToLocalPosition:(unsigned)fileOffset;
{
  insist (self && blog && month);
  
  /*get the file offset of the start of the month and make the fileOffset local*/
  Entry*firstEntry = [blog getEntry:month->firstEntry];
  insist (fileOffset >= firstEntry->offset);
  fileOffset -= firstEntry->offset;
  
  /*step along entry by entry, taking into account the gaps until we hit the fileOffset
    in practice the fileOffset is going to be for the start of an Entry, so we'll always
    hit it. In other words we can't jump to random positions in the text.*/
  unsigned offset = 0;
  unsigned gapTotal = 0;
  for (int i = 0; offset < fileOffset; i++)
  {
    Entry*entry = [blog getEntry:month->firstEntry + i];
    insist (entry);

    offset += entry->length + entry->gap;
    gapTotal += entry->gap;
  }

  /*now we know how much gap space were before us, subtract that and we're done*/
  insist (gapTotal <= fileOffset);
  return fileOffset - gapTotal;
}

- (BOOL)getOffset:(unsigned*)offset ofPageForLocalPosition:(unsigned)position
{
  insist (offset);
  *offset = 0;

  int i;
  for (i = 0; i < [pageLengths count]; i++)
  {    
    unsigned n = [[pageLengths objectAtIndex:i] unsignedIntegerValue];
    if (position >= *offset && position < *offset + n)
      break;
    *offset += n;
  }
  return i < [pageLengths count];
}

- (void) reportPageDone
{
  [delegate pageDrawnByPaginator:self topPosition:[self localPositionToFileOffset:pendingTopPosition] length:pendingLength];
}

-(unsigned)localPositionToFileOffset:(unsigned)localPosition;
{
  insist (self);
  Entry*firstEntry = [blog getEntry:month->firstEntry];
  
  unsigned offset = 0;
  unsigned gapTotal = 0;
  
  /*step along and count out how much gap space is before the localPosition.*/
  for (int i = 0; offset < localPosition; i++)
  {
    Entry*entry = [blog getEntry:month->firstEntry + i];
    insist (entry);
    
    offset += entry->length;
    gapTotal += entry->gap;
  }

  /*convert back to global position*/
  return localPosition + firstEntry->offset + gapTotal;
}

/*this is called on a separate thread to paginate a month in the background*/
-(void)paginate:(id)anArgument
{
  /*we are on a new thread so we have to set up an autorelease pool*/
  NSAutoreleasePool*pool = [[NSAutoreleasePool alloc] init];
  insist (pool);

  insist (pageLengths && blog && month && font);
  
  /*first get the text for the whole month. first get the first and last entries in the month*/
  Entry*firstEntry = [blog getEntry:month->firstEntry];
  Entry*lastEntry = [blog getEntry:month->firstEntry + month->numEntries - 1];
  insist (firstEntry && lastEntry);

  /*get the length of text*/
  unsigned length = lastEntry->offset + lastEntry->length - firstEntry->offset;
  firstPosition = firstEntry->offset;
  
  /*get the text*/
  text = [[blog getTextAtPosition:firstPosition length:length] retain];
  insist (text);
  unsigned position = 0;

  unsigned total = 0;
  unsigned lastLength;
  /*eat up the string into pageLengths*/
  while (!shouldStop && position < [text length])
  {
    [lock lock];
    
    /*context nil means we aren't actually drawing*/
    lastLength = [self layoutFrom:position context:nil];
    
    /*it should never happen that length is 0, but logically it means we're done*/
    if (lastLength == 0)
    {
      [lock unlock];
      break;
    }
    total += lastLength;
    [pageLengths addObject:[NSNumber numberWithUnsignedInt:lastLength]];

    position += lastLength;
    [pool release];
    pool = [[NSAutoreleasePool alloc] init];

    /*see if we have been requested to draw a page that we've got paginated so far*/
    /*the way we are using this code none of this should ever happen*/
    unsigned offset;
    if (pendingContext) 
    {
      if ([self getOffset:&offset ofPageForLocalPosition:pendingPosition])
      {
        /*we can draw it immediately*/
        pendingLength = [self layoutFrom:offset context:pendingContext];
        pendingTopPosition = offset;
        pendingContext = nil;
        [self reportPageDone];
        //[self performSelectorOnMainThread:@selector (reportPageDone) withObject:nil waitUntilDone:YES];
      }
      else if (pendingPosition < position)
      {
        /*this means we have paginated enough to know that the pendingPosition request is not going to be
          in this chapter -- it's before what we've paginated so far*/
        pendingContext = nil;
        [delegate pageFailedByPaginator:self];
        //[delegate performSelectorOnMainThread:@selector (pageFailedByPaginator:) withObject:self waitUntilDone:YES];
      }
    }
    [lock unlock];
  }
  
  lastTopPosition = firstEntry->offset;

  /*find the top position of the last page*/
  for (int i = 0; i < [pageLengths count] - 1; i++)
    lastTopPosition += [[pageLengths objectAtIndex:i] unsignedIntegerValue];  
  
  /*done. first check the case where the delegate wanted us to draw an out of bounds page*/
  if (pendingContext)
  {
    pendingContext = nil;
    [delegate pageFailedByPaginator:self];
    //[delegate performSelectorOnMainThread:@selector (pageFailedByPaginator:) withObject:self waitUntilDone:YES];
  }
  stopped = YES;
  /*tell the delegate we're done.*/
  [delegate paginatorStopped:self];
//  [delegate performSelectorOnMainThread: @selector (paginatorStopped:) withObject:self waitUntilDone:YES];
  [pool release];
}

-(void)stop
{
  /*if we are already stopped instantly tell the delegate*/
  /*lock to prevent a race*/
  [lock lock];
  shouldStop = YES;
  [lock unlock];
}

/*returns YES if we were able to draw the page immediately. if it works, the page's first postion and length are returned in topPosition and length
  those 2 values are in local space.*/
-(BOOL)drawPageContainingPosition:(unsigned)position context:(CGContextRef)context topPosition:(unsigned*)topPosition length:(unsigned*)length failed:(BOOL*)failed
{
  insist (pageLengths && blog && month && context);
  insist (!pendingContext);
  insist (topPosition && length && failed);
  
  *failed = NO;
  
  /*find start of the page containing position, if possible*/
  Entry*firstEntry = [blog getEntry:month->firstEntry];
  unsigned offset = firstEntry->offset;

  /*if we are being asked to draw a postion in a previous month/chapter, forget it*/
  if (position < offset)
  {
    *failed = YES;
    return YES;
  }

  /*covert offset to the local string offset*/
  position = [self fileOffsetToLocalPosition:position];
  
  [lock lock];
  unsigned tempTopPosition;
  if ([self getOffset:&tempTopPosition ofPageForLocalPosition:position])
  {
    *length = [self layoutFrom:tempTopPosition context:context];
    /*convert back to global offsets, length is still local, i.e. doesn't include gaps*/
    *topPosition = [self localPositionToFileOffset:tempTopPosition];
  
    [lock unlock];
    return YES;
  }
  
  /*if we are done paginating and yet can't draw it means the page is out of bounds*/
  if (stopped)
  {
    *failed = YES;
    [lock unlock];
    return YES;
  }
  [lock unlock];
  return NO;

  /*we can't draw now, keep track of this request so when we paginate far enough we can draw*/
  pendingPosition = position;
  pendingContext = context;
  [lock unlock];
  return NO;
}
 
-(void) dealloc
{
  [pageLengths release];
  [blog release];
  [lock release];
  [text release];
  [super dealloc];
}

@end
