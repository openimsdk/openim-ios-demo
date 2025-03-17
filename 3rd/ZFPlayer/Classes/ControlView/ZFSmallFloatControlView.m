























#import "ZFSmallFloatControlView.h"
#import "ZFUtilities.h"

@interface ZFSmallFloatControlView ()

@property (nonatomic, strong) UIButton *closeBtn;

@end

@implementation ZFSmallFloatControlView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.closeBtn];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat min_x = 0;
    CGFloat min_y = 0;
    CGFloat min_w = 0;
    CGFloat min_h = 0;
    CGFloat min_view_w = self.bounds.size.width;
    
    min_x = min_view_w-20;
    min_y = -10;
    min_w = 30;
    min_h = min_w;
    self.closeBtn.frame = CGRectMake(min_x, min_y, min_w, min_h);
}

- (void)closeBtnClick:(UIButton *)sender {
    if (self.closeClickCallback) self.closeClickCallback();
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:ZFPlayer_Image(@"ZFPlayer_close") forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

@end
