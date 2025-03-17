























#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZFPlayerMediaPlayback.h"
#import "ZFOrientationObserver.h"
#import "ZFPlayerMediaControl.h"
#import "ZFPlayerGestureControl.h"
#import "ZFPlayerNotification.h"
#import "ZFFloatView.h"
#import "UIScrollView+ZFPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZFPlayerController : NSObject

@property (nonatomic, weak, nullable) UIView *containerView;

@property (nonatomic, strong) id<ZFPlayerMediaPlayback> currentPlayerManager;

@property (nonatomic, strong, nullable) UIView<ZFPlayerMediaControl> *controlView;

@property (nonatomic, strong, readonly, nullable) ZFPlayerNotification *notification;

@property (nonatomic, assign, readonly) ZFPlayerContainerType containerType;

@property (nonatomic, strong, readonly, nullable) ZFFloatView *smallFloatView;

@property (nonatomic, assign, readonly) BOOL isSmallFloatViewShow;

@property (nonatomic, weak, nullable) UIScrollView *scrollView;
/*!
 @method            playerWithPlayerManager:containerView:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerView to see the video frames must set the contrainerView.
 @result            An instance of ZFPlayerController.
 */
+ (instancetype)playerWithPlayerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

/*!
 @method            initWithPlayerManager:containerView:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerView to see the video frames must set the contrainerView.
 @result            An instance of ZFPlayerController.
 */
- (instancetype)initWithPlayerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

/*!
 @method            playerWithScrollView:playerManager:containerViewTag:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item. Use in `UITableView` or `UICollectionView`.
 @param             scrollView is `tableView` or `collectionView`.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerViewTag to see the video at scrollView must set the contrainerViewTag.
 @result            An instance of ZFPlayerController.
 */
+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag;

/*!
 @method            initWithScrollView:playerManager:containerViewTag:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item. Use in `UITableView` or `UICollectionView`.
 @param             scrollView is `tableView` or `collectionView`.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerViewTag to see the video at scrollView must set the contrainerViewTag.
 @result            An instance of ZFPlayerController.
 */
- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag;

/*!
 @method            playerWithScrollView:playerManager:containerView:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item. Use in `UIScrollView`.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerView to see the video at the scrollView.
 @result            An instance of ZFPlayerController.
 */
+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

/*!
 @method            initWithScrollView:playerManager:containerView:
 @abstract          Create an ZFPlayerController that plays a single audiovisual item. Use in `UIScrollView`.
 @param             playerManager must conform `ZFPlayerMediaPlayback` protocol.
 @param             containerView to see the video at the scrollView.
 @result            An instance of ZFPlayerController.
 */
- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<ZFPlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

@end

@interface ZFPlayerController (ZFPlayerTimeControl)

@property (nonatomic, readonly) NSTimeInterval currentTime;

@property (nonatomic, readonly) NSTimeInterval totalTime;

@property (nonatomic, readonly) NSTimeInterval bufferTime;

@property (nonatomic, readonly) float progress;

@property (nonatomic, readonly) float bufferProgress;

/**
 Use this method to seek to a specified time for the current player and to be notified when the seek operation is complete.

 @param time seek time.
 @param completionHandler completion handler.
 */
- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler;

@end

@interface ZFPlayerController (ZFPlayerPlaybackControl)


@property (nonatomic, assign) BOOL resumePlayRecord;



@property (nonatomic) float volume;



@property (nonatomic, getter=isMuted) BOOL muted;

@property (nonatomic) float brightness;

@property (nonatomic, nullable) NSURL *assetURL;



@property (nonatomic, copy, nullable) NSArray <NSURL *>*assetURLs;

@property (nonatomic) NSInteger currentPlayIndex;

@property (nonatomic, readonly) BOOL isLastAssetURL;

@property (nonatomic, readonly) BOOL isFirstAssetURL;


@property (nonatomic) BOOL pauseWhenAppResignActive;


@property (nonatomic, getter=isPauseByEvent) BOOL pauseByEvent;

@property (nonatomic, getter=isViewControllerDisappear) BOOL viewControllerDisappear;


@property (nonatomic, assign) BOOL customAudioSession;

@property (nonatomic, copy, nullable) void(^playerPrepareToPlay)(id<ZFPlayerMediaPlayback> asset, NSURL *assetURL);

@property (nonatomic, copy, nullable) void(^playerReadyToPlay)(id<ZFPlayerMediaPlayback> asset, NSURL *assetURL);

@property (nonatomic, copy, nullable) void(^playerPlayTimeChanged)(id<ZFPlayerMediaPlayback> asset, NSTimeInterval currentTime, NSTimeInterval duration);

@property (nonatomic, copy, nullable) void(^playerBufferTimeChanged)(id<ZFPlayerMediaPlayback> asset, NSTimeInterval bufferTime);

@property (nonatomic, copy, nullable) void(^playerPlayStateChanged)(id<ZFPlayerMediaPlayback> asset, ZFPlayerPlaybackState playState);

@property (nonatomic, copy, nullable) void(^playerLoadStateChanged)(id<ZFPlayerMediaPlayback> asset, ZFPlayerLoadState loadState);

@property (nonatomic, copy, nullable) void(^playerPlayFailed)(id<ZFPlayerMediaPlayback> asset, id error);

@property (nonatomic, copy, nullable) void(^playerDidToEnd)(id<ZFPlayerMediaPlayback> asset);

@property (nonatomic, copy, nullable) void(^presentationSizeChanged)(id<ZFPlayerMediaPlayback> asset, CGSize size);

/**
 Play the next url ,while the `assetURLs` is not NULL.
 */
- (void)playTheNext;

/**
  Play the previous url ,while the `assetURLs` is not NULL.
 */
- (void)playThePrevious;

/**
 Play the index of url ,while the `assetURLs` is not NULL.

 @param index play the index.
 */
- (void)playTheIndex:(NSInteger)index;

/**
 Player stop and playerView remove from super view,remove other notification.
 */
- (void)stop;

/*!
 @method           replaceCurrentPlayerManager:
 @abstract         Replaces the player's current playeranager with the specified player item.
 @param            manager must conform `ZFPlayerMediaPlayback` protocol
 @discussion       The playerManager that will become the player's current playeranager.
 */
- (void)replaceCurrentPlayerManager:(id<ZFPlayerMediaPlayback>)manager;

/**
 Add video to cell.
 */
- (void)addPlayerViewToCell;

/**
 Add video to container view.
 */
- (void)addPlayerViewToContainerView:(UIView *)containerView;

/**
 Add to small float view.
 */
- (void)addPlayerViewToSmallFloatView;

/**
 Stop the current playing video and remove the playerView.
 */
- (void)stopCurrentPlayingView;

/**
 stop the current playing video on cell.
 */
- (void)stopCurrentPlayingCell;

@end

@interface ZFPlayerController (ZFPlayerOrientationRotation)

@property (nonatomic, readonly) ZFOrientationObserver *orientationObserver;



@property (nonatomic, readonly) BOOL shouldAutorotate;


@property (nonatomic) BOOL allowOrentitaionRotation;


@property (nonatomic, readonly) BOOL isFullScreen;

@property (nonatomic, assign) BOOL exitFullScreenWhenStop;

@property (nonatomic, getter=isLockedScreen) BOOL lockedScreen;

@property (nonatomic, copy, nullable) void(^orientationWillChange)(ZFPlayerController *player, BOOL isFullScreen);

@property (nonatomic, copy, nullable) void(^orientationDidChanged)(ZFPlayerController *player, BOOL isFullScreen);

@property (nonatomic, assign) UIStatusBarStyle fullScreenStatusBarStyle;

@property (nonatomic, assign) UIStatusBarAnimation fullScreenStatusBarAnimation;

@property (nonatomic, getter=isStatusBarHidden) BOOL statusBarHidden;

/**
 Add the device orientation observer.
 */
- (void)addDeviceOrientationObserver;

/**
 Remove the device orientation observer.
 */
- (void)removeDeviceOrientationObserver;

/**
 Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModeLandscape.

 @param orientation is UIInterfaceOrientation.
 @param animated is animated.
*/
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;

/**
 Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModeLandscape.

 @param orientation is UIInterfaceOrientation.
 @param animated is animated.
 @param completion rotating completed callback.
*/
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void(^ __nullable)(void))completion;

/**
 Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModePortrait.

 @param fullScreen is fullscreen.
 @param animated is animated.
 @param completion rotating completed callback.
 */
- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void(^ __nullable)(void))completion;

/**
 Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModePortrait.

 @param fullScreen is fullscreen.
 @param animated is animated.
 */
- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

/**
 FullScreen mode is determined by ZFFullScreenMode.

 @param fullScreen is fullscreen.
 @param animated is animated.
 @param completion rotating completed callback.
 */
- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void(^ __nullable)(void))completion;

/**
 FullScreen mode is determined by ZFFullScreenMode.

 @param fullScreen is fullscreen.
 @param animated is animated.
 */
- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

@end

@interface ZFPlayerController (ZFPlayerViewGesture)

@property (nonatomic, readonly) ZFPlayerGestureControl *gestureControl;

@property (nonatomic, assign) ZFPlayerDisableGestureTypes disableGestureTypes;

@property (nonatomic) ZFPlayerDisablePanMovingDirection disablePanMovingDirection;

@end

@interface ZFPlayerController (ZFPlayerScrollView)

@property (nonatomic) BOOL shouldAutoPlay;

@property (nonatomic, getter=isWWANAutoPlay) BOOL WWANAutoPlay;

@property (nonatomic, readonly, nullable) NSIndexPath *playingIndexPath;

@property (nonatomic, readonly, nullable) NSIndexPath *shouldPlayIndexPath;

@property (nonatomic, readonly) NSInteger containerViewTag;

@property (nonatomic) BOOL stopWhileNotVisible;

/**
 The current player scroll slides off the screen percent.
 the property used when the `stopWhileNotVisible` is YES, stop the current playing player.
 the property used when the `stopWhileNotVisible` is NO, the current playing player add to small container view.
 The range is 0.0~1.0, defalut is 0.5.
 0.0 is the player will disappear.
 1.0 is the player did disappear.
 */
@property (nonatomic) CGFloat playerDisapperaPercent;

/**
 The current player scroll to the screen percent to play the video.
 The range is 0.0~1.0, defalut is 0.0.
 0.0 is the player will appear.
 1.0 is the player did appear.
 */
@property (nonatomic) CGFloat playerApperaPercent;

@property (nonatomic, copy, nullable) NSArray <NSArray <NSURL *>*>*sectionAssetURLs;

@property (nonatomic, copy, nullable) void(^zf_playerAppearingInScrollView)(NSIndexPath *indexPath, CGFloat playerApperaPercent);

@property (nonatomic, copy, nullable) void(^zf_playerDisappearingInScrollView)(NSIndexPath *indexPath, CGFloat playerDisapperaPercent);

@property (nonatomic, copy, nullable) void(^zf_playerWillAppearInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_playerDidAppearInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_playerWillDisappearInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_playerDidDisappearInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_playerShouldPlayInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_scrollViewDidEndScrollingCallback)(NSIndexPath *indexPath);

- (void)zf_filterShouldPlayCellWhileScrolled:(void (^ __nullable)(NSIndexPath *indexPath))handler;

- (void)zf_filterShouldPlayCellWhileScrolling:(void (^ __nullable)(NSIndexPath *indexPath))handler;

/**
 Play the indexPath of url without scroll postion,  while the `assetURLs` or `sectionAssetURLs` is not NULL.
 
 @param indexPath Play the indexPath of url.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath;

/**
 Play the indexPath of url, while the `assetURLs` or `sectionAssetURLs` is not NULL.

 @param indexPath Play the indexPath of url.
 @param scrollPosition scroll position.
 @param animated scroll animation.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath
          scrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated;

/**
 Play the indexPath of url with scroll postion, while the `assetURLs` or `sectionAssetURLs` is not NULL.
 
 @param indexPath Play the indexPath of url.
 @param scrollPosition scroll position.
 @param animated scroll animation.
 @param completionHandler Scroll completion callback.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath
          scrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated
       completionHandler:(void (^ __nullable)(void))completionHandler;


/**
 Play the indexPath of url with scroll postion.
 
 @param indexPath Play the indexPath of url
 @param assetURL The player URL.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath assetURL:(NSURL *)assetURL;


/**
 Play the indexPath of url with scroll postion.
 
 @param indexPath Play the indexPath of url
 @param assetURL The player URL.
 @param scrollPosition  scroll position.
 @param animated scroll animation.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath
                assetURL:(NSURL *)assetURL
          scrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated;

/**
 Play the indexPath of url with scroll postion.
 
 @param indexPath Play the indexPath of url
 @param assetURL The player URL.
 @param scrollPosition  scroll position.
 @param animated scroll animation.
 @param completionHandler Scroll completion callback.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath
                assetURL:(NSURL *)assetURL
          scrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated
       completionHandler:(void (^ __nullable)(void))completionHandler;


@end

@interface ZFPlayerController (ZFPlayerDeprecated)

/**
 Add the playerView to cell.
 */
- (void)updateScrollViewPlayerToCell  __attribute__((deprecated("use `addPlayerViewToCell:` instead.")));

/**
 Add the playerView to containerView.
 
 @param containerView The playerView containerView.
 */
- (void)updateNoramlPlayerWithContainerView:(UIView *)containerView __attribute__((deprecated("use `addPlayerViewToContainerView:` instead.")));

/**
 Play the indexPath of url ,while the `assetURLs` or `sectionAssetURLs` is not NULL.
 
 @param indexPath Play the indexPath of url
 @param scrollToTop Scroll the current cell to top with animations.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop  __attribute__((deprecated("use `playTheIndexPath:scrollPosition:animated:` instead.")));

/**
 Play the indexPath of url with scroll postion.
 
 @param indexPath Play the indexPath of url
 @param assetURL The player URL.
 @param scrollToTop Scroll the current cell to top with animations.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath assetURL:(NSURL *)assetURL scrollToTop:(BOOL)scrollToTop  __attribute__((deprecated("use `playTheIndexPath:assetURL:scrollPosition:animated:` instead.")));

/**
 Play the indexPath of url ,while the `assetURLs` or `sectionAssetURLs` is not NULL.
 
 @param indexPath Play the indexPath of url
 @param scrollToTop scroll the current cell to top with animations.
 @param completionHandler Scroll completion callback.
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop completionHandler:(void (^ __nullable)(void))completionHandler  __attribute__((deprecated("use `playTheIndexPath:scrollPosition:animated:completionHandler:` instead.")));

/**
 Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModeLandscape.

 @param orientation UIInterfaceOrientation
 @param animated is animated.
 @param completion rotating completed callback.
 */
- (void)enterLandscapeFullScreen:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void(^ __nullable)(void))completion __attribute__((deprecated("use `rotateToOrientation:animated:completion:` instead.")));

/**
 Enter the fullScreen while the ZFFullScreenMode is ZFFullScreenModeLandscape.

 @param orientation UIInterfaceOrientation
 @param animated is animated.
 */
- (void)enterLandscapeFullScreen:(UIInterfaceOrientation)orientation animated:(BOOL)animated __attribute__((deprecated("use `rotateToOrientation:animated:` instead.")));

/**
 Add to the keyWindow.
 */
- (void)addPlayerViewToKeyWindow __attribute__((deprecated("use `addPlayerViewToSmallFloatView` instead.")));;

@end

NS_ASSUME_NONNULL_END
