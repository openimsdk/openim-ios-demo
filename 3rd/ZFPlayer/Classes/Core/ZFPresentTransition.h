























#import <UIKit/UIKit.h>
#import "ZFOrientationObserver.h"

typedef NS_ENUM(NSUInteger, ZFPresentTransitionType) {
    ZFPresentTransitionTypePresent,
    ZFPresentTransitionTypeDismiss,
};

@interface ZFPresentTransition : NSObject<UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) id<ZFPortraitOrientationDelegate> delagate;

@property (nonatomic, assign) CGRect contentFullScreenRect;

@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

@property (nonatomic, assign) BOOL interation;

@property (nonatomic, assign) NSTimeInterval duration;

- (void)transitionWithTransitionType:(ZFPresentTransitionType)type
                         contentView:(UIView *)contentView
                       containerView:(UIView *)containerView;

@end
