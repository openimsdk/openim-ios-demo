
import OUICore
import RxRelay

class NewGroupViewModel {
    
    var groupName: String?
    var groupAvatar: String?
    private var groupType: GroupType
    
    var membersRelay: BehaviorRelay<[UserInfo]> = .init(value: [])
    
    init(users: [UserInfo], groupType: GroupType = .normal) {
        self.membersRelay.accept(users)
        self.groupType = groupType
    }

    func getMembers() {
        var users = membersRelay.value
        /*
        let fakeUser = UserInfo(userID: "")
        fakeUser.isAddButton = true
        users.append(fakeUser)

        let fakeUser2 = UserInfo(userID: "")
        fakeUser2.isRemoveButton = true
        users.append(fakeUser2)
        */
        membersRelay.accept(users)
    }
    
    func updateMembers(_ users: [UserInfo]) {
        var temp = users
        /*
        let fakeUser = UserInfo(userID: "")
        fakeUser.isAddButton = true
        temp.append(fakeUser)

        let fakeUser2 = UserInfo(userID: "")
        fakeUser2.isRemoveButton = true
        temp.append(fakeUser2)
        */
        membersRelay.accept(temp)
    }
    
    func uploadFile(fullPath: String, onComplete: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.uploadFile(fullPath: fullPath, onProgress: { _ in
        }) { [weak self] url in
            onComplete(url)
        }
    }
    
    func createGroup(onSuccess: @escaping CallBack.ConversationInfoOptionalReturnVoid) {
        guard let groupName = groupName else {
            return
        }

        IMController.shared.createGroupConversation(users: membersRelay.value,
                                                    groupType: groupType,
                                                    groupName: groupName,
                                                    avatar: groupAvatar) { [weak self] groupInfo in
            
            guard let groupInfo = groupInfo, let sself = self else {
                onSuccess(nil)
                return
            }
            
            IMController.shared.getConversation(sessionType: .superGroup,
                                                sourceId: groupInfo.groupID) { [weak self] (conversation: ConversationInfo?) in
                onSuccess(conversation)
            }
        } onFailure: { code, msg in
            onSuccess(nil)
        }
    }
}
