























#import <UIKit/UIKit.h>

@protocol ZFSliderViewDelegate <NSObject>

@optional

- (void)sliderTouchBegan:(float)value;

- (void)sliderValueChanged:(float)value;

- (void)sliderTouchEnded:(float)value;

- (void)sliderTapped:(float)value;

@end

@interface ZFSliderButton : UIButton

@end

@interface ZFSliderView : UIView

@property (nonatomic, weak) id<ZFSliderViewDelegate> delegate;

/** 滑块 */
@property (nonatomic, strong, readonly) ZFSliderButton *sliderBtn;

/** 默认滑杆的颜色 */
@property (nonatomic, strong) UIColor *maximumTrackTintColor;

/** 滑杆进度颜色 */
@property (nonatomic, strong) UIColor *minimumTrackTintColor;

/** 缓存进度颜色 */
@property (nonatomic, strong) UIColor *bufferTrackTintColor;

/** loading进度颜色 */
@property (nonatomic, strong) UIColor *loadingTintColor;

/** 默认滑杆的图片 */
@property (nonatomic, strong) UIImage *maximumTrackImage;

/** 滑杆进度的图片 */
@property (nonatomic, strong) UIImage *minimumTrackImage;

/** 缓存进度的图片 */
@property (nonatomic, strong) UIImage *bufferTrackImage;

/** 滑杆进度 */
@property (nonatomic, assign) float value;

/** 缓存进度 */
@property (nonatomic, assign) float bufferValue;

/** 是否允许点击，默认是YES */
@property (nonatomic, assign) BOOL allowTapped;

/** 是否允许点击，默认是YES */
@property (nonatomic, assign) BOOL animate;

/** 设置滑杆的高度 */
@property (nonatomic, assign) CGFloat sliderHeight;

/** 设置滑杆的圆角 */
@property (nonatomic, assign) CGFloat sliderRadius;

/** 是否隐藏滑块（默认为NO） */
@property (nonatomic, assign) BOOL isHideSliderBlock;

@property (nonatomic, assign) BOOL isdragging;

@property (nonatomic, assign) BOOL isForward;

@property (nonatomic, assign) CGSize thumbSize;

/**
 *  Starts animation of the spinner.
 */
- (void)startAnimating;

/**
 *  Stops animation of the spinnner.
 */
- (void)stopAnimating;

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state;

- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state;

@end
