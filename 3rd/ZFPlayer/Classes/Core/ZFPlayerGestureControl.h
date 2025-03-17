























#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZFPlayerGestureType) {
    ZFPlayerGestureTypeUnknown,
    ZFPlayerGestureTypeSingleTap,
    ZFPlayerGestureTypeDoubleTap,
    ZFPlayerGestureTypePan,
    ZFPlayerGestureTypePinch
};

typedef NS_ENUM(NSUInteger, ZFPanDirection) {
    ZFPanDirectionUnknown,
    ZFPanDirectionV,
    ZFPanDirectionH,
};

typedef NS_ENUM(NSUInteger, ZFPanLocation) {
    ZFPanLocationUnknown,
    ZFPanLocationLeft,
    ZFPanLocationRight,
};

typedef NS_ENUM(NSUInteger, ZFPanMovingDirection) {
    ZFPanMovingDirectionUnkown,
    ZFPanMovingDirectionTop,
    ZFPanMovingDirectionLeft,
    ZFPanMovingDirectionBottom,
    ZFPanMovingDirectionRight,
};

typedef NS_OPTIONS(NSUInteger, ZFPlayerDisableGestureTypes) {
    ZFPlayerDisableGestureTypesNone         = 0,
    ZFPlayerDisableGestureTypesSingleTap    = 1 << 0,
    ZFPlayerDisableGestureTypesDoubleTap    = 1 << 1,
    ZFPlayerDisableGestureTypesPan          = 1 << 2,
    ZFPlayerDisableGestureTypesPinch        = 1 << 3,
    ZFPlayerDisableGestureTypesAll          = (ZFPlayerDisableGestureTypesSingleTap | ZFPlayerDisableGestureTypesDoubleTap | ZFPlayerDisableGestureTypesPan | ZFPlayerDisableGestureTypesPinch)
};

typedef NS_OPTIONS(NSUInteger, ZFPlayerDisablePanMovingDirection) {
    ZFPlayerDisablePanMovingDirectionNone         = 0,       /// Not disable pan moving direction.
    ZFPlayerDisablePanMovingDirectionVertical     = 1 << 0,  /// Disable pan moving vertical direction.
    ZFPlayerDisablePanMovingDirectionHorizontal   = 1 << 1,  /// Disable pan moving horizontal direction.
    ZFPlayerDisablePanMovingDirectionAll          = (ZFPlayerDisablePanMovingDirectionVertical | ZFPlayerDisablePanMovingDirectionHorizontal)  /// Disable pan moving all direction.
};

@interface ZFPlayerGestureControl : NSObject

@property (nonatomic, copy, nullable) BOOL(^triggerCondition)(ZFPlayerGestureControl *control, ZFPlayerGestureType type, UIGestureRecognizer *gesture, UITouch *touch);

@property (nonatomic, copy, nullable) void(^singleTapped)(ZFPlayerGestureControl *control);

@property (nonatomic, copy, nullable) void(^doubleTapped)(ZFPlayerGestureControl *control);

@property (nonatomic, copy, nullable) void(^beganPan)(ZFPlayerGestureControl *control, ZFPanDirection direction, ZFPanLocation location);

@property (nonatomic, copy, nullable) void(^changedPan)(ZFPlayerGestureControl *control, ZFPanDirection direction, ZFPanLocation location, CGPoint velocity);

@property (nonatomic, copy, nullable) void(^endedPan)(ZFPlayerGestureControl *control, ZFPanDirection direction, ZFPanLocation location);

@property (nonatomic, copy, nullable) void(^pinched)(ZFPlayerGestureControl *control, float scale);

@property (nonatomic, strong, readonly) UITapGestureRecognizer *singleTap;

@property (nonatomic, strong, readonly) UITapGestureRecognizer *doubleTap;

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGR;

@property (nonatomic, strong, readonly) UIPinchGestureRecognizer *pinchGR;

@property (nonatomic, readonly) ZFPanDirection panDirection;

@property (nonatomic, readonly) ZFPanLocation panLocation;

@property (nonatomic, readonly) ZFPanMovingDirection panMovingDirection;

@property (nonatomic) ZFPlayerDisableGestureTypes disableTypes;

@property (nonatomic) ZFPlayerDisablePanMovingDirection disablePanMovingDirection;

/**
 Add  all gestures(singleTap、doubleTap、panGR、pinchGR) to the view.
 */
- (void)addGestureToView:(UIView *)view;

/**
 Remove all gestures(singleTap、doubleTap、panGR、pinchGR) form the view.
 */
- (void)removeGestureToView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
