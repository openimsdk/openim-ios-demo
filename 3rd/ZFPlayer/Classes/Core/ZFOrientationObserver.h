























#import <UIKit/UIKit.h>
#import "ZFPlayerView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZFFullScreenMode) {
    ZFFullScreenModeAutomatic,  // Determine full screen mode automatically
    ZFFullScreenModeLandscape,  // Landscape full screen mode
    ZFFullScreenModePortrait    // Portrait full screen Model
};

typedef NS_ENUM(NSUInteger, ZFPortraitFullScreenMode) {
    ZFPortraitFullScreenModeScaleToFill,    // Full fill
    ZFPortraitFullScreenModeScaleAspectFit  // contents scaled to fit with fixed aspect. remainder is transparent
};

typedef NS_ENUM(NSUInteger, ZFRotateType) {
    ZFRotateTypeNormal,         // Normal
    ZFRotateTypeCell            // Cell
};

/**
 Rotation of support direction
 */
typedef NS_OPTIONS(NSUInteger, ZFInterfaceOrientationMask) {
    ZFInterfaceOrientationMaskUnknow = 0,
    ZFInterfaceOrientationMaskPortrait = (1 << 0),
    ZFInterfaceOrientationMaskLandscapeLeft = (1 << 1),
    ZFInterfaceOrientationMaskLandscapeRight = (1 << 2),
    ZFInterfaceOrientationMaskPortraitUpsideDown = (1 << 3),
    ZFInterfaceOrientationMaskLandscape = (ZFInterfaceOrientationMaskLandscapeLeft | ZFInterfaceOrientationMaskLandscapeRight),
    ZFInterfaceOrientationMaskAll = (ZFInterfaceOrientationMaskPortrait | ZFInterfaceOrientationMaskLandscape | ZFInterfaceOrientationMaskPortraitUpsideDown),
    ZFInterfaceOrientationMaskAllButUpsideDown = (ZFInterfaceOrientationMaskPortrait | ZFInterfaceOrientationMaskLandscape),
};

typedef NS_OPTIONS(NSUInteger, ZFDisablePortraitGestureTypes) {
    ZFDisablePortraitGestureTypesNone         = 0,
    ZFDisablePortraitGestureTypesTap          = 1 << 0,
    ZFDisablePortraitGestureTypesPan          = 1 << 1,
    ZFDisablePortraitGestureTypesAll          = (ZFDisablePortraitGestureTypesTap | ZFDisablePortraitGestureTypesPan)
};

@protocol ZFPortraitOrientationDelegate <NSObject>

- (void)zf_orientationWillChange:(BOOL)isFullScreen;

- (void)zf_orientationDidChanged:(BOOL)isFullScreen;

- (void)zf_interationState:(BOOL)isDragging;

@end

@interface ZFOrientationObserver : NSObject

- (void)updateRotateView:(ZFPlayerView *)rotateView
           containerView:(UIView *)containerView;

@property (nonatomic, strong, readonly, nullable) UIView *fullScreenContainerView;

@property (nonatomic, weak) UIView *containerView;

@property (nonatomic, copy, nullable) void(^orientationWillChange)(ZFOrientationObserver *observer, BOOL isFullScreen);

@property (nonatomic, copy, nullable) void(^orientationDidChanged)(ZFOrientationObserver *observer, BOOL isFullScreen);

@property (nonatomic) ZFFullScreenMode fullScreenMode;

@property (nonatomic, assign) ZFPortraitFullScreenMode portraitFullScreenMode;

@property (nonatomic) NSTimeInterval duration;

@property (nonatomic, readonly, getter=isFullScreen) BOOL fullScreen;

@property (nonatomic, getter=isLockedScreen) BOOL lockedScreen;

@property (nonatomic, assign) BOOL fullScreenStatusBarHidden;

@property (nonatomic, assign) UIStatusBarStyle fullScreenStatusBarStyle;

@property (nonatomic, assign) UIStatusBarAnimation fullScreenStatusBarAnimation;

@property (nonatomic, assign) CGSize presentationSize;

@property (nonatomic, assign) ZFDisablePortraitGestureTypes disablePortraitGestureTypes;


@property (nonatomic, readonly) UIInterfaceOrientation currentOrientation;


@property (nonatomic, assign) BOOL allowOrientationRotation;

@property (nonatomic, assign) ZFInterfaceOrientationMask supportInterfaceOrientation;

- (void)addDeviceOrientationObserver;

- (void)removeDeviceOrientationObserver;

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void(^ __nullable)(void))completion;

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void(^ __nullable)(void))completion;

- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END


