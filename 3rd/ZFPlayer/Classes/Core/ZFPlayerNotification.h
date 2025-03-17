























#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZFPlayerBackgroundState) {
    ZFPlayerBackgroundStateForeground,  // Enter the foreground from the background.
    ZFPlayerBackgroundStateBackground,  // From the foreground to the background.
};

@interface ZFPlayerNotification : NSObject

@property (nonatomic, readonly) ZFPlayerBackgroundState backgroundState;

@property (nonatomic, copy, nullable) void(^willResignActive)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^didBecomeActive)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^newDeviceAvailable)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^oldDeviceUnavailable)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^categoryChange)(ZFPlayerNotification *registrar);

@property (nonatomic, copy, nullable) void(^volumeChanged)(float volume);

@property (nonatomic, copy, nullable) void(^audioInterruptionCallback)(AVAudioSessionInterruptionType interruptionType);

- (void)addNotification;

- (void)removeNotification;

@end

NS_ASSUME_NONNULL_END
