























#import "ZFLandscapeViewController_iOS15.h"

@implementation ZFLandscapeViewController_iOS15

- (void)viewDidLoad {
    [super viewDidLoad];
    _playerSuperview = [[UIView alloc] initWithFrame:CGRectZero];
    _playerSuperview.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_playerSuperview];
}

- (BOOL)shouldAutorotate {
    return [self.delegate ls_shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

@end
