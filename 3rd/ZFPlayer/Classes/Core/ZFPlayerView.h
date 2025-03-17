























#import <UIKit/UIKit.h>
#import "ZFPlayerConst.h"

@interface ZFPlayerView : UIView

@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, assign) ZFPlayerScalingMode scalingMode;

@property (nonatomic, assign) CGSize presentationSize;

@property (nonatomic, strong, readonly) UIImageView *coverImageView;

@end
