
import OUICore
import RxRelay
import RxSwift

class SingleChatSettingViewModel {
    private(set) var conversation: ConversationInfo

    let membesRelay: BehaviorRelay<[UserInfo]> = .init(value: [])
    let noDisturbRelay: BehaviorRelay<Bool> = .init(value: false)
    let setTopContactRelay: BehaviorRelay<Bool> = .init(value: false)
    
    private let _disposeBag = DisposeBag()
    init(conversation: ConversationInfo, userInfo: UserInfo? = nil) {
        self.conversation = conversation
        if let userInfo {
            self.membesRelay.accept([userInfo])
        }
        IMController.shared.friendInfoChangedSubject.subscribe { [weak self] (friendInfo: FriendInfo?) in
            guard let sself = self else { return }
            if friendInfo?.userID == sself.conversation.userID {
                var users = sself.membesRelay.value
                for (index, user) in sself.membesRelay.value.enumerated() {
                    if user.userID == friendInfo?.userID {
                        var nickName: String? = friendInfo?.nickname
                        if let remark = friendInfo?.remark, !remark.isEmpty {
                            nickName = nickName?.append(string: "(\(remark))")
                        }
                        user.nickname = nickName
                        if let gender = friendInfo?.gender {
                            user.gender = gender
                        }
                        user.phoneNumber = friendInfo?.phoneNumber
                        if let birth = friendInfo?.birth {
                            user.birth = birth
                        }
                        user.email = friendInfo?.email
                        users[index] = user
                    }
                }
                sself.membesRelay.accept(users)
            }
        }.disposed(by: _disposeBag)
    }

    private func publishConversationInfo() {
        noDisturbRelay.accept(conversation.recvMsgOpt == .notNotify)
        setTopContactRelay.accept(conversation.isPinned)
    }

    func getConversationInfo() {
        guard let userId = conversation.userID else { return }

        IMController.shared.getConversation(sessionType: conversation.conversationType, sourceId: userId) { [weak self] (chat: ConversationInfo?) in
            if let chat = chat {
                self?.conversation = chat
                self?.publishConversationInfo()
            }
        }
        
        IMController.shared.getFriendsInfo(userIDs: [userId]) { [self] users in
            
            if let user = users.first {
                let userInfo = UserInfo(userID: user.userID!, nickname: user.nickname, faceURL: user.faceURL)
                var nickName: String? = user.nickname
                if let remark = user.remark, !remark.isEmpty {
                    nickName = nickName?.append(string: "(\(remark))")
                }
                userInfo.nickname = nickName

                let fakeUser = UserInfo(userID: "")
                fakeUser.isAddButton = true
                self.membesRelay.accept([userInfo, fakeUser])
                
                return;
            }
            IMController.shared.getUserInfo(uids: [userId]) { [self] userInfos in
                
                if let user = userInfos.first {
                    let userInfo = UserInfo(userID: user.userID!, nickname: user.nickname, faceURL: user.faceURL)

                    let fakeUser = UserInfo(userID: "")
                    fakeUser.isAddButton = true
                    self.membesRelay.accept([userInfo, fakeUser])
                }
            }
        }
    }

    func clearRecord(completion: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.clearC2CHistoryMessages(conversationID: conversation.conversationID) { [weak self] resp in
            guard let sself = self else { return }
            let event = EventRecordClear(conversationId: sself.conversation.conversationID)
            JNNotificationCenter.shared.post(event)
            completion(resp)
        }
    }

    func toggleTopContacts() {
        IMController.shared.pinConversation(id: conversation.conversationID, isPinned: !setTopContactRelay.value, completion: { [weak self] _ in
            guard let sself = self else { return }
            sself.setTopContactRelay.accept(!sself.setTopContactRelay.value)
        })
    }

    func toggleNoDisturb() {
        let receiveOpt: ReceiveMessageOpt = !noDisturbRelay.value == true ? .notNotify : .receive
        IMController.shared.setConversationRecvMessageOpt(conversationID: conversation.conversationID, status: receiveOpt, completion: { [weak self] _ in
            guard let sself = self else { return }
            self?.noDisturbRelay.accept(!sself.noDisturbRelay.value)
        })
    }
}

var UserInfoAddButtonExtensionKey: String?
var UserInfoRemoveButtonExtensionKey: String?
extension UserInfo {
    public var isAddButton: Bool {
        set {
            objc_setAssociatedObject(self, &UserInfoAddButtonExtensionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }

        get {
            let value: Bool = objc_getAssociatedObject(self, &UserInfoAddButtonExtensionKey) as? Bool ?? false
            return value
        }
    }
    
    public var isRemoveButton: Bool {
        set {
            objc_setAssociatedObject(self, &UserInfoRemoveButtonExtensionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }

        get {
            let value: Bool = objc_getAssociatedObject(self, &UserInfoRemoveButtonExtensionKey) as? Bool ?? false
            return value
        }
    }
}
