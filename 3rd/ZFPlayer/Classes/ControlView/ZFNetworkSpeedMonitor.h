























#import <Foundation/Foundation.h>

extern NSString *const ZFDownloadNetworkSpeedNotificationKey;
extern NSString *const ZFUploadNetworkSpeedNotificationKey;
extern NSString *const ZFNetworkSpeedNotificationKey;

@interface ZFNetworkSpeedMonitor : NSObject

@property (nonatomic, copy, readonly) NSString *downloadNetworkSpeed;
@property (nonatomic, copy, readonly) NSString *uploadNetworkSpeed;

- (void)startNetworkSpeedMonitor;
- (void)stopNetworkSpeedMonitor;

@end
