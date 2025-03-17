
#import <Foundation/Foundation.h>

@interface WPFPinYinDataManager : NSObject

+ (WPFPinYinDataManager *)shareInstance;

/** 添加解析的单个数据源,id标识符是为了防止重名 */
+ (void)addInitializeString:(NSString *)string identifer:(NSString *)identifier;
+ (void)addInitializeString:(NSString *)string sub:(NSString *)sub identifer:(NSString *)identifier;

/** 获取已解析的数据源 */
+ (NSArray *)getInitializedDataSource;

- (void)clearDataSource;
@end
