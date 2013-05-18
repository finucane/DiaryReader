//
//  DFError.m
//  MyMySpaceMail
//
//  Created by David Finucane on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "DFError.h"

@implementation DFError

- (id) initWithDescription: (NSString*)aDescription code:(int)code
{
  [super initWithDomain:@"DF" code:code userInfo:nil];
  description = [aDescription retain];
  return self;
}

+ (id) errorWithDescription:(NSString*)aDescription code:(int)code
{
  DFError*error = [[DFError alloc] initWithDescription: aDescription code:code];
  return [error autorelease];
}

+ (id) errorWithDescription:(NSString*)aDescription
{
  DFError*error = [[DFError alloc] initWithDescription: aDescription code:0];
  return [error autorelease];
}

- (void) dealloc
{
  [description release];
  [super dealloc];
}
- (NSString*) localizedDescription
{
  return description;
}

+ (BOOL) match:(NSError*)error withCode:(int)code
{
  return error && [error code] == code && [[error domain] isEqualToString:@"DF"];
}

@end
