//
//  UrlChecker.h
//  diaryreader
//
//  Created by finucane on 1/23/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFWebReader.h"

@interface UrlChecker : DFWebReader
{
  NSString*blogID;
  id delegate;
  
}
-(id) initWithDelegate:(id)aDelegate timeout:(NSTimeInterval)timeout;
-(void) checkUrl:(NSString*)url;
-(NSString*)getBlogID;
@end


@interface NSObject (UrlCheckerDelegate)
- (void) urlCheckerStatusChanged:(UrlChecker*)urlChecker status:(NSString*)status;
- (void) urlCheckerFailed:(UrlChecker*)urlChecker reason:(NSString*)reason;
- (void) urlCheckerFinished:(UrlChecker*)urlChecker;
- (NSMutableArray*)getEntries;
@end