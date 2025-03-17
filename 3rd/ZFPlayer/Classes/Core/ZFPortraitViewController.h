























#import <UIKit/UIKit.h>
#import "ZFOrientationObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZFPortraitViewController : UIViewController

@property (nonatomic, copy, nullable) void(^orientationWillChange)(BOOL isFullScreen);

@property (nonatomic, copy, nullable) void(^orientationDidChanged)(BOOL isFullScreen);

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, assign) BOOL statusBarHidden;

@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;

@property (nonatomic, assign) UIStatusBarAnimation statusBarAnimation;

@property (nonatomic, assign) ZFDisablePortraitGestureTypes disablePortraitGestureTypes;

@property (nonatomic, assign) CGSize presentationSize;

@property (nonatomic, assign) BOOL fullScreenAnimation;

@property (nonatomic, assign) NSTimeInterval duration;

@end

NS_ASSUME_NONNULL_END
