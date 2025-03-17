























#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#if __has_include(<ZFPlayer/ZFPlayerMediaPlayback.h>)
#import <ZFPlayer/ZFPlayerMediaPlayback.h>
#else
#import "ZFPlayerMediaPlayback.h"
#endif

@interface ZFAVPlayerManager : NSObject <ZFPlayerMediaPlayback>

@property (nonatomic, strong, readonly) AVURLAsset *asset;
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;
@property (nonatomic, strong, readonly) AVPlayer *player;
@property (nonatomic, assign) NSTimeInterval timeRefreshInterval;

@property (nonatomic, strong) NSDictionary *requestHeader;

@property (nonatomic, strong, readonly) AVPlayerLayer *avPlayerLayer;

@end
