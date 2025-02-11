


#import <Foundation/Foundation.h>
#import "WPFPinYinTools.h"

@interface WPFPerson : NSObject

/** 唯一标识符 */
@property (nonatomic, copy) NSString *personId;
/** 人物名称，如：王鹏飞 */
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *sub;
/** 拼音全拼（小写）如：@"wangpengfei" */
@property (nonatomic, copy) NSString *completeSpelling;
/** 拼音首字母（小写）如：@"wpf" */
@property (nonatomic, copy) NSString *initialString;
/**
 拼音全拼（小写）位置，如：@"0,0,0,0,1,1,1,1,2,2,2"
                        w a n g p e n g f e i
 */
@property (nonatomic, copy) NSString *pinyinLocationString;
/** 拼音首字母拼音（小写）数组字符串位置，如@"0,1,2" */
@property (nonatomic, copy) NSString *initialLocationString;
/** 高亮位置 */
@property (nonatomic, assign) NSInteger highlightLoaction;
/** 关键字范围 */
@property (nonatomic, assign) NSRange textRange;
/** 匹配类型 */
@property (nonatomic, assign) NSInteger matchType;

/** 是否包含多音字 */
@property (nonatomic, assign) BOOL isContainPolyPhone;
/** 第二个多音字 拼音全拼（小写） */
@property (nonatomic, copy) NSString *polyPhoneCompleteSpelling;
/** 第二个多音字 拼音首字母（小写）*/
@property (nonatomic, copy) NSString *polyPhoneInitialString;
/** 第二个多音字 拼音全拼（小写）位置 */
@property (nonatomic, copy) NSString *polyPhonePinyinLocationString;
/** 第二个多音字 拼音首字母拼音（小写）数组字符串位置 */




/**
 快速构建方法

 @param name 姓名
 @return 构建完毕的person
 */
+ (instancetype)personWithId:(NSString *)personId name:(NSString *)name hanyuPinyinOutputFormat:(HanyuPinyinOutputFormat *)pinyinFormat;
+ (instancetype)personWithId:(NSString *)personId name:(NSString *)name sub:(nullable NSString *)sub hanyuPinyinOutputFormat:(HanyuPinyinOutputFormat *)pinyinFormat;
@end
