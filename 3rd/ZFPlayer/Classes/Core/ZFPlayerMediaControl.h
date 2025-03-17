























#import <Foundation/Foundation.h>
#import "ZFPlayerMediaPlayback.h"
#import "ZFOrientationObserver.h"
#import "ZFPlayerGestureControl.h"
#import "ZFReachabilityManager.h"
@class ZFPlayerController;

NS_ASSUME_NONNULL_BEGIN

@protocol ZFPlayerMediaControl <NSObject>

@required

@property (nonatomic, weak) ZFPlayerController *player;

@optional

#pragma mark - Playback state

- (void)videoPlayer:(ZFPlayerController *)videoPlayer prepareToPlay:(NSURL *)assetURL;

- (void)videoPlayer:(ZFPlayerController *)videoPlayer playStateChanged:(ZFPlayerPlaybackState)state;

- (void)videoPlayer:(ZFPlayerController *)videoPlayer loadStateChanged:(ZFPlayerLoadState)state;

#pragma mark - progress

/**
 When the playback changed.
 
 @param videoPlayer the player.
 @param currentTime the current play time.
 @param totalTime the video total time.
 */
- (void)videoPlayer:(ZFPlayerController *)videoPlayer
        currentTime:(NSTimeInterval)currentTime
          totalTime:(NSTimeInterval)totalTime;

/**
 When buffer progress changed.
 */
- (void)videoPlayer:(ZFPlayerController *)videoPlayer
         bufferTime:(NSTimeInterval)bufferTime;

/**
 When you are dragging to change the video progress.
 */
- (void)videoPlayer:(ZFPlayerController *)videoPlayer
       draggingTime:(NSTimeInterval)seekTime
          totalTime:(NSTimeInterval)totalTime;

/**
 When play end.
 */
- (void)videoPlayerPlayEnd:(ZFPlayerController *)videoPlayer;

/**
 When play failed.
 */
- (void)videoPlayerPlayFailed:(ZFPlayerController *)videoPlayer error:(id)error;

#pragma mark - lock screen

/**
 When set `videoPlayer.lockedScreen`.
 */
- (void)lockedVideoPlayer:(ZFPlayerController *)videoPlayer lockedScreen:(BOOL)locked;

#pragma mark - Screen rotation

/**
 When the fullScreen maode will changed.
 */
- (void)videoPlayer:(ZFPlayerController *)videoPlayer orientationWillChange:(ZFOrientationObserver *)observer;

/**
 When the fullScreen maode did changed.
 */
- (void)videoPlayer:(ZFPlayerController *)videoPlayer orientationDidChanged:(ZFOrientationObserver *)observer;

#pragma mark - The network changed

/**
 When the network changed
 */
- (void)videoPlayer:(ZFPlayerController *)videoPlayer reachabilityChanged:(ZFReachabilityStatus)status;

#pragma mark - The video size changed

/**
 When the video size changed
 */
- (void)videoPlayer:(ZFPlayerController *)videoPlayer presentationSizeChanged:(CGSize)size;

#pragma mark - Gesture

/**
 When the gesture condition
 */
- (BOOL)gestureTriggerCondition:(ZFPlayerGestureControl *)gestureControl
                    gestureType:(ZFPlayerGestureType)gestureType
              gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
                          touch:(UITouch *)touch;

/**
 When the gesture single tapped
 */
- (void)gestureSingleTapped:(ZFPlayerGestureControl *)gestureControl;

/**
 When the gesture double tapped
 */
- (void)gestureDoubleTapped:(ZFPlayerGestureControl *)gestureControl;

/**
 When the gesture begin panGesture
 */
- (void)gestureBeganPan:(ZFPlayerGestureControl *)gestureControl
           panDirection:(ZFPanDirection)direction
            panLocation:(ZFPanLocation)location;

/**
 When the gesture paning
 */
- (void)gestureChangedPan:(ZFPlayerGestureControl *)gestureControl
             panDirection:(ZFPanDirection)direction
              panLocation:(ZFPanLocation)location
             withVelocity:(CGPoint)velocity;

/**
 When the end panGesture
 */
- (void)gestureEndedPan:(ZFPlayerGestureControl *)gestureControl
           panDirection:(ZFPanDirection)direction
            panLocation:(ZFPanLocation)location;

/**
 When the pinchGesture changed
 */
- (void)gesturePinched:(ZFPlayerGestureControl *)gestureControl
                 scale:(float)scale;

#pragma mark - scrollview

/**
 When the player will appear in scrollView.
 */
- (void)playerWillAppearInScrollView:(ZFPlayerController *)videoPlayer;

/**
 When the player did appear in scrollView.
 */
- (void)playerDidAppearInScrollView:(ZFPlayerController *)videoPlayer;

/**
 When the player will disappear in scrollView.
 */
- (void)playerWillDisappearInScrollView:(ZFPlayerController *)videoPlayer;

/**
 When the player did disappear in scrollView.
 */
- (void)playerDidDisappearInScrollView:(ZFPlayerController *)videoPlayer;

/**
 When the player appearing in scrollView.
 */
- (void)playerAppearingInScrollView:(ZFPlayerController *)videoPlayer playerApperaPercent:(CGFloat)playerApperaPercent;

/**
 When the player disappearing in scrollView.
 */
- (void)playerDisappearingInScrollView:(ZFPlayerController *)videoPlayer playerDisapperaPercent:(CGFloat)playerDisapperaPercent;

/**
 When the small float view show.
 */
- (void)videoPlayer:(ZFPlayerController *)videoPlayer floatViewShow:(BOOL)show;

@end

NS_ASSUME_NONNULL_END

