
import OUICore
import RxSwift
import RxRelay
#if ENABLE_ORGANIZATION
import OUIOrganization
#endif

class UserDetailViewModel {
    let userId: String
    let groupId: String?
    let groupInfo: GroupInfo?
    
    let userInfoRelay: BehaviorSubject<FriendInfo?> = .init(value: nil)
    var memberInfoRelay: BehaviorRelay<GroupMemberInfo?> = .init(value: nil)
    var allowAddFriend: BehaviorRelay<Bool> = .init(value: false)
    var showSetAdmin: Bool = false
    var showJoinSource: Bool = false
    var showMute: Bool = false
    var allowSendMsg: PublishRelay<Bool> = .init()
    var userDetailFor = UserDetailFor.groupMemberInfo
#if ENABLE_ORGANIZATION
    var companyName: String?
    var organizationInfo: BehaviorRelay<[DepartmentMemberInfo]> = .init(value: [])
#endif
    
    var isMine: Bool {
        userId == IMController.shared.uid || groupInfo?.ownerUserID == IMController.shared.uid
    }
    
    var isFriend: Bool = false
    
    private let _disposeBag = DisposeBag()
    init(userId: String, groupId: String? = nil, groupInfo: GroupInfo? = nil, groupMemberInfo: GroupMemberInfo? = nil, userInfo: PublicUserInfo? = nil, userDetailFor: UserDetailFor) {
        self.userId = userId
        self.groupId = groupId
        self.groupInfo = groupInfo
        self.userDetailFor = userDetailFor
        if let userInfo {
            self.userInfoRelay.onNext(FriendInfo(userID: userInfo.userID, nickname: userInfo.nickname, faceURL: userInfo.faceURL))
        }
        if let groupMemberInfo {
            self.memberInfoRelay.accept(groupMemberInfo)
        }
        
        IMController.shared.friendInfoChangedSubject.subscribe(onNext: { [weak self] (friendInfo: FriendInfo?) in
            guard let self else { return }
            guard friendInfo?.userID == userId else { return }
            
            userInfoRelay.onNext(friendInfo)
        }).disposed(by: _disposeBag)
        
        IMController.shared.addFriendSubject.subscribe(onNext: { [weak self] info in
            guard let self, info.userID == userId else { return }
            queryUserInfoFromChat(isFriend: true)
            userInfoRelay.onNext(info)
        }).disposed(by: _disposeBag)
        
        IMController.shared.deleteFriendSubject.subscribe(onNext: { [weak self] info in
            guard let self, info.userID == userId else { return }
            
            userInfoRelay.onNext(info)
        }).disposed(by: _disposeBag)
    }
    
    func getUserOrMemberInfo() {
        let group = DispatchGroup()
        var memberInfo: GroupMemberInfo?
#if ENABLE_ORGANIZATION
        var orgInfo: [DepartmentMemberInfo] = []
#endif
        
        if let groupId = groupId, !groupId.isEmpty, userDetailFor == .groupMemberInfo {
            group.enter()

            var isSelf = IMController.shared.uid == userId
            IMController.shared.getGroupMembersInfo(groupId: groupId,
                                                    uids: isSelf ? [userId] : [IMController.shared.uid, userId]) { [weak self] (members: [GroupMemberInfo]) in
                guard let mine = members.first(where: { $0.userID == IMController.shared.uid}), let sself = self else {
                    group.leave()
                    return
                }
                memberInfo = members.first(where: { $0.userID == sself.userId})
                
                if !isSelf {
                    if mine.roleLevel == .owner {
                        sself.showMute = true
                        sself.showSetAdmin = true
                        sself.showJoinSource = true
                    } else if mine.roleLevel == .admin {
                        sself.showMute = true
                        sself.showJoinSource = true
                    }


                    group.leave()

                } else {
                    group.leave()
                }
            }
        }
        
#if ENABLE_ORGANIZATION
        group.enter()
        OUIOrganization.DefaultDataProvider.queryDepartment() { [weak self] (r: [DepartmentInfo]?) in
            if let r {
                self?.companyName = r.first?.name
            }
            group.leave()
        }
        
        group.enter()
        OUIOrganization.DefaultDataProvider.queryUserInDepartment(userIDs: [userId]) { [weak self] r in
            if let r = r {
                orgInfo.append(contentsOf: r)
            }
            group.leave()
        }
#endif
        group.notify(queue: .main) { [weak self] in
            self?.memberInfoRelay.accept(memberInfo)
#if ENABLE_ORGANIZATION
            self?.organizationInfo.accept(orgInfo)
#endif
        }
        
        getOtherSetting()
    }
    
    func getOtherSetting() {
        if let cacheUser = UserCacheManager.shared.getUserInfo(userID: userId) {
            userInfoRelay.onNext(cacheUser.toFriendInfo())
        }
        
        IMController.shared.getFriendsInfo(userIDs: [userId]) { [self] friends in
            if let friend = friends.first {
                isFriend = true
                userInfoRelay.onNext(friend)
                UserCacheManager.shared.addOrUpdateUserInfo(userID: userId, userInfo: UserInfo(userID: friend.userID!, nickname: friend.nickname, remark: friend.remark, faceURL: friend.faceURL))
                
                queryUserInfoFromChat(isFriend: true)
            } else {
                IMController.shared.getUserInfo(uids: [userId]) { [self] users in
                    guard let sdkUser = users.first else { return }
                    
                    userInfoRelay.onNext(sdkUser.toFriendInfo())
                    UserCacheManager.shared.addOrUpdateUserInfo(userID: userId, userInfo: UserInfo(userID: sdkUser.userID!, nickname: sdkUser.nickname, faceURL: sdkUser.faceURL))
                    
                    queryUserInfoFromChat(isFriend: false)
                }
            }
        }
    }
    func queryUserInfoFromChat(isFriend: Bool) {
        if let handler = OIMApi.queryUsersInfoWithCompletionHandler, userId != IMController.shared.uid {
            handler([userId], { [weak self] users in
                guard let self else { return }
                
                if let chatUser = users.first {
                    UserCacheManager.shared.addOrUpdateUserInfo(userID: userId, userInfo: chatUser)
                    
                    var chatAllowAddFriend = chatUser.allowAddFriend == 1 && !isFriend
                    var groupAllowAddFriend = true

                    if let groupInfo = groupInfo {
                        groupAllowAddFriend = groupInfo.applyMemberFriend == 0
                    }
                    
                    let allow = chatAllowAddFriend && groupAllowAddFriend
                    
                    allowAddFriend.accept(allow)
                }
            })
        }
        
        guard !isFriend else {
            allowSendMsg.accept(true)
            
            return
        }
        
        if let configHandler = OIMApi.queryConfigHandler {
            
            configHandler { [weak self] code, result in
                guard let self else { return }
                
                if !result.isEmpty {
                    if let allowSendMsgNotFriend = result["allowSendMsgNotFriend"] as? String {
                        let allowedStranger = Int(allowSendMsgNotFriend) == 1 && userId != IMController.shared.uid
                        
                        allowSendMsg.accept(isFriend || allowedStranger)
                    }
                } else {
                    allowSendMsg.accept(true)
                }
            }
        }
    }
    
    func createSingleChat(onComplete: @escaping (ConversationInfo) -> Void) {
        IMController.shared.getConversation(sessionType: .c2c, sourceId: userId) { [weak self] (conversation: ConversationInfo?) in
            guard let conversation else { return }
            
            onComplete(conversation)
        }
    }
    
    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        let reqMsg = "\(IMController.shared.currentUserRelay.value!.nickname!)请求添加你为好友"
        IMController.shared.addFriend(uid: userId, reqMsg: reqMsg, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func toggleSetAdmin(toAdmin: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.setGroupMemberRoleLevel(groupId: groupId!, userID: userId, roleLevel: toAdmin ? .admin : .member, onSuccess: onSuccess)
    }
    
    func setMutedSeconds(seconds: Int, acceptValue: Bool = true, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        guard let groupId = groupId else {
            return
        }
        
        IMController.shared.changeGroupMemberMute(groupID: groupId, userID: userId, seconds: seconds) { [weak self] r in
            
            guard let sself = self else { return }
            if acceptValue {
                var info = sself.memberInfoRelay.value!
                info.muteEndTime = (NSDate().timeIntervalSince1970 + Double(seconds)) * 1000
                sself.memberInfoRelay.accept(info)
            }
            onSuccess(r)
        }
    }
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}

struct UserCacheManager {
    static var shared = UserCacheManager()
    var _userInfoMap: [String: UserInfo] = [:]
    
    mutating func addOrUpdateUserInfo(userID: String, userInfo: UserInfo) {
        if var temp = _userInfoMap[userID] {

            let nickname = userInfo.nickname
            temp.nickname = nickname
            let remark = userInfo.remark
            temp.remark = remark
            let faceURL = userInfo.faceURL
            temp.faceURL = faceURL
            let gender = userInfo.gender
            temp.gender = gender
            let phoneNumber = userInfo.phoneNumber
            temp.phoneNumber = phoneNumber
            let birth = userInfo.birth
            temp.birth = birth
            let email = userInfo.email
            temp.email = email
            let landline = userInfo.landline
            temp.landline = landline
            let forbidden = userInfo.forbidden
            temp.forbidden = forbidden
            let allowAddFriend = userInfo.allowAddFriend
            temp.allowAddFriend = allowAddFriend
            let ex = userInfo.ex
            temp.ex = ex
            
            temp.createTime = userInfo.createTime
            temp.globalRecvMsgOpt = userInfo.globalRecvMsgOpt

            _userInfoMap[userID] = temp
        } else {
            _userInfoMap[userID] = userInfo
        }
    }


    func getUserInfo(userID: String) -> UserInfo? {
      return _userInfoMap[userID]
    }

    mutating func removeUserInfo(userID: String) {
      _userInfoMap.removeValue(forKey: userID)
    }
}
