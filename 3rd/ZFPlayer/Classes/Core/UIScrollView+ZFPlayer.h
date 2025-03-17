























#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * The scroll direction of scrollView.
 */
typedef NS_ENUM(NSUInteger, ZFPlayerScrollDirection) {
    ZFPlayerScrollDirectionNone,
    ZFPlayerScrollDirectionUp,         // Scroll up
    ZFPlayerScrollDirectionDown,       // Scroll Down
    ZFPlayerScrollDirectionLeft,       // Scroll left
    ZFPlayerScrollDirectionRight       // Scroll right
};

/*
 * The scrollView direction.
 */
typedef NS_ENUM(NSInteger, ZFPlayerScrollViewDirection) {
    ZFPlayerScrollViewDirectionVertical,
    ZFPlayerScrollViewDirectionHorizontal
};

/*
 * The player container type
 */
typedef NS_ENUM(NSInteger, ZFPlayerContainerType) {
    ZFPlayerContainerTypeView,
    ZFPlayerContainerTypeCell
};

typedef NS_ENUM(NSInteger , ZFPlayerScrollViewScrollPosition) {
    ZFPlayerScrollViewScrollPositionNone,

    ZFPlayerScrollViewScrollPositionTop,
    ZFPlayerScrollViewScrollPositionCenteredVertically,
    ZFPlayerScrollViewScrollPositionBottom,

    ZFPlayerScrollViewScrollPositionLeft,
    ZFPlayerScrollViewScrollPositionCenteredHorizontally,
    ZFPlayerScrollViewScrollPositionRight
};

@interface UIScrollView (ZFPlayer)

@property (nonatomic, readonly) CGFloat zf_lastOffsetY;

@property (nonatomic, readonly) CGFloat zf_lastOffsetX;

@property (nonatomic) ZFPlayerScrollViewDirection zf_scrollViewDirection;



@property (nonatomic, readonly) ZFPlayerScrollDirection zf_scrollDirection;

- (UIView *)zf_getCellForIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)zf_getIndexPathForCell:(UIView *)cell;

/**
Scroll to indexPath with position.
 
@param indexPath scroll the  indexPath.
@param scrollPosition  scrollView scroll position.
@param animated animate.
@param completionHandler  Scroll completion callback.
*/
- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath
                 atScrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                         animated:(BOOL)animated
                completionHandler:(void (^ __nullable)(void))completionHandler;

/**
Scroll to indexPath with position.
 
@param indexPath scroll the  indexPath.
@param scrollPosition  scrollView scroll position.
@param duration animate duration.
@param completionHandler  Scroll completion callback.
*/
- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath
                 atScrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                  animateDuration:(NSTimeInterval)duration
                completionHandler:(void (^ __nullable)(void))completionHandler;




- (void)zf_scrollViewDidEndDecelerating;

- (void)zf_scrollViewDidEndDraggingWillDecelerate:(BOOL)decelerate;

- (void)zf_scrollViewDidScrollToTop;

- (void)zf_scrollViewDidScroll;

- (void)zf_scrollViewWillBeginDragging;





@end

@interface UIScrollView (ZFPlayerCannotCalled)

@property (nonatomic, copy, nullable) void(^zf_playerAppearingInScrollView)(NSIndexPath *indexPath, CGFloat playerApperaPercent);

@property (nonatomic, copy, nullable) void(^zf_playerDisappearingInScrollView)(NSIndexPath *indexPath, CGFloat playerDisapperaPercent);

@property (nonatomic, copy, nullable) void(^zf_playerWillAppearInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_playerDidAppearInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_playerWillDisappearInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_playerDidDisappearInScrollView)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_scrollViewDidEndScrollingCallback)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_scrollViewDidScrollCallback)(NSIndexPath *indexPath);

@property (nonatomic, copy, nullable) void(^zf_playerShouldPlayInScrollView)(NSIndexPath *indexPath);






@property (nonatomic) CGFloat zf_playerDisapperaPercent;




@property (nonatomic) CGFloat zf_playerApperaPercent;

@property (nonatomic) BOOL zf_viewControllerDisappear;

@property (nonatomic, assign) BOOL zf_stopPlay;

@property (nonatomic, assign) BOOL zf_stopWhileNotVisible;

@property (nonatomic, nullable) NSIndexPath *zf_playingIndexPath;

@property (nonatomic, nullable) NSIndexPath *zf_shouldPlayIndexPath;

@property (nonatomic, getter=zf_isWWANAutoPlay) BOOL zf_WWANAutoPlay;

@property (nonatomic) BOOL zf_shouldAutoPlay;

@property (nonatomic) NSInteger zf_containerViewTag;

@property (nonatomic, strong) UIView *zf_containerView;

@property (nonatomic, assign) ZFPlayerContainerType zf_containerType;

- (void)zf_filterShouldPlayCellWhileScrolled:(void (^ __nullable)(NSIndexPath *indexPath))handler;

- (void)zf_filterShouldPlayCellWhileScrolling:(void (^ __nullable)(NSIndexPath *indexPath))handler;

@end

@interface UIScrollView (ZFPlayerDeprecated)

@property (nonatomic, copy, nullable) void(^zf_scrollViewDidStopScrollCallback)(NSIndexPath *indexPath) __attribute__((deprecated("use `ZFPlayerController.zf_scrollViewDidEndScrollingCallback` instead.")));

@property (nonatomic, copy, nullable) void(^zf_shouldPlayIndexPathCallback)(NSIndexPath *indexPath) __attribute__((deprecated("use `ZFPlayerController.zf_playerShouldPlayInScrollView` instead.")));

- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath
                completionHandler:(void (^ __nullable)(void))completionHandler __attribute__((deprecated("use `zf_scrollToRowAtIndexPath:atScrollPosition:animated:completionHandler:` instead.")));

- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath
                         animated:(BOOL)animated
                completionHandler:(void (^ __nullable)(void))completionHandler __attribute__((deprecated("use `zf_scrollToRowAtIndexPath:atScrollPosition:animated:completionHandler:` instead.")));

- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath
              animateWithDuration:(NSTimeInterval)duration
                completionHandler:(void (^ __nullable)(void))completionHandler __attribute__((deprecated("use `zf_scrollToRowAtIndexPath:atScrollPosition:animateDuration:completionHandler:` instead.")));

@end

NS_ASSUME_NONNULL_END
