























#import "UIView+ZFFrame.h"

@implementation UIView (ZFFrame)

- (CGFloat)zf_x {
    return self.frame.origin.x;
}

- (void)setZf_x:(CGFloat)zf_x {
    CGRect newFrame   = self.frame;
    newFrame.origin.x = zf_x;
    self.frame        = newFrame;
}

- (CGFloat)zf_y {
    return self.frame.origin.y;
}

- (void)setZf_y:(CGFloat)zf_y {
    CGRect newFrame   = self.frame;
    newFrame.origin.y = zf_y;
    self.frame        = newFrame;
}

- (CGFloat)zf_width {
    return CGRectGetWidth(self.bounds);
}

- (void)setZf_width:(CGFloat)zf_width {
    CGRect newFrame     = self.frame;
    newFrame.size.width = zf_width;
    self.frame          = newFrame;
}

- (CGFloat)zf_height {
    return CGRectGetHeight(self.bounds);
}

- (void)setZf_height:(CGFloat)zf_height {
    CGRect newFrame      = self.frame;
    newFrame.size.height = zf_height;
    self.frame           = newFrame;
}

- (CGFloat)zf_top {
    return self.frame.origin.y;
}

- (void)setZf_top:(CGFloat)zf_top {
    CGRect newFrame   = self.frame;
    newFrame.origin.y = zf_top;
    self.frame        = newFrame;
}

- (CGFloat)zf_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setZf_bottom:(CGFloat)zf_bottom {
    CGRect newFrame   = self.frame;
    newFrame.origin.y = zf_bottom - self.frame.size.height;
    self.frame        = newFrame;
}

- (CGFloat)zf_left {
    return self.frame.origin.x;
}

- (void)setZf_left:(CGFloat)zf_left {
    CGRect newFrame   = self.frame;
    newFrame.origin.x = zf_left;
    self.frame        = newFrame;
}

- (CGFloat)zf_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setZf_right:(CGFloat)zf_right {
    CGRect newFrame   = self.frame;
    newFrame.origin.x = zf_right - self.frame.size.width;
    self.frame        = newFrame;
}

- (CGFloat)zf_centerX {
    return self.center.x;
}

- (void)setZf_centerX:(CGFloat)zf_centerX {
    CGPoint newCenter = self.center;
    newCenter.x       = zf_centerX;
    self.center       = newCenter;
}

- (CGFloat)zf_centerY {
    return self.center.y;
}

- (void)setZf_centerY:(CGFloat)zf_centerY {
    CGPoint newCenter = self.center;
    newCenter.y       = zf_centerY;
    self.center       = newCenter;
}

- (CGPoint)zf_origin {
    return self.frame.origin;
}

- (void)setZf_origin:(CGPoint)zf_origin {
    CGRect newFrame = self.frame;
    newFrame.origin = zf_origin;
    self.frame      = newFrame;
}

- (CGSize)zf_size {
    return self.frame.size;
}

- (void)setZf_size:(CGSize)zf_size {
    CGRect newFrame = self.frame;
    newFrame.size   = zf_size;
    self.frame      = newFrame;
}

@end
