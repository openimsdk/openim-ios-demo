























#import <UIKit/UIKit.h>
#import "ZFPortraitControlView.h"
#import "ZFLandScapeControlView.h"
#import "ZFSpeedLoadingView.h"
#import "ZFSmallFloatControlView.h"
#if __has_include(<ZFPlayer/ZFPlayerMediaControl.h>)
#import <ZFPlayer/ZFPlayerMediaControl.h>
#else
#import "ZFPlayerMediaControl.h"
#endif

@interface ZFPlayerControlView : UIView <ZFPlayerMediaControl>

@property (nonatomic, strong, readonly) ZFPortraitControlView *portraitControlView;

@property (nonatomic, strong, readonly) ZFLandScapeControlView *landScapeControlView;

@property (nonatomic, strong, readonly) ZFSpeedLoadingView *activity;

@property (nonatomic, strong, readonly) UIView *fastView;

@property (nonatomic, strong, readonly) ZFSliderView *fastProgressView;

@property (nonatomic, strong, readonly) UILabel *fastTimeLabel;

@property (nonatomic, strong, readonly) UIImageView *fastImageView;

@property (nonatomic, strong, readonly) UIButton *failBtn;

@property (nonatomic, strong, readonly) ZFSliderView *bottomPgrogress;

@property (nonatomic, strong, readonly) UIImageView *coverImageView;

@property (nonatomic, strong, readonly) UIImageView *bgImgView;

@property (nonatomic, strong, readonly) UIView *effectView;

@property (nonatomic, strong, readonly) ZFSmallFloatControlView *floatControlView;

@property (nonatomic, assign) BOOL fastViewAnimated;

@property (nonatomic, assign) BOOL effectViewShow;

@property (nonatomic, assign) BOOL seekToPlay;

@property (nonatomic, copy) void(^backBtnClickCallback)(void);

@property (nonatomic, readonly) BOOL controlViewAppeared;

@property (nonatomic, copy) void(^controlViewAppearedCallback)(BOOL appeared);

@property (nonatomic, assign) NSTimeInterval autoHiddenTimeInterval;

@property (nonatomic, assign) NSTimeInterval autoFadeTimeInterval;

@property (nonatomic, assign) BOOL horizontalPanShowControlView;

@property (nonatomic, assign) BOOL prepareShowControlView;

@property (nonatomic, assign) BOOL prepareShowLoading;

@property (nonatomic, assign) BOOL customDisablePanMovingDirection;

@property (nonatomic, assign) BOOL showCustomStatusBar;

@property (nonatomic, assign) ZFFullScreenMode fullScreenMode;

/**
 设置标题、封面、全屏模式

 @param title 视频的标题
 @param coverUrl 视频的封面，占位图默认是灰色的
 @param fullScreenMode 全屏模式
 */
- (void)showTitle:(NSString *)title coverURLString:(NSString *)coverUrl fullScreenMode:(ZFFullScreenMode)fullScreenMode;

/**
 设置标题、封面、默认占位图、全屏模式

 @param title 视频的标题
 @param coverUrl 视频的封面
 @param placeholder 指定封面的placeholder
 @param fullScreenMode 全屏模式
 */
- (void)showTitle:(NSString *)title coverURLString:(NSString *)coverUrl placeholderImage:(UIImage *)placeholder fullScreenMode:(ZFFullScreenMode)fullScreenMode;

/**
 设置标题、UIImage封面、全屏模式

 @param title 视频的标题
 @param image 视频的封面UIImage
 @param fullScreenMode 全屏模式
 */
- (void)showTitle:(NSString *)title coverImage:(UIImage *)image fullScreenMode:(ZFFullScreenMode)fullScreenMode;


/**
 重置控制层
 */
- (void)resetControlView;

@end
