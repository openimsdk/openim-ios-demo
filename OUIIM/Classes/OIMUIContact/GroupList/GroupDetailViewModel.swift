
import OUICore
import RxSwift
import RxRelay

class GroupDetailViewModel {
    let groupId: String

    let membersRelay: BehaviorRelay<[GroupMemberInfo]> = .init(value: [])
    let membersCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let groupInfoRelay: BehaviorRelay<GroupInfo?> = .init(value: nil)
    let isInGroupSubject: BehaviorSubject<Bool> = .init(value: false)
    var allMembers: [String] = []
    private(set) var superAndAdmins: [String] = []

    init(groupId: String) {
        self.groupId = groupId
    }

    func getGroupInfo() {
        IMController.shared.getGroupMemberList(groupId: groupId, filter: .all, offset: 0, count: 7) { [weak self] ms in
            var temp = ms.prefix(6)
            
            if ms.count > 6 {
                let fakeUser = GroupMemberInfo()
                fakeUser.nickname = "•••"
                temp.append(fakeUser)
            }
            self?.membersRelay.accept(Array(temp))
        }

        IMController.shared.getGroupInfo(groupIds: [groupId]) { [weak self] (groupInfos: [GroupInfo]) in
            guard let sself = self else { return }
            guard let groupInfo = groupInfos.first else { return }
            self?.groupInfoRelay.accept(groupInfo)
            self?.membersCountRelay.accept(groupInfo.memberCount)
            IMController.shared.getGroupMemberList(groupId: sself.groupId, filter: .all, offset: 0, count: groupInfo.memberCount) { (members: [GroupMemberInfo]) in
                self?.allMembers = members.compactMap { $0.userID }
                self?.superAndAdmins = members.filter({ $0.isOwnerOrAdmin }).map({ $0.userID! })
            }
        }
        IMController.shared.isJoinedGroup(groupID: groupId) { [self] isIn in
            self.isInGroupSubject.onNext(isIn)
        }
    }

    func joinCurrentGroup(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.joinGroup(id: groupId, reqMsg: nil, onSuccess: onSuccess)
    }
}
