//
//  Library.h
//  diaryreader
//
//  Created by David Finucane on 1/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Blog.h"

@interface Library : NSObject
{
  NSMutableArray*blogs;
  Blog*currentBlog;
  BOOL dirty;
  BOOL corrupted;
}

+(NSString*)pathForBlogID:(NSString*)blogID;
+(void)wipeFromDisk:(NSString*)blogID;

-(id)init;
-(void)add:(Blog*)blog;
-(void)remove:(Blog*)blog;
-(void)removeBlogAtIndex:(int)i;
-(int)getNumBlogs;
-(Blog*)getBlog:(int)i;
-(Blog*)getBlogWithID:(NSString*)blogID;
-(Blog*)getCurrentBlog;
-(void)moveBlogFrom:(int)from to:(int)to;
-(void)setCurrentBlog:(Blog*)blog;
-(BOOL)sync;
-(BOOL)wasCorrupted;
-(void)clearCorrupted;
-(NSString*)anyBlogID;
-(int)getCurrentBlogIndex;
@end
