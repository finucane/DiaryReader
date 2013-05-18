//
//  Tags.h
//  diaryreader
//
//  Created by David Finucane on 1/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tag : NSObject
{
@public
  NSString*word;
  NSMutableArray*entries;
}
-(id)initWithWord:(NSString*)aWord;
-(id)initWithCoder:(NSCoder*)coder;
-(void)encodeWithCoder:(NSCoder*)coder;
-(void)addEntry:(int)entry;
-(NSUInteger)hash;
- (BOOL)isEqual:(id)anObject;

@end

@interface Tags : NSObject
{
@public
  NSMutableArray*tags;
}

-(id) init;
-(id)initWithCoder:(NSCoder*)coder;
-(void)encodeWithCoder:(NSCoder*)coder;
-(void)addTags:(NSSet*)someTags;
@end
