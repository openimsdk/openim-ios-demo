























#import <Foundation/Foundation.h>
#import "ZFPlayerView.h"
#import "ZFPlayerConst.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZFPlayerMediaPlayback <NSObject>

@required

@property (nonatomic) ZFPlayerView *view;



@property (nonatomic) float volume;



@property (nonatomic, getter=isMuted) BOOL muted;

@property (nonatomic) float rate;

@property (nonatomic, readonly) NSTimeInterval currentTime;

@property (nonatomic, readonly) NSTimeInterval totalTime;

@property (nonatomic, readonly) NSTimeInterval bufferTime;

@property (nonatomic) NSTimeInterval seekTime;

@property (nonatomic, readonly) BOOL isPlaying;

@property (nonatomic) ZFPlayerScalingMode scalingMode;

/**
 @abstract Check whether video preparation is complete.
 @discussion isPreparedToPlay processing logic
 
 * If isPreparedToPlay is true, you can call [ZFPlayerMediaPlayback play] API start playing;
 * If isPreparedToPlay to false, direct call [ZFPlayerMediaPlayback play], in the play the internal automatic call [ZFPlayerMediaPlayback prepareToPlay] API.
 * Returns true if prepared for playback.
 */
@property (nonatomic, readonly) BOOL isPreparedToPlay;

@property (nonatomic) BOOL shouldAutoPlay;

@property (nonatomic, nullable) NSURL *assetURL;

@property (nonatomic) CGSize presentationSize;

@property (nonatomic, readonly) ZFPlayerPlaybackState playState;

@property (nonatomic, readonly) ZFPlayerLoadState loadState;





@property (nonatomic, copy, nullable) void(^playerPrepareToPlay)(id<ZFPlayerMediaPlayback> asset, NSURL *assetURL);

@property (nonatomic, copy, nullable) void(^playerReadyToPlay)(id<ZFPlayerMediaPlayback> asset, NSURL *assetURL);

@property (nonatomic, copy, nullable) void(^playerPlayTimeChanged)(id<ZFPlayerMediaPlayback> asset, NSTimeInterval currentTime, NSTimeInterval duration);

@property (nonatomic, copy, nullable) void(^playerBufferTimeChanged)(id<ZFPlayerMediaPlayback> asset, NSTimeInterval bufferTime);

@property (nonatomic, copy, nullable) void(^playerPlayStateChanged)(id<ZFPlayerMediaPlayback> asset, ZFPlayerPlaybackState playState);

@property (nonatomic, copy, nullable) void(^playerLoadStateChanged)(id<ZFPlayerMediaPlayback> asset, ZFPlayerLoadState loadState);

@property (nonatomic, copy, nullable) void(^playerPlayFailed)(id<ZFPlayerMediaPlayback> asset, id error);

@property (nonatomic, copy, nullable) void(^playerDidToEnd)(id<ZFPlayerMediaPlayback> asset);

@property (nonatomic, copy, nullable) void(^presentationSizeChanged)(id<ZFPlayerMediaPlayback> asset, CGSize size);




- (void)prepareToPlay;

- (void)reloadPlayer;

- (void)play;

- (void)pause;

- (void)replay;

- (void)stop;

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler;

@optional

- (UIImage *)thumbnailImageAtCurrentTime;

- (void)thumbnailImageAtCurrentTime:(void(^)(UIImage *))handler;

@end

NS_ASSUME_NONNULL_END
