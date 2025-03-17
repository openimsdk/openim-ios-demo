























#import <UIKit/UIKit.h>
#import "ZFSliderView.h"
#if __has_include(<ZFPlayer/ZFPlayerController.h>)
#import <ZFPlayer/ZFPlayerController.h>
#else
#import "ZFPlayerController.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ZFPortraitControlView : UIView

@property (nonatomic, strong, readonly) UIView *bottomToolView;

@property (nonatomic, strong, readonly) UIView *topToolView;

@property (nonatomic, strong, readonly) UILabel *titleLabel;

@property (nonatomic, strong, readonly) UIButton *playOrPauseBtn;

@property (nonatomic, strong, readonly) UILabel *currentTimeLabel;

@property (nonatomic, strong, readonly) ZFSliderView *slider;

@property (nonatomic, strong, readonly) UILabel *totalTimeLabel;

@property (nonatomic, strong, readonly) UIButton *fullScreenBtn;

@property (nonatomic, weak) ZFPlayerController *player;

@property (nonatomic, copy, nullable) void(^sliderValueChanging)(CGFloat value,BOOL forward);

@property (nonatomic, copy, nullable) void(^sliderValueChanged)(CGFloat value);

@property (nonatomic, assign) BOOL seekToPlay;

@property (nonatomic, assign) ZFFullScreenMode fullScreenMode;

- (void)resetControlView;

- (void)showControlView;

- (void)hideControlView;

- (void)videoPlayer:(ZFPlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime;

- (void)videoPlayer:(ZFPlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime;

- (BOOL)shouldResponseGestureWithPoint:(CGPoint)point withGestureType:(ZFPlayerGestureType)type touch:(nonnull UITouch *)touch;

- (void)showTitle:(NSString *_Nullable)title fullScreenMode:(ZFFullScreenMode)fullScreenMode;

- (void)playOrPause;

- (void)playBtnSelectedState:(BOOL)selected;

- (void)sliderValueChanged:(CGFloat)value currentTimeString:(NSString *)timeString;

- (void)sliderChangeEnded;

@end

NS_ASSUME_NONNULL_END
