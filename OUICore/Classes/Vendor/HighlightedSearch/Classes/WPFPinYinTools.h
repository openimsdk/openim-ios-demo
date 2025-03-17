
#import <Foundation/Foundation.h>
#import "PinYin4Objc.h"

@class WPFPerson;

typedef NS_ENUM(NSUInteger, MatchType) {
    MatchTypeChinese,  
    MatchTypeComplate, 
    MatchTypeInitial,  
};

@interface WPFSearchResultModel : NSObject

/** 高亮范围 */
@property (nonatomic, assign) NSRange highlightedRange;
/** 匹配类型 */
@property (nonatomic, assign) MatchType matchType;

@end

@interface WPFPinYinTools : NSObject

/** 判断传入的字符串是否是纯中文 */
+ (BOOL)isChinese:(NSString *)string;
/** 判断传入的字符串是否包含英文 */
+ (BOOL)includeChinese:(NSString *)string;
/** 获取传入字符串的第一个拼音字母 */
+ (NSString *)firstCharactor:(NSString *)aString withFormat:(HanyuPinyinOutputFormat *)pinyinFormat;

/** 获取格式化器 */
+ (HanyuPinyinOutputFormat *)getOutputFormat;

+ (WPFSearchResultModel *)searchEffectiveResultWithSearchString:(NSString *)searchStrLower
                                                         Person:(WPFPerson *)person;
/** 排序规则 */
+ (NSArray *)sortingRules;

@end
