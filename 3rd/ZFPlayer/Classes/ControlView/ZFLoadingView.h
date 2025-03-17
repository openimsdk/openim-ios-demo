























#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZFLoadingType) {
    ZFLoadingTypeKeep,
    ZFLoadingTypeFadeOut,
};

@interface ZFLoadingView : UIView

@property (nonatomic, assign) ZFLoadingType animType;

@property (nonatomic, strong, null_resettable) UIColor *lineColor;

@property (nonatomic) CGFloat lineWidth;

@property (nonatomic) BOOL hidesWhenStopped;

@property (nonatomic, readwrite) NSTimeInterval duration;

@property (nonatomic, assign, readonly, getter=isAnimating) BOOL animating;

/**
 *  Starts animation of the spinner.
 */
- (void)startAnimating;

/**
 *  Stops animation of the spinnner.
 */
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
