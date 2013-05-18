 //
//  StringCategory.h
//  4TrakStudio
//
//  Created by David Finucane on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (StringCategory)
- (BOOL) grep:(NSString*)s;
- (NSString*)htmlSafe;
- (BOOL) igrep:(NSString*)s;
- (BOOL) startsWith:(NSString*)s;
- (NSString*) stringByTrimmingString:(NSString*)s;
- (NSString*) stringByRemovingCharactersInString:(NSString*)s;
- (NSString *) flattenHTML;
- (NSString *) removeTags;
- (NSString *) stringByReplacing:(unichar)original withChar:(unichar)replacement;
- (NSString*) substringAfterString:(NSString*)s;
- (NSString*)substringToString:(NSString*)s;
- (NSArray*) componentsSeparatedByCharactersInString:(NSString*)s;
- (NSString*) stringWithoutRepeatedString:(NSString*)s options:(NSStringCompareOptions)mask;
- (NSArray*) nonEmptyComponentsSeparatedByString:(NSString*)s;
- (NSArray*) nonEmptyComponentsSeparatedByCharactersInSet:(NSCharacterSet*)set;
- (NSString*) removeTagsOfType:(NSString*)type;
- (NSString*)stringBetweenTags:(NSString*)tag;
- (NSString*) stringByCollapsingWhitespaceAndRemovingNewlines;
- (NSString *) replaceTagsOfType:(NSString*)type with:(NSString*)replacement;
- (NSString *) eradicateTag:(NSString*)type;
-(NSRange)rangeOfStringBetweenNestedTagsOfType:(NSString*)type range:(NSRange)range;
@end
