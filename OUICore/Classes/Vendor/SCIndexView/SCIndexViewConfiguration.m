
#import "SCIndexViewConfiguration.h"

const NSUInteger SCIndexViewInvalidSection = NSUIntegerMax - 1;
const NSInteger SCIndexViewSearchSection = -1;

static inline UIColor *SCGetColor(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha)
{
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
}

@interface SCIndexViewConfiguration ()

@property (nonatomic, assign) SCIndexViewStyle indexViewStyle;  

@end

@implementation SCIndexViewConfiguration

@synthesize indexViewStyle = _indexViewStyle;

+ (instancetype)configuration
{
    return [self configurationWithIndexViewStyle:SCIndexViewStyleDefault];
}

+ (instancetype)configurationWithIndexViewStyle:(SCIndexViewStyle)indexViewStyle
{
    UIColor *indicatorBackgroundColor, *indicatorTextColor;
    UIFont *indicatorTextFont;
    CGFloat indicatorHeight;
    switch (indexViewStyle) {
        case SCIndexViewStyleDefault:
        {
            indicatorBackgroundColor = SCGetColor(200, 200, 200, 1);
            indicatorTextColor = [UIColor whiteColor];
            indicatorTextFont = [UIFont systemFontOfSize:38];
            indicatorHeight = 50;
        }
            break;
            
        case SCIndexViewStyleCenterToast:
        {
            indicatorBackgroundColor = SCGetColor(200, 200, 200, 0.8);
            indicatorTextColor = [UIColor whiteColor];
            indicatorTextFont = [UIFont systemFontOfSize:60];
            indicatorHeight = 120;
        }
            break;
            
        default:
            return nil;
            break;
    }
    
    return [self configurationWithIndexViewStyle:indexViewStyle
                        indicatorBackgroundColor:indicatorBackgroundColor
                              indicatorTextColor:indicatorTextColor
                               indicatorTextFont:indicatorTextFont
                                 indicatorHeight:indicatorHeight
                            indicatorRightMargin:40
                           indicatorCornerRadius:10
                          indicatorCenterYOffset:0
                        indexItemBackgroundColor:[UIColor clearColor]
                              indexItemTextColor:[UIColor darkGrayColor]
                               indexItemTextFont:[UIFont fontWithName:@"Helvetica" size:12]
                indexItemSelectedBackgroundColor:SCGetColor(40, 170, 40, 1)
                      indexItemSelectedTextColor:[UIColor whiteColor]
                       indexItemSelectedTextFont:[UIFont fontWithName:@"Helvetica" size:12]
                                 indexItemHeight:15
                            indexItemRightMargin:5
                                 indexItemsSpace:0];
}

+ (instancetype)configurationWithIndexViewStyle:(SCIndexViewStyle)indexViewStyle
                       indicatorBackgroundColor:(UIColor *)indicatorBackgroundColor
                             indicatorTextColor:(UIColor *)indicatorTextColor
                              indicatorTextFont:(UIFont *)indicatorTextFont
                                indicatorHeight:(CGFloat)indicatorHeight
                           indicatorRightMargin:(CGFloat)indicatorRightMargin
                          indicatorCornerRadius:(CGFloat)indicatorCornerRadius
                         indicatorCenterYOffset:(CGFloat)indicatorCenterYOffset
                       indexItemBackgroundColor:(UIColor *)indexItemBackgroundColor
                             indexItemTextColor:(UIColor *)indexItemTextColor
                              indexItemTextFont:(UIFont *)indexItemTextFont
               indexItemSelectedBackgroundColor:(UIColor *)indexItemSelectedBackgroundColor
                     indexItemSelectedTextColor:(UIColor *)indexItemSelectedTextColor
                      indexItemSelectedTextFont:(UIFont *)indexItemSelectedTextFont
                                indexItemHeight:(CGFloat)indexItemHeight
                           indexItemRightMargin:(CGFloat)indexItemRightMargin
                                indexItemsSpace:(CGFloat)indexItemsSpace
{
    SCIndexViewConfiguration *configuration = [self new];
    if (!configuration) return nil;
    
    configuration.indexViewStyle = indexViewStyle;
    configuration.indicatorBackgroundColor = indicatorBackgroundColor;
    configuration.indicatorTextColor = indicatorTextColor;
    configuration.indicatorTextFont = indicatorTextFont;
    configuration.indicatorHeight = indicatorHeight;
    configuration.indicatorRightMargin = indicatorRightMargin;
    configuration.indicatorCornerRadius = indicatorCornerRadius;
    configuration.indicatorCenterYOffset = indicatorCenterYOffset;
    
    configuration.indexItemBackgroundColor = indexItemBackgroundColor;
    configuration.indexItemTextColor = indexItemTextColor;
    configuration.indexItemTextFont = indexItemTextFont;
    configuration.indexItemSelectedBackgroundColor = indexItemSelectedBackgroundColor;
    configuration.indexItemSelectedTextColor = indexItemSelectedTextColor;
    configuration.indexItemSelectedTextFont = indexItemSelectedTextFont;
    configuration.indexItemHeight = indexItemHeight;
    configuration.indexItemRightMargin = indexItemRightMargin;
    configuration.indexItemsSpace = indexItemsSpace;
    
    return configuration;
}

@end
