






#import <UIKit/UIKit.h>
#import "ZFLoadingView.h"

@interface ZFSpeedLoadingView : UIView

@property (nonatomic, strong) ZFLoadingView *loadingView;

@property (nonatomic, strong) UILabel *speedTextLabel;

/**
 *  Starts animation of the spinner.
 */
- (void)startAnimating;

/**
 *  Stops animation of the spinnner.
 */
- (void)stopAnimating;

@end
