






#import "OIMSignalingInfo.h"
#import <MJExtension/MJExtension.h>

@implementation OIMInvitationInfo

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _timeout = 30;
        _platformID = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? iPad : iPhone;
    }
    
    return self;
}

- (BOOL)isVideo {
    return [self.mediaType isEqualToString:@"video"];
}
@end

@implementation OIMInvitationResultInfo
+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{@"liveURL": @"serverUrl"};
}
@end

@implementation OIMSignalingInfo

@end

@implementation OIMParticipantMetaData

@end

@implementation OIMParticipantConnectedInfo

+ (NSDictionary *)mj_objectClassInArray
{
    return @{@"metaData" : [OIMParticipantMetaData class],
             @"participant" : [OIMParticipantMetaData class]
    };
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    return @{@"liveURL": @"serverUrl"};
}
@end
