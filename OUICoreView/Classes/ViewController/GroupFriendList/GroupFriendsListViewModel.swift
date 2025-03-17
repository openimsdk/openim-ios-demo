
import OUICore
import RxRelay
import RxSwift

class GroupFriendsListViewModel {
    let isMyGroupTableSelected: BehaviorRelay<Bool> = .init(value: true)
    let isMyFriendsTableSelected: BehaviorRelay<Bool> = .init(value: true)
    let items: BehaviorRelay<[Any]> = .init(value: [])
    let myGroupsRelay: BehaviorRelay<[GroupInfo]> = .init(value: [])
    let myFriendsRelay: BehaviorRelay<[UserInfo]> = .init(value: [])
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])

    private let _disposeBag = DisposeBag()
    private var iMyGroups: [GroupInfo] = []
    private var iMyFriends: [UserInfo] = []
    var members: [GroupMemberInfo] = []
    var contactSections: [[GroupMemberInfo]] = []

    init() {
        isMyGroupTableSelected.subscribe(onNext: { [weak self] (isICreated: Bool) in
            guard let sself = self else { return }
            if isICreated {
                self?.items.accept(sself.iMyGroups)
            } else {
                self?.items.accept(sself.iMyFriends)
            }
        }).disposed(by: _disposeBag)
    }

    func getMyGroups() {
        IMController.shared.getJoinedGroupList { [weak self] (groups: [GroupInfo]) in
            self?.iMyGroups = groups
            self?.myGroupsRelay.accept(groups)
            self?.isMyGroupTableSelected.accept(true)
        }
    }
    
    func getFriends() {
        IMController.shared.getFriendList { [weak self] friends in
            let r = friends.map({ UserInfo(userID: $0.userID!, nickname: $0.nickname, faceURL: $0.faceURL) })
            self?.iMyFriends = r
            self?.myFriendsRelay.accept(r)
        }
    }
}
