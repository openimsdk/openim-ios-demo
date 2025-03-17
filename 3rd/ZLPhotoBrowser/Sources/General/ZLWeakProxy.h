

























#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLWeakProxy : NSObject

@property (nonatomic, weak, readonly, nullable) id target;

- (nonnull instancetype)initWithTarget:(nonnull id)target NS_SWIFT_NAME(init(target:));
+ (nonnull instancetype)proxyWithTarget:(nonnull id)target NS_SWIFT_NAME(proxy(target:));

@end

NS_ASSUME_NONNULL_END
