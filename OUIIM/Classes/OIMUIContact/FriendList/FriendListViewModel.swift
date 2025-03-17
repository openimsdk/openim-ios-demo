
import OUICore
import RxRelay
import RxSwift

class FriendListViewModel {
    let loadingSubject: PublishRelay<Bool> = .init()
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])
    var myFriends: [UserInfo] = []
    var contactSections: [[UserInfo]] = []
    
    var myGroups: [GroupInfo] = []
    var groupsSections: [[GroupInfo]] = []
    
    var count = 300
    private let disposeBag = DisposeBag()
    
    init() {
        IMController.shared.onBlackAddedSubject.subscribe(onNext: { [weak self] black in
            guard let self, let black else { return }
            
            getMyFriendList()
        }).disposed(by: disposeBag)
        
        IMController.shared.onBlackDeletedSubject.subscribe(onNext: { [weak self] black in
            guard let self, let black else { return }
            
            getMyFriendList()
        }).disposed(by: disposeBag)
    }
    
    func getMyFriendList() {
        
        Task { [self] in
            loadingSubject.accept(true)
            myFriends.removeAll()
                        
            while(true) {
                let friends = await IMController.shared.getFriendsSplit(offset: myFriends.count, count: count, filterBlack: true)
                let r = friends.compactMap({ UserInfo(userID: $0.userID!, nickname: $0.nickname, remark: $0.remark, faceURL: $0.faceURL) })
                myFriends.append(contentsOf: r)
                
                divideUsersInSection(users: myFriends)
                
                if r.count < count {
                    break
                }
                
                count = 1000
            }
            
            await MainActor.run {
                loadingSubject.accept(false)
            }
        }
    }
    
    func getGroups() {
        IMController.shared.getJoinedGroupList { [weak self] groups in
            self?.myGroups = groups
            self?.divideGroupsInSection(groups)
        }
    }
    
    func getUsersAt(indexPaths: [IndexPath]) -> [UserInfo] {
        var users: [UserInfo] = []
        for indexPath in indexPaths {
            let user = contactSections[indexPath.section][indexPath.row]
            users.append(user)
        }
        return users
    }
    
    private func divideUsersInSection(users: [UserInfo]) {
        var categorizedUsers: [String: [UserInfo]] = [:]
        
        for user in users {
            if let letter = user.nickname?.getFirstPinyinUppercaseCharactor() {
                if categorizedUsers[letter] != nil {
                    categorizedUsers[letter]!.append(user)
                } else {
                    categorizedUsers[letter] = [user]
                }
            }
        }
        
        var sections: [[UserInfo]] = []
        
        let sortedKeys = categorizedUsers.keys.sorted {
            if $0 == "#" {
                return false
            } else if $1 == "#" {
                return true
            } else {
                return $0 < $1
            }
        }

        for key in sortedKeys {
            sections.append(categorizedUsers[key]!)
        }
                
        DispatchQueue.main.async { [self] in
            contactSections = sections
            lettersRelay.accept(sortedKeys)
        }
    }
    
    
    private func divideGroupsInSection(_ users: [GroupInfo]) {
        DispatchQueue.global().async { [weak self] in
            var letterSet: Set<String> = []
            for user in users {
                if let firstLetter = user.groupName?.getFirstPinyinUppercaseCharactor() {
                    letterSet.insert(firstLetter)
                }
            }
            
            let letterArr: [String] = Array(letterSet)
            let ret = letterArr.sorted { $0 < $1 }
            
            for letter in ret {
                var sectionArr: [GroupInfo] = []
                for user in users {
                    if let first = user.groupName?.getFirstPinyinUppercaseCharactor(), first == letter {
                        sectionArr.append(user)
                    }
                }
                self?.groupsSections.append(sectionArr)
            }
            DispatchQueue.main.async {
                self?.lettersRelay.accept(ret)
            }
        }
    }
    
    func searchFriend(keyword: String) async -> [FriendInfo] {
        return await withCheckedContinuation { continuation in
            let param = SearchUserParam()
            param.keywordList = [keyword]
            
            IMController.shared.searchFriends(param: param) { r in
                continuation.resume(returning: r)
            }
        }
    }
}
