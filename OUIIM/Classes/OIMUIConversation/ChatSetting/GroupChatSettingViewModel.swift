
import OUICore
import RxCocoa
import RxSwift

class GroupChatSettingViewModel {
    private let _disposeBag = DisposeBag()
    private(set) var conversation: ConversationInfo

    let membersRelay: BehaviorRelay<[GroupMemberInfo]> = .init(value: [])
    let membersCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let noDisturbRelay: BehaviorRelay<Bool> = .init(value: false)
    var groupInfoRelay: BehaviorRelay<GroupInfo?> = .init(value: nil)
    let myInfoInGroup: BehaviorRelay<GroupMemberInfo?> = .init(value: nil)
    let isInGroupRelay: BehaviorRelay<Bool> = .init(value: true)

    private(set) var allMembers: [String] = []
    private(set) var superAndAdmins: [GroupMemberInfo] = []
    
    init(conversation: ConversationInfo, groupInfo: GroupInfo? = nil, groupMembers: [GroupMemberInfo]? = nil) {
        self.conversation = conversation
        if let groupInfo {
            groupInfoRelay.accept(groupInfo)
        }
        let defaultUserInfo = GroupMemberInfo()
        defaultUserInfo.userID = IMController.shared.currentUserRelay.value?.userID
        defaultUserInfo.nickname = IMController.shared.currentUserRelay.value?.nickname
        myInfoInGroup.accept(defaultUserInfo)
        
        if let groupInfo {
            groupInfoRelay.accept(groupInfo)
        } else {
            isInGroupRelay.accept(false)
        }
        
        if let groupMembers {
            configMembers(groupMembers: groupMembers)
        }
        
        IMController.shared.groupMemberInfoChange.subscribe(onNext: { [weak self] info in
            guard let self else { return }
            getConversationInfo()
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupMemberAdded.subscribe(onNext: { [weak self] info in

            guard let self, conversation.groupID == info?.groupID else { return }
            queryMembers(groupID: conversation.groupID!) {
            }
            var temp = groupInfoRelay.value
            temp?.memberCount += 1
            groupInfoRelay.accept(temp)
            
            queryMyInfoInGroup()
            isInGroupRelay.accept(true)
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupMemberDeleted.subscribe(onNext: { [weak self] info in

            guard let self, conversation.groupID == info?.groupID, let info else { return }
            
            var temp = groupInfoRelay.value
            temp?.memberCount -= 1
            groupInfoRelay.accept(temp)
            
            removeLocalMembers(member: info)
        }).disposed(by: _disposeBag)
        
        IMController.shared.joinedGroupAdded.subscribe(onNext: { [weak self] info in
            guard let self, conversation.groupID == info?.groupID else { return }
            queryMembers(groupID: conversation.groupID!) {
            }
            queryMyInfoInGroup()
            isInGroupRelay.accept(true)
        }).disposed(by: _disposeBag)
        
        IMController.shared.joinedGroupDeleted.subscribe(onNext: { [weak self] info in
            guard let self, conversation.groupID == info?.groupID else { return }
            
            isInGroupRelay.accept(false)
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupInfoChangedSubject.subscribe { [weak self] groupInfo in
            guard let self else { return }
            
            groupInfoRelay.accept(groupInfo)
            getGroupInfoHelper(groupInfo: groupInfo)
            queryMyInfoInGroup()
        }.disposed(by: _disposeBag)
    }

    private func publishConversationInfo() {
        noDisturbRelay.accept(conversation.recvMsgOpt != .receive)
    }
    
    func getConversationInfo() {
        
        if let groupInfo = groupInfoRelay.value {
            getGroupInfoHelper(groupInfo: groupInfo)
        } else {
            getGroupInfo()
        }
    }
    
    private func getGroupInfo() {
        guard let groupID = conversation.groupID else { return }
        
        IMController.shared.getGroupInfo(groupIds: [groupID]) { [weak self] (groupInfos: [GroupInfo]) in
            guard let self else { return }
            guard let groupInfo = groupInfos.first else { return }
            
            getGroupInfoHelper(groupInfo: groupInfo)
        }
    }
    
    private func getGroupInfoHelper(groupInfo: GroupInfo) {
        membersCountRelay.accept(groupInfo.memberCount)
        
        IMController.shared.isJoinedGroup(groupID: groupInfo.groupID) { [self] isIn in
            
            self.isInGroupRelay.accept(isIn)
            
            if isIn {
                self.queryMembers(groupID: groupInfo.groupID) { [self] in
                    self.groupInfoRelay.accept(groupInfo)
                    self.publishConversationInfo()
                }
            } else {
                self.publishConversationInfo()
            }
        }
    }
    
    private func queryMyInfoInGroup() {
        guard let gid = conversation.groupID else { return }

        IMController.shared.getGroupMembersInfo(groupId: gid, uids: [IMController.shared.uid]) { [weak self] (members: [GroupMemberInfo]) in
            for member in members {
                if member.isSelf {
                    member.nickname = member.nickname ?? IMController.shared.currentUserRelay.value?.nickname
                    self?.myInfoInGroup.accept(member)
                }
            }
        }
    }
    
    private func removeLocalMembers(member: GroupMemberInfo) {
        superAndAdmins.removeAll(where: { $0.userID == member.userID })
        
        var temp = membersRelay.value
        
        for (i, item) in temp.enumerated() {
            if item.userID == member.userID {
                temp.remove(at: i)
                break
            }
        }
        
        membersRelay.accept(temp)
        
        for (i, item) in allMembers.enumerated() {
            if item == member.userID {
                allMembers.remove(at: i)
                break
            }
        }
    }
    
    private func queryMembers(groupID: String, endHandler: @escaping () -> Void) {
        
        Task {
            var offset = 0
            var count = 500
            
            var groupMembers: [GroupMemberInfo] = []
            
            while (true) {
                let members = await getGroupMembers(groupID:groupID, offset: offset, count: count)
                    
                groupMembers.append(contentsOf: members)
                
                if members.isEmpty || members.count < count {
                    break
                }
                
                offset += count
            }
            
            configMembers(groupMembers: groupMembers)
            DispatchQueue.main.async { [self] in
                endHandler()
            }
        }
    }
    
    func getGroupMembers(groupID: String, offset: Int = 0, count: Int = 1000) async -> [GroupMemberInfo] {
        
        return await withCheckedContinuation { continuation in
            IMController.shared.getGroupMemberList(groupId: groupID, filter: .all, offset: offset, count: count) { [self] ms in
                continuation.resume(returning: ms)
            }
        }
    }
    
    func configMembers(groupMembers: [GroupMemberInfo]) {
        allMembers.removeAll()
        superAndAdmins.removeAll()
        var displayMembers: [GroupMemberInfo] = []
        
        for member in groupMembers {
            if member.isSelf {
                member.nickname = member.nickname ?? IMController.shared.currentUserRelay.value?.nickname
                DispatchQueue.main.async { [self] in
                    myInfoInGroup.accept(member)
                }
            }
            
            allMembers.append(member.userID!)
            
            if member.isOwnerOrAdmin {
                superAndAdmins.append(member)
            } else {
                displayMembers.append(member)
            }
        }
        
        var users: [GroupMemberInfo] = []
        
        let fakeUser = GroupMemberInfo()
        fakeUser.isAddButton = true
        fakeUser.nickname = "invite".innerLocalized()
        users.append(fakeUser)
        
        if let isSuperAndAdmin = superAndAdmins.first(where: { $0.userID == IMController.shared.uid }) {
            let fakeUser2 = GroupMemberInfo()
            fakeUser2.isRemoveButton = true
            fakeUser2.nickname = "remove".innerLocalized()
            users.append(fakeUser2)
        }
        
        let tempUsers = (superAndAdmins + displayMembers).prefix(10 - users.count)
        users.insert(contentsOf: Array(tempUsers), at: 0)
        
        DispatchQueue.main.async { [self] in
            membersRelay.accept(users)
        }
    }

    func updateGroupName(_ name: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        guard let group = groupInfoRelay.value else { return }
        group.groupName = name
        IMController.shared.setGroupInfo(group: group) { [weak self] resp in
            self?.groupInfoRelay.accept(group)
            onSuccess(resp)
        }
    }

    func clearRecord(completion: @escaping CallBack.StringOptionalReturnVoid) {
        guard let groupID = conversation.groupID else { return }
        IMController.shared.clearGroupHistoryMessages(conversationID: conversation.conversationID) { [weak self] resp in
            guard let sself = self else { return }
            let event = EventRecordClear(conversationId: sself.conversation.conversationID)
            JNNotificationCenter.shared.post(event)
            completion(resp)
        }
    }

    func setNoDisturbWithNotNotify() {
        IMController.shared.setConversationRecvMessageOpt(conversationID: conversation.conversationID, status: .notNotify, completion: { [weak self] _ in
            guard let sself = self else { return }
            self?.noDisturbRelay.accept(true)
        })
    }

    func setNoDisturbOff() {
        IMController.shared.setConversationRecvMessageOpt(conversationID: conversation.conversationID, status: .receive, completion: { [weak self] _ in
            guard let sself = self else { return }
            self?.noDisturbRelay.accept(false)
        })
    }

    func dismissGroup(onSuccess: @escaping CallBack.VoidReturnVoid) {
        guard let groupId = conversation.groupID else { return }
        IMController.shared.dismissGroup(id: groupId) { [weak self] _ in
            guard let sself = self else { return }
            let event = EventGroupDismissed(conversationId: sself.conversation.conversationID)
            JNNotificationCenter.shared.post(event)
            IMController.shared.deleteConversation(conversationID: (self?.conversation.conversationID)!) { r in
                onSuccess()
            }
        }
    }

    func quitGroup(onSuccess: @escaping CallBack.VoidReturnVoid) {
        guard let groupId = conversation.groupID else { return }
        IMController.shared.quitGroup(id: groupId) { [weak self] _ in
            guard let sself = self else { return }
            let event = EventGroupDismissed(conversationId: sself.conversation.conversationID)
            JNNotificationCenter.shared.post(event)
            IMController.shared.deleteConversation(conversationID: (self?.conversation.conversationID)!) { r in
                onSuccess()
            }
        }
    }
    
    func transferOwner(to uid: String, onSuccess: @escaping CallBack.VoidReturnVoid) {
        guard let group = groupInfoRelay.value else { return }
        IMController.shared.transferOwner(groupId: group.groupID, to: uid) { r in
            onSuccess()
        }
    }
    
    func inviteUsersToGroup(uids: [String], onSuccess: @escaping CallBack.VoidReturnVoid, onFailure: CallBack.ErrorOptionalReturnVoid? = nil) {
        guard let groupID = groupInfoRelay.value?.groupID else { return }
        
        IMController.shared.inviteUsersToGroup(groupId: groupID, uids: uids, onSuccess: { [self] in
            self.queryMembers(groupID: groupID) {
                onSuccess()
            }
        }, onFailure: onFailure)
    }
    
    func kickGroupMember(uids: [String], onSuccess: @escaping CallBack.VoidReturnVoid) {
        guard let groupID = groupInfoRelay.value?.groupID else { return }

        IMController.shared.kickGroupMember(groupId: groupID, uids: uids) { [weak self] r in
            if r {
                self?.queryMembers(groupID: groupID) {
                    onSuccess()
                }
            } else {
                onSuccess()
            }
        }
    }
    
    func uploadFile(fullPath: String, onProgress: @escaping (CGFloat) -> Void, onComplete: @escaping () -> Void) {
        IMController.shared.uploadFile(fullPath: fullPath, onProgress: onProgress) { [weak self] url in
            if let url, let info = self?.groupInfoRelay.value {
                
                let p = GroupInfo(groupID: info.groupID)
                p.faceURL = url
                
                IMController.shared.setGroupInfo(group: p) { r in
                    info.faceURL = url
                    self?.groupInfoRelay.accept(info)
                    onComplete()
                }
            }
        }
    }
    
    func removeConversation(onComplete: @escaping (Bool) -> Void) {
        IMController.shared.deleteConversation(conversationID: conversation.conversationID) { [weak self] r in
            onComplete(r != nil)
        }
    }
}

fileprivate var GroupMemberInfoAddButtonExtensionKey: String?
fileprivate var GroupMemberInfoRemoveButtonExtensionKey: String?

extension GroupMemberInfo {
    public func toUserInfo() -> UserInfo {
        let user = UserInfo(userID: userID!)
        user.faceURL = faceURL
        user.nickname = nickname
        
        return user
    }
    
    public var isAddButton: Bool {
        set {
            objc_setAssociatedObject(self, &GroupMemberInfoAddButtonExtensionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }

        get {
            let value: Bool = objc_getAssociatedObject(self, &GroupMemberInfoAddButtonExtensionKey) as? Bool ?? false
            return value
        }
    }
    
    public var isRemoveButton: Bool {
        set {
            objc_setAssociatedObject(self, &GroupMemberInfoRemoveButtonExtensionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }

        get {
            let value: Bool = objc_getAssociatedObject(self, &GroupMemberInfoRemoveButtonExtensionKey) as? Bool ?? false
            return value
        }
    }
}
