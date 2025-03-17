























#import <UIKit/UIKit.h>
@class ZFLandscapeViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol ZFLandscapeViewControllerDelegate <NSObject>
@optional
- (BOOL)ls_shouldAutorotate;
- (void)rotationFullscreenViewController:(ZFLandscapeViewController *)viewController viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;

@end

@interface ZFLandscapeViewController : UIViewController

@property (nonatomic, weak, nullable) id<ZFLandscapeViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL disableAnimations;

@property (nonatomic, assign) BOOL statusBarHidden;

@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;

@property (nonatomic, assign) UIStatusBarAnimation statusBarAnimation;

@end

NS_ASSUME_NONNULL_END
