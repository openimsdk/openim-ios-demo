
#import <UIKit/UIKit.h>

extern const NSUInteger SCIndexViewInvalidSection;
extern const NSInteger SCIndexViewSearchSection;

typedef NS_ENUM(NSUInteger, SCIndexViewStyle) {
    SCIndexViewStyleDefault = 0,    
    SCIndexViewStyleCenterToast,    
};

@interface SCIndexViewConfiguration : NSObject

@property (nonatomic, assign, readonly) SCIndexViewStyle indexViewStyle;    

@property (nonatomic, strong) UIColor *indicatorBackgroundColor;            
@property (nonatomic, strong) UIColor *indicatorTextColor;                  
@property (nonatomic, strong) UIFont *indicatorTextFont;                    
@property (nonatomic, assign) CGFloat indicatorHeight;                      
@property (nonatomic, assign) CGFloat indicatorRightMargin;                 
@property (nonatomic, assign) CGFloat indicatorCornerRadius;                
@property (nonatomic, assign) CGFloat indicatorCenterYOffset;               

@property (nonatomic, strong) UIColor *indexItemBackgroundColor;            
@property (nonatomic, strong) UIColor *indexItemTextColor;                  
@property (nonatomic, strong) UIFont *indexItemTextFont;                    
@property (nonatomic, strong) UIColor *indexItemSelectedBackgroundColor;    
@property (nonatomic, strong) UIColor *indexItemSelectedTextColor;          
@property (nonatomic, strong) UIFont *indexItemSelectedTextFont;            
@property (nonatomic, assign) CGFloat indexItemHeight;                      
@property (nonatomic, assign) CGFloat indexItemRightMargin;                 
@property (nonatomic, assign) CGFloat indexItemsSpace;                      

+ (instancetype)configuration;

+ (instancetype)configurationWithIndexViewStyle:(SCIndexViewStyle)indexViewStyle;

@end
