//
//  DFWebReaders.h
//  MyMySpaceMail.tiger
//
//  Created by finucane on 12/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "DFWebReader.h"

@interface DFWebReaders : NSObject
{
  NSTimeInterval timeout;
  NSMutableArray*readers;
  int numReaders;
  id delegate;
  int numRead, numPending;
}
- (id) initWithDelegate:(id) aDelegate timeout:(NSTimeInterval)timeout;
- (void) start: (int)newNumReaders;
- (void)webReaderStatusChanged:(DFWebReader*)reader status:(NSString*)status;
@end
