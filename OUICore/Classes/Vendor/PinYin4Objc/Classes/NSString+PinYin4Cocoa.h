
#import <Foundation/Foundation.h>

@interface NSString (PinYin4Cocoa)

- (NSInteger)indexOfString:(NSString *)s;
- (NSInteger)indexOfString:(NSString *)s fromIndex:(int)index;
- (NSInteger)indexOf:(int)ch;
- (NSInteger)indexOf:(int)ch fromIndex:(int)index;
+ (NSString *)valueOfChar:(unichar)value;

-(NSString *) stringByReplacingRegexPattern:(NSString *)regex withString:(NSString *) replacement;
-(NSString *) stringByReplacingRegexPattern:(NSString *)regex withString:(NSString *) replacement caseInsensitive:(BOOL) ignoreCase;
-(NSString *) stringByReplacingRegexPattern:(NSString *)regex withString:(NSString *) replacement caseInsensitive:(BOOL) ignoreCase treatAsOneLine:(BOOL) assumeMultiLine;
-(NSArray *) stringsByExtractingGroupsUsingRegexPattern:(NSString *)regex;
-(NSArray *) stringsByExtractingGroupsUsingRegexPattern:(NSString *)regex caseInsensitive:(BOOL) ignoreCase treatAsOneLine:(BOOL) assumeMultiLine;
-(BOOL) matchesPatternRegexPattern:(NSString *)regex;
-(BOOL) matchesPatternRegexPattern:(NSString *)regex caseInsensitive:(BOOL) ignoreCase treatAsOneLine:(BOOL) assumeMultiLine;
@end
