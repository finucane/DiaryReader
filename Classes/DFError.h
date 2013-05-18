//
//  DFError.h
//  MyMySpaceMail
//
//  Created by David Finucane on 12/8/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFError : NSError
{
  NSString*description;
}

- (id) initWithDescription:(NSString*)aDescription code:(int)code;
+ (id) errorWithDescription:(NSString*)aDescription;
+ (id) errorWithDescription:(NSString*)aDescription code:(int)code;
+ (BOOL) match:(NSError*)error withCode:(int)code;

- (void) dealloc;

@end
