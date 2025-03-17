






#import <Foundation/Foundation.h>
#import "OIMMessageInfo.h"
#import "OIMFullUserInfo.h"
#import "OIMDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface OIMInvitationInfo : NSObject

/**
 *  List of invitee UserIDs, with only one element in the case of a one-on-one chat.
 */
@property (nonatomic, copy) NSArray<NSString *> *inviteeUserIDList;

/**
 *  Room ID, must be unique.
 */
@property (nonatomic, copy) NSString *roomID;

/**
 *  Invitation timeout in seconds, default is 1000.
 */
@property (nonatomic, assign) NSInteger timeout;

/**
 *  Video or audio.
 */
@property (nonatomic, copy) NSString *mediaType;

/**
 *  1 for one-on-one chat, 2 for group chat.
 */
@property (nonatomic, assign) OIMConversationType sessionType;

@property (nonatomic, assign) OIMPlatform platformID;

/**
 *  Inviter's UserID.
 */
@property (nonatomic, copy) NSString *inviterUserID;

- (BOOL)isVideo;

@end

@interface OIMInvitationResultInfo : NSObject

/**
 *  Token.
 */
@property (nonatomic, copy) NSString *token;

/**
 *  Room ID, must be unique and can be left unset.
 */
@property (nonatomic, copy) NSString *roomID;

/**
 *  Live streaming URL.
 */
@property (nonatomic, copy) NSString *liveURL;

/**
 * List of occupied lines.
 */
@property (nonatomic, copy) NSArray<NSString *> *busyLineUserIDList;

@end

@interface OIMSignalingInfo : NSObject

@property (nonatomic, copy) NSString *userID;

@property (nonatomic, strong) OIMInvitationInfo *invitation;

@property (nonatomic, strong) OIMOfflinePushInfo *offlinePushInfo;

@end

@interface OIMParticipantMetaData : NSObject

@property (nonatomic, strong) OIMGroupInfo *groupInfo;

@property (nonatomic, strong) OIMGroupMemberInfo *groupMemberInfo;

@property (nonatomic, strong) OIMPublicUserInfo *publicUserInfo;

@property (nonatomic, strong) OIMPublicUserInfo *userInfo;

@end

@interface OIMParticipantConnectedInfo : NSObject

@property (nonatomic, copy) NSString *groupID;

@property (nonatomic, strong) OIMInvitationInfo *invitation;

@property (nonatomic, copy) NSArray<OIMParticipantMetaData *> *metaData;

@property (nonatomic, copy) NSArray<OIMParticipantMetaData *> *participant;

@property (nonatomic, copy) NSString *token;

@property (nonatomic, copy) NSString *roomID;

@property (nonatomic, copy) NSString *liveURL;

@end

NS_ASSUME_NONNULL_END
