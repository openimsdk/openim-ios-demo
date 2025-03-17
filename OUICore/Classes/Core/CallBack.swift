import Foundation

public struct CallBack {
    public typealias StringOptionalReturnVoid = (String?) -> Void
    public typealias VoidReturnVoid = () -> Void
    public typealias BoolReturnVoid = (Bool) -> Void
    public typealias MessageReturnVoid = (MessageInfo) -> Void
    public typealias MessagesReturnVoid = ([MessageInfo]) -> Void
    public typealias UserInfoOptionalReturnVoid = (UserInfo?) -> Void
    public typealias UsersInfoOptionalReturnVoid = ([UserInfo]?) -> Void
    public typealias PublicUserInfosReturnVoid = ([PublicUserInfo]) -> Void
    public typealias GroupInfoOptionalReturnVoid = (GroupInfo?) -> Void
    public typealias GroupInfosReturnVoid = ([GroupInfo]) -> Void
    public typealias GroupSignalingInfoReturnVoid = (Bool, [UserInfo]) -> Void
    public typealias ConversationInfoOptionalReturnVoid = (ConversationInfo?) -> Void
    public typealias GroupMembersReturnVoid = ([GroupMemberInfo]) -> Void
    public typealias ProgressReturnVoid = (CGFloat) -> Void
    public typealias SearchResultInfoOptionalReturnVoid = (SearchResultInfo?) -> Void
    public typealias BlackListOptionalReturnVoid = ([BlackInfo]) -> Void
    public typealias SearchUsersInfoOptionalReturnVoid = ([SearchUserInfo]) -> Void
    public typealias ErrorOptionalReturnVoid = (_ errCode: Int, _ errMsg: String?) -> Void
    public typealias UserStatusInfoReturnVoid = ([UserStatusInfo]) -> Void
    public typealias InputStatusChangedReturnVoid = (InputStatusChangedData?) -> Void
    public typealias FriendsInfosReturnVoid = ([FriendInfo]) -> Void
}
