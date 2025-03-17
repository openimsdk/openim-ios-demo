























#import "ZFLandscapeRotationManager.h"

@interface ZFLandscapeRotationManager ()  <ZFLandscapeViewControllerDelegate>

@end

@implementation ZFLandscapeRotationManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentOrientation = UIInterfaceOrientationPortrait;
    }
    return self;
}

- (void)updateRotateView:(ZFPlayerView *)rotateView
           containerView:(UIView *)containerView {
    self.contentView = rotateView;
    self.containerView = containerView;
}

- (UIInterfaceOrientation)getCurrentOrientation {
    if (@available(iOS 16.0, *)) {
        NSArray *array = [[[UIApplication sharedApplication] connectedScenes] allObjects];
        UIWindowScene *scene = [array firstObject];
        return scene.interfaceOrientation;
    } else {
        return (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    }
}

- (void)handleDeviceOrientationChange {
    if (!self.allowOrientationRotation || self.isLockedScreen) return;
    if (!UIDeviceOrientationIsValidInterfaceOrientation([UIDevice currentDevice].orientation)) {
        return;
    }
    UIInterfaceOrientation currentOrientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;

    if (currentOrientation == _currentOrientation) return;
    _currentOrientation = currentOrientation;
    if (currentOrientation == UIInterfaceOrientationPortraitUpsideDown) return;
    
    switch (currentOrientation) {
        case UIInterfaceOrientationPortrait: {
            if ([self _isSupportedPortrait]) {
                [self rotateToOrientation:UIInterfaceOrientationPortrait animated:YES];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
            if ([self _isSupportedLandscapeLeft]) {
                [self rotateToOrientation:UIInterfaceOrientationLandscapeLeft animated:YES];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeRight: {
            if ([self _isSupportedLandscapeRight]) {
                [self rotateToOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
            }
        }
            break;
        default: break;
    }
}

- (BOOL)isSuppprtInterfaceOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == UIInterfaceOrientationPortrait) {
        return [self _isSupportedPortrait];
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return [self _isSupportedLandscapeLeft];
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return [self _isSupportedLandscapeRight];
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return [self _isSupportedPortraitUpsideDown];
    }
    return NO;
}

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation completion:(void(^ __nullable)(void))completion {}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated {
    [self rotateToOrientation:orientation animated:animated completion:nil];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void(^ __nullable)(void))completion {
    _currentOrientation = orientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        if (!self.window) {
            self.window = [ZFLandscapeWindow new];
            self.landscapeViewController.delegate = self;
            self.window.rootViewController = self.landscapeViewController;
            self.window.rotationManager = self;
        }
    }
    self.disableAnimations = !animated;
    
    if ([UIDevice currentDevice].systemVersion.doubleValue < 16.0) {
        [self interfaceOrientation:UIInterfaceOrientationUnknown completion:nil];
    }
    [self interfaceOrientation:orientation completion:completion];
}

- (BOOL)_isSupportedPortrait {
    return self.supportInterfaceOrientation & ZFInterfaceOrientationMaskPortrait;
}

- (BOOL)_isSupportedPortraitUpsideDown {
    return self.supportInterfaceOrientation & ZFInterfaceOrientationMaskPortraitUpsideDown;
}

- (BOOL)_isSupportedLandscapeLeft {
    return self.supportInterfaceOrientation & ZFInterfaceOrientationMaskLandscapeLeft;
}

- (BOOL)_isSupportedLandscapeRight {
    return self.supportInterfaceOrientation & ZFInterfaceOrientationMaskLandscapeRight;
}

+ (ZFInterfaceOrientationMask)supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
    if ([window isKindOfClass:ZFLandscapeWindow.class]) {
        ZFLandscapeRotationManager *manager = ((ZFLandscapeWindow *)window).rotationManager;
        if (manager != nil) {
            return (ZFInterfaceOrientationMask)[manager supportedInterfaceOrientationsForWindow:window];
        }
    }
    return ZFInterfaceOrientationMaskUnknow;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
