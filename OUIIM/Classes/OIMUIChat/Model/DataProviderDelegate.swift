
import OUICore

protocol DataProviderDelegate: AnyObject {

    func received(messages: [MessageInfo], forceReload: Bool)
    
    func isInGroup(with isIn: Bool)
        
    func groupMemberInfoChanged(info: GroupMemberInfo)
    
    func groupInfoChanged(info: GroupInfo)
            
    func friendInfoChanged(info: FriendInfo)
    
    func myUserInfoChanged(info: UserInfo)
    
    func groupMembersChanged(added: Bool, info: GroupMemberInfo)
    
    func unreadCountChanged(count: Int)
    
    func clearMessage()
    
    func conversationChanged(info: ConversationInfo)
}
