
























#import <UIKit/UIKit.h>
#import "ZFOrientationObserver.h"

@interface ZFPersentInteractiveTransition : UIPercentDrivenInteractiveTransition

@property (nonatomic, weak) id<ZFPortraitOrientationDelegate> delagate;

@property (nonatomic, assign) BOOL interation;

@property (nonatomic, assign) ZFDisablePortraitGestureTypes disablePortraitGestureTypes;

@property (nonatomic, assign) BOOL fullScreenAnimation;

@property (nonatomic, assign) CGRect contentFullScreenRect;

@property (nonatomic, weak) UIViewController *viewController;

- (void)updateContentView:(UIView *)contenView
            containerView:(UIView *)containerView;

@end
