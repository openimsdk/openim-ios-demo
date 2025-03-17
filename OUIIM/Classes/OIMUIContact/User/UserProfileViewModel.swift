
import OUICore
import RxSwift
import RxRelay

class UserProfileViewModel {
    let userId: String
    let groupId: String?
    
    let userInfoRelay: BehaviorRelay<UserInfo?> = .init(value: nil)
    let memberInfoRelay: PublishSubject<GroupMemberInfo?> = .init()
    let isInBlackListRelay: PublishSubject<Bool> = .init()
    let isFriendRelay: BehaviorSubject<Bool?> = .init(value: nil)
    
    init(userId: String, groupId: String?, isFriend: Bool? = nil) {
        self.userId = userId
        self.groupId = groupId
        isFriendRelay.onNext(isFriend)
    }
    
    var isMine: Bool {
        userId == IMController.shared.uid
    }
    
    func getUserOrMemberInfo() {
        if let groupId = groupId, groupId.isEmpty == false {
            let u = UserCacheManager.shared.getUserInfo(userID: userId)
            
            let cacheInfo = GroupMemberInfo()
            cacheInfo.userID = u?.userID
            cacheInfo.nickname = u?.nickname
            cacheInfo.faceURL = u?.faceURL
            
            memberInfoRelay.onNext(cacheInfo)
            
            IMController.shared.getGroupMembersInfo(groupId: groupId, uids: [userId]) { [weak self] (members: [GroupMemberInfo]) in
                guard let member = members.first else { return }
                
                let cacheInfo = UserInfo(userID: member.userID!, nickname: member.nickname, faceURL: member.faceURL)
                UserCacheManager.shared.addOrUpdateUserInfo(userID: cacheInfo.userID, userInfo: cacheInfo)
                
                self?.memberInfoRelay.onNext(member)
            }
        }
        
        var u = UserCacheManager.shared.getUserInfo(userID: userId)
        userInfoRelay.accept(u)
        
        IMController.shared.getBlackList { [self] blacks in
            isInBlackListRelay.onNext(blacks.contains(where: { $0.userID == userId }))
        }
        
        IMController.shared.getFriendsInfo(userIDs: [userId]) { [self] friendInfo in
            let isFriend = friendInfo.first != nil
            
            isFriendRelay.onNext(isFriend)

            if let friendInfo = friendInfo.first {
                if let u {
                    u.nickname = friendInfo.nickname
                    u.remark = friendInfo.remark
                    u.faceURL = friendInfo.faceURL
                } else {
                    u = UserInfo(userID: friendInfo.userID!, nickname: friendInfo.nickname, remark: friendInfo.remark, faceURL: friendInfo.faceURL)
                }
                
                userInfoRelay.accept(u)
            }
            IMController.shared.getUserInfo(uids: [userId]) { [weak self] users in
                guard let self, let sdkUser = users.first else { return }
                
                if let handler = OIMApi.queryUsersInfoWithCompletionHandler {
                    handler([userId], { [self] users in
                        if let chatUser = users.first {
                            chatUser.remark = friendInfo.first?.remark
                            self.userInfoRelay.accept(chatUser)
                            UserCacheManager.shared.addOrUpdateUserInfo(userID: sdkUser.userID!, userInfo: chatUser)
                        }
                    })
                }
            }
        }
    }
    
    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        let reqMsg = "\(IMController.shared.currentUserRelay.value!.nickname!)请求添加你为好友"
        IMController.shared.addFriend(uid: userId, reqMsg: reqMsg, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func saveRemark(remark: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid)  {
        IMController.shared.setFriend(uid: userId, remark: remark, onSuccess: onSuccess)
    }
    
    func blockUser(blocked: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid){
        IMController.shared.blockUser(uid: userId, blocked: blocked) { [weak self] r in
            self?.isInBlackListRelay.onNext(blocked)
        }
    }
    
    func deleteFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.deleteFriend(uid: userId) { [weak self] res in
            guard let `self` = self else { return }
            IMController.shared.getConversation(sessionType: .c2c, sourceId: userId) { conv in
                guard let conv else { return }
                IMController.shared.deleteConversation(conversationID: conv.conversationID) { r in
                    onSuccess(res)
                }
            }
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}
