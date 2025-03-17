


























#import "ZFLandscapeViewController.h"

@implementation ZFLandscapeViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _statusBarStyle = UIStatusBarStyleLightContent;
        _statusBarAnimation = UIStatusBarAnimationSlide;
    }
    return self;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if ([self.delegate respondsToSelector:@selector(rotationFullscreenViewController:viewWillTransitionToSize:withTransitionCoordinator:)]) {
        [self.delegate rotationFullscreenViewController:self viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return self.statusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.statusBarStyle;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.statusBarAnimation;
}

@end

