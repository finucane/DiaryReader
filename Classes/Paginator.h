//
//  Paginator.h
//  diaryreader
//
//  Created by finucane on 1/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Blog.h"
#import "AppDelegate.h"

@interface Paginator : NSObject
{
  NSMutableArray*pageLengths;
  NSString*text;
  Blog*blog;
  Month*month;
  NSLock*lock;
  UIFont*font;
  CGRect frame;
  BOOL shouldStop;
  BOOL stopped;
  unsigned firstPosition;
  id delegate;
  CGContextRef pendingContext;
  unsigned pendingPosition;
  unsigned pendingLength;
  unsigned pendingTopPosition;
  unsigned lastTopPosition;
  AppDelegate*appDelegate;
}

-(id) initWithBlog:(Blog*)aBlog month:(Month*)aMonth font:(UIFont*)aFont frame:(CGRect)aFrame delegate:(id)aDelegate appDelegate:(AppDelegate*)anAppDelegate;
-(void)paginate:(id)anArgument;
-(void)stop;
-(BOOL)drawPageContainingPosition:(unsigned)position context:(CGContextRef)context topPosition:(unsigned*)topPosition length:(unsigned*)length failed:(BOOL*)failed;
-(unsigned)fileOffsetToLocalPosition:(unsigned)fileOffset;
-(unsigned)localPositionToFileOffset:(unsigned)localPosition;

@end


@interface NSObject (PaginatorDelegate)
-(void) pageDrawnByPaginator:(Paginator*)aPaginator topPosition:(unsigned)topPosition length:(unsigned)length;
-(void) pageFailedByPaginator:(Paginator*)aPaginator;
-(void) paginatorStopped:(Paginator*)aPaginator;
@end
