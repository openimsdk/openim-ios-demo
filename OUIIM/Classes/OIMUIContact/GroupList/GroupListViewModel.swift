
import OUICore
import RxRelay
import RxSwift

class GroupListViewModel {
    let isICreateTableSelected: BehaviorRelay<Bool> = .init(value: true)
    let items: BehaviorRelay<[GroupInfo]> = .init(value: [])
    let myGroupsRelay: BehaviorRelay<[GroupInfo]> = .init(value: [])
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])
    let loading = BehaviorRelay<Bool>(value: false)
    
    private let _disposeBag = DisposeBag()
    private var iCreateGroups: [GroupInfo] = []
    private var iJoinedGroups: [GroupInfo] = []
    var members: [GroupMemberInfo] = []
    var contactSections: [[GroupMemberInfo]] = []
    
    private var iCreateOffset = 0
    private var iJoinOffset = 0
    var count = 1000
    
    init() {
        isICreateTableSelected.subscribe(onNext: { [weak self] (isICreated: Bool) in
            guard let self else { return }
            
            if isICreated {
                self.refreshICreate {_ in }
            } else {
                self.refreshIJoined {_ in }
            }
        }).disposed(by: _disposeBag)
        
        IMController.shared.getJoinedGroupList(count: 100 * 100) { [weak self] infos in
            self?.myGroupsRelay.accept(infos)
        }
    }
    
    func onRefresh(completion: @escaping (Int) -> Void) {
        if isICreateTableSelected.value {
            refreshICreate(completion: completion)
        } else {
            refreshIJoined(completion: completion)
        }
    }
    
    func onLoadMore(completion: @escaping (Int) -> Void) {
        if isICreateTableSelected.value {
            loadMoreICreate(completion: completion)
        } else {
            loadMoreIJoined(completion: completion)
        }
    }
    
    func refreshICreate(completion: @escaping (Int) -> Void) {
        iCreateOffset = 0
        iCreateGroups.removeAll()
        
        IMController.shared.getJoinedGroupList(offset: iCreateOffset, count: count) { [weak self] result in
            guard let self else { return }
            
            iCreateGroups = result.filter({ $0.creatorUserID == IMController.shared.uid })
            items.accept(iCreateGroups)
            
            if !result.isEmpty {
                completion(result.count)
            }
            
            if (result.count == count) {
                iCreateOffset += result.count
            }
        }
    }
    
    func loadMoreICreate(completion: @escaping (Int) -> Void) {
        IMController.shared.getJoinedGroupList(offset: iCreateOffset, count: count) {  [weak self] result in
            guard let self else { return }
            
            iCreateGroups.append(contentsOf: result.filter({ $0.creatorUserID == IMController.shared.uid }))
            items.accept(iCreateGroups)
            
            iCreateOffset += result.count
            
            completion(result.count)
        }
    }
    
    func refreshIJoined(completion: @escaping (Int) -> Void) {
        iJoinOffset = 0
        iJoinedGroups.removeAll()
        
        IMController.shared.getJoinedGroupList(offset: iJoinOffset, count: count) {  [weak self] result in
            guard let self else { return }
            
            iJoinedGroups = result.filter({ $0.creatorUserID != IMController.shared.uid })
            items.accept(iJoinedGroups)
            
            if !result.isEmpty {
                completion(result.count)
            }
            
            if (result.count == count) {
                iJoinOffset += result.count
            }
        }
    }
    
    func loadMoreIJoined(completion: @escaping (Int) -> Void) {
        IMController.shared.getJoinedGroupList(offset: iJoinOffset, count: count) { [weak self] result in
            guard let self else { return }
            
            iJoinedGroups.append(contentsOf: result.filter({ $0.creatorUserID != IMController.shared.uid }))
            items.accept(iJoinedGroups)
            
            iJoinOffset += result.count
            
            completion(result.count)
        }
    }
    
    func getMyGroups() {
        loading.accept(true)
        IMController.shared.getJoinedGroupList { [weak self] (groups: [GroupInfo]) in
            let groups: [GroupInfo] = groups ?? []
            var createGroups: [GroupInfo] = []
            var joinedGroups: [GroupInfo] = []
            for group in groups {
                if group.creatorUserID == IMController.shared.uid {
                    createGroups.append(group)
                } else {
                    joinedGroups.append(group)
                }
            }
            self?.iCreateGroups = createGroups
            self?.iJoinedGroups = joinedGroups
            self?.myGroupsRelay.accept(groups)
            self?.isICreateTableSelected.accept(true)
            self?.loading.accept(false)
        }
    }
    
    func getGroupMemberList(groupID: String) {
        IMController.shared.getGroupMemberList(groupId: groupID, offset: 0, count: 1000) { (members: [GroupMemberInfo]) in
            self.members = members
            self.divideUsersInSection(users: members)
        }
    }
    
    func getUsersAt(indexPaths: [IndexPath]) -> [UserInfo] {
        var users: [UserInfo] = []
        for indexPath in indexPaths {
            let member = contactSections[indexPath.section][indexPath.row]
            let user = UserInfo(userID: member.userID!, nickname: member.nickname, faceURL: member.faceURL)
            
            users.append(user)
        }
        return users
    }
    
    private func divideUsersInSection(users: [GroupMemberInfo]) {
        DispatchQueue.global().async { [weak self] in
            var letterSet: Set<String> = []
            for user in users {
                if let firstLetter = user.nickname?.getFirstPinyinUppercaseCharactor() {
                    letterSet.insert(firstLetter)
                }
            }
            
            let letterArr: [String] = Array(letterSet)
            let ret = letterArr.sorted { $0 < $1 }
            
            for letter in ret {
                var sectionArr: [GroupMemberInfo] = []
                for user in users {
                    if let first = user.nickname?.getFirstPinyinUppercaseCharactor(), first == letter {
                        sectionArr.append(user)
                    }
                }
                self?.contactSections.append(sectionArr)
            }
            DispatchQueue.main.async {
                self?.lettersRelay.accept(ret)
            }
        }
    }
}
