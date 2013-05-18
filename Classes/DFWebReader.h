//
//  DFWebReader.h
//  MyMySpaceMail
//
//  Created by David Finucane on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DFWebReader : NSObject
{
  @private
  NSTimer*timer;
  NSTimeInterval timeout;
  NSMutableData*data;
  
  @protected
  NSURLConnection*connection;
  
  @public
  BOOL cancelled;
}

- (id) initWithTimeout: (NSTimeInterval)aTimeout;
- (void) cancel;
- (void) setPending:(BOOL)pending;
- (void) setTimer;
- (void) clearTimer;
- (NSURLRequest*)requestWithString:(NSString*)s;
- (NSMutableURLRequest*)mutableRequestWithString:(NSString*)s;
- (NSString*) salvageString:(NSData*)someData;

  /*override these*/
- (BOOL) isBinary;
- (void) didLoad:(NSScanner*)scanner;
- (void) didLoadData:(NSData*)data;
- (void) didFail:(NSError*)error;
- (BOOL) cullData:(NSData*)someData;

@end

@interface NSObject (DFWebReader)
- (void)webReaderStatusChanged:(DFWebReader*)reader status:(NSString*)status;
@end
