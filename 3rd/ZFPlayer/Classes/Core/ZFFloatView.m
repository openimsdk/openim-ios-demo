























#import "ZFFloatView.h"

@implementation ZFFloatView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initilize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initilize];
    }
    return self;
}

- (void)initilize {
    self.safeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(doMoveAction:)];
    [self addGestureRecognizer:panGestureRecognizer];
}

- (void)setParentView:(UIView *)parentView {
    _parentView = parentView;
    [parentView addSubview:self];
}

#pragma mark - Action

- (void)doMoveAction:(UIPanGestureRecognizer *)recognizer {

    CGPoint translation = [recognizer translationInView:self.parentView];
    CGPoint newCenter = CGPointMake(recognizer.view.center.x + translation.x,
                                    recognizer.view.center.y + translation.y);


    newCenter.y = MAX(recognizer.view.frame.size.height/2 + self.safeInsets.top, newCenter.y);

    newCenter.y = MIN(self.parentView.frame.size.height - self.safeInsets.bottom - recognizer.view.frame.size.height/2, newCenter.y);

    newCenter.x = MAX(recognizer.view.frame.size.width/2, newCenter.x);

    newCenter.x = MIN(self.parentView.frame.size.width - recognizer.view.frame.size.width/2,newCenter.x);

    recognizer.view.center = newCenter;

    [recognizer setTranslation:CGPointZero inView:self.parentView];
}


@end
