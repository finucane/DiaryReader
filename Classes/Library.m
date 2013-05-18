//
//  Library.m
//  diaryreader
//
//  Created by David Finucane on 1/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Library.h"
#import "insist.h"

#define DIRECTORIES_FMT @"%@/directories"
#define VERSION_FMT @"%@/version"
#define CURRENT_BLOG_FMT @"%@/current_blog"
#define VERSION 0

@implementation Library

+(NSString*)pathForBlogID:(NSString*)blogID
{
  return [NSString stringWithFormat:@"%@/blogs/%@", [AppDelegate home], blogID];
}

+(BOOL)existsOnDisk:(NSString*)blogID
{
  return [[NSFileManager defaultManager] fileExistsAtPath: [Library pathForBlogID:blogID]];
}

+(void)wipeFromDisk:(NSString*)blogID
{
  [[NSFileManager defaultManager] removeItemAtPath: [Library pathForBlogID:blogID] error:nil];
}

-(id)init
{
  self = [super init];
  insist (self);
  
  dirty = corrupted = NO;
  
  /*get the version, if any. this is so if we change any of the file formats in this app we can be
   silently convert older file formats to the latest rather than just crash.*/
  
  NSString*path = [NSString stringWithFormat:VERSION_FMT, [AppDelegate home]];
  insist (path);  

  int version = -1;
  @try
  {
    NSNumber*n = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    insist (n);
    version = [n intValue];
  }
  @catch (NSException*exception)
  {
    version = -1;
  }
  if (version < 0)
  {
    version = VERSION;
    dirty = YES;
  }
  
  /*here is where we would start caring about if version != VERSION*/
  
  path = [NSString stringWithFormat:DIRECTORIES_FMT, [AppDelegate home]];
  insist (path);
  NSArray*directories = nil;
  
  /*get the list of blog directories if any*/
  @try
  {
    directories = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    insist (directories);
  }
  @catch (NSException*exception)
  {
    dirty = YES;
    [directories release];
    directories = nil;
  }

  if (!directories)
  {
    directories = [[[NSArray alloc] init] autorelease];
    dirty = YES;
  }
  
  insist (directories);
  
  currentBlog = nil;
  
  /*make an array for our blogs*/
  blogs = [[NSMutableArray arrayWithCapacity:[directories count]] retain];
  
  /*read each blog from disk. if anything goes wrong just delete the blog silently -- it was a corrupted directory*/
  for (int i = 0; i < [directories count]; i++)
  {
    NSString*blogPath = [directories objectAtIndex:i];
    insist (blogPath);

    @try
    {
      Blog*blog = [NSKeyedUnarchiver unarchiveObjectWithFile:[Blog archivePath:blogPath]];
      insist (blog);
      [blogs addObject:blog];
    }
    @catch (NSException*exception)
    {
      corrupted = dirty = YES;
      [[NSFileManager defaultManager] removeItemAtPath: blogPath error:nil];
    }
  }
  
  /*remember any currentBlog from last time the app was running*/
  @try
  {
    NSNumber*n = [NSKeyedUnarchiver unarchiveObjectWithFile:[NSString stringWithFormat:CURRENT_BLOG_FMT, [AppDelegate home]]];
    insist (n);
    int whichIndex = [n intValue];
    if (whichIndex >= 0 && whichIndex < [blogs count])
      currentBlog = [blogs objectAtIndex:whichIndex];
  }
  @catch (NSException*exception)
  {
    dirty = YES;
  }
  return self;
}

-(void) dealloc
{
  [blogs release];
  [super dealloc];
}

-(Blog*)getBlogWithID:(NSString*)blogID
{
  insist (self && blogID && blogs);
  for (int i = 0; i < [blogs count]; i++)
  {
    Blog*blog = [blogs objectAtIndex:i];
    insist (blog);
    if ([[blog getBlogID] isEqualToString:blogID])
      return blog;
  }
  return nil;
}

-(Blog*)getCurrentBlog
{
  return currentBlog;
}

-(void)add:(Blog*)blog
{
  insist (![self getBlogWithID:[blog getBlogID]]);
  [blogs addObject:blog];
  
  dirty = YES;
}

-(void)remove:(Blog*)blog
{
  insist (self && blog && blogs);
  insist ([self getBlogWithID:[blog getBlogID]]);
  [Library wipeFromDisk:[blog getBlogID]];
  [blogs removeObjectIdenticalTo:blog];
  if (blog == currentBlog)
    currentBlog = nil;
  dirty = YES;
}

-(void)removeBlogAtIndex:(int)i
{
  insist (self && blogs);
  insist (i >= 0 && i < [blogs count]);
  
  Blog*blog = [blogs objectAtIndex:i];
  [Library wipeFromDisk:[blog getBlogID]];
  [blogs removeObjectAtIndex:i];
  
  if (blog == currentBlog)
    currentBlog = nil;
  dirty = YES;
}

-(int)getCurrentBlogIndex
{
  if (!currentBlog) return -1;
  for (int i = 0; i < [blogs count]; i++)
    if ([blogs objectAtIndex:i] == currentBlog)
      return i;
  return -1;
}

-(int)getNumBlogs
{
  insist (self && blogs);
  return [blogs count];
}

-(Blog*)getBlog:(int)i
{
  insist (self && blogs && i >= 0 && i < [blogs count]);
  return [blogs objectAtIndex:i];
}

-(void)moveBlogFrom:(int)from to:(int)to
{
  insist (self && blogs && from >= 0 && from < [blogs count]);
  insist (to >= 0 && to < [blogs count]);
  if (to == from) return;
  
  /*remove the blog from the list but retain it so it doesn't get actually deleted*/
  Blog*blog = [[blogs objectAtIndex:from] retain];
  insist (blog);
  [blogs removeObjectIdenticalTo:blog];

  /*add the object back*/
  [blogs insertObject:blog atIndex:to];
  
  /*fix the reference count*/
  [blog release];
  dirty = YES;
}

/*this keeps track of any blog that might be changing so we can sync it later*/
-(void)setCurrentBlog:(Blog*)blog
{
  insist (self);
  if (currentBlog == blog) return;
  
  if (currentBlog)
    [currentBlog sync];
  currentBlog = blog;
  dirty = YES;
}

-(BOOL)sync
{
  /*get the currentBlog index (-1 means no currentBlog)*/
  int currentBlogIndex = -1;
  if (currentBlog)
    currentBlogIndex = [blogs indexOfObjectIdenticalTo:currentBlog];  
  
  /*sync all blogs*/
  for (int i = 0; i < [blogs count]; i++)
    [[blogs objectAtIndex:i] sync];
  
  if (!dirty)
    return YES;
  
  /*archive the version*/
  [NSKeyedArchiver archiveRootObject:[NSNumber numberWithInt:VERSION]
                              toFile:[NSString stringWithFormat:VERSION_FMT, [AppDelegate home]]];
  
  /*archive the current blog index*/
  [NSKeyedArchiver archiveRootObject:[NSNumber numberWithInt:currentBlogIndex]
                              toFile:[NSString stringWithFormat:CURRENT_BLOG_FMT, [AppDelegate home]]];
  
  NSMutableArray*directories = [NSMutableArray arrayWithCapacity:[blogs count]];
  insist (directories);
  
  /*now make an array of directory paths for all the blogs*/
  for (int i = 0; i < [blogs count]; i++)
  {
    Blog*blog = [blogs objectAtIndex:i];
    insist (blog);
    NSString*path = [blog getPath];
    insist (path && [[NSFileManager defaultManager] fileExistsAtPath: path]);
    [directories addObject:path];
  }
  
  /*and archive the array*/

  dirty = ![NSKeyedArchiver archiveRootObject:directories toFile:[NSString stringWithFormat:DIRECTORIES_FMT, [AppDelegate home]]];
  return !dirty;
}

-(BOOL)wasCorrupted
{
  return corrupted;
}

-(void)clearCorrupted
{
  corrupted = NO;
}

- (NSString*)anyBlogID
{
  if ([blogs count] == 0)
    return nil;
  return [[blogs lastObject] getBlogID];
}

@end
