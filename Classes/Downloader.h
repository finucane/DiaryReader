//
//  Downloader.h
//  diaryreader
//
//  Created by finucane on 1/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFWebReader.h"
#import "Blog.h"
#import "AppDelegate.h"

/*this downloads new entries and adds them to a blog*/

@interface Downloader : DFWebReader
{
  id delegate;
  Blog*blog;
  NSMutableString*buffer;
  unsigned numEntriesDownloaded;
  unsigned numEntriesExpected;
  NSAutoreleasePool*pool;
  BOOL done;
}

- (id) initWithDelegate:(id)aDelegate timeout:(NSTimeInterval)aTimeout blog:(Blog*)aBlog;
- (void) download:(id)anArgument;
+ (NSString*)prettyPage:(NSString*)contents date:(NSDate*)date title:(NSString*)title;

@end


@interface NSObject (DownloaderDelegate)
- (void) downloaderStatusChanged:(Downloader*)downloader status:(NSString*)status;
- (void) downloaderProgressed:(Downloader*)downloader value:(double)value;
- (void) downloaderFailed:(Downloader*)downloader reason:(NSString*)reason;
- (void) downloaderFinished:(Downloader*)downloader;
@end

