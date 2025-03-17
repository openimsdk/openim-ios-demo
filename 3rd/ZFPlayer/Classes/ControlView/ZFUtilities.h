























#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? ((NSInteger)(([[UIScreen mainScreen] currentMode].size.height/[[UIScreen mainScreen] currentMode].size.width)*100) == 216) : NO)

#define ZFPlayer_Image(file)                 [ZFUtilities imageNamed:file]

#define ZFPlayer_ScreenWidth                 [[UIScreen mainScreen] bounds].size.width

#define ZFPlayer_ScreenHeight                [[UIScreen mainScreen] bounds].size.height

#define UIColorFromHex(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface ZFUtilities : NSObject

+ (NSString *)convertTimeSecond:(NSInteger)timeSecond;

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

+ (UIImage *)imageNamed:(NSString *)name;

@end

