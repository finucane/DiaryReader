//
//  DFWebReaders.m
//  MyMySpaceMail.tiger
//
//  Created by finucane on 12/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DFWebReaders.h"
#import "insist.h"

@implementation DFWebReaders
- (id) initWithDelegate:(id) aDelegate timeout:(NSTimeInterval)aTimeout
{
  self = [super init];
  delegate = [aDelegate retain];
  timeout = aTimeout;
  numPending = 0;
  readers = nil;
  numReaders = 0;
  return self;
}

- (void) dealloc
{
  [delegate release];
	[readers release];
  [super dealloc];  
}

- (void) start: (int)newNumReaders
{
  numReaders = newNumReaders;
  
  if (!readers)
    readers = [[NSMutableArray arrayWithCapacity:numReaders] retain];
  
  insist (readers);
  int readersCount = [readers count];
  
  for (int i = 0; i < numReaders - readersCount; i++)
  {
    id r = [self newReader];
    insist (r);
  	[readers addObject:r];
  }
  
  numRead = numPending = 0;
  
  /*fire off initial volley*/
  for (int i = 0; i < numReaders ; i++)
  {
    if (![self getAnother:[readers objectAtIndex:i]])
    {
      insist (i);
      break;
    }
  }
}

- (void)webReaderStatusChanged:(DFWebReader*)reader status:(NSString*)status
{
  [delegate webReaderStatusChanged:reader status:status];
}

@end
