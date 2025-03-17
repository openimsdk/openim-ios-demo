
import OUICore
import RxRelay
import RxSwift

class MemberListViewModel {
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])
    var membersRelay: BehaviorRelay<[GroupMemberInfo]> = .init(value: [])
    var contactSections: [[GroupMemberInfo]] = []
    var targetUserId: String?
    let targetIndexRelay: BehaviorRelay<IndexPath?> = .init(value: nil)
    let ownerAndAdminRelay: BehaviorRelay<[GroupMemberInfo]> = .init(value: [])
    
    let groupInfo: GroupInfo
    private var offset = 0
    private var limit = 500
    private let _disposeBag = DisposeBag()
    
    init(groupInfo: GroupInfo) {
        self.groupInfo = groupInfo
        
        IMController.shared.groupMemberInfoChange.subscribe(onNext: { [weak self] info in
            guard let self, let info else { return }
            
            if info.isOwnerOrAdmin {
                var temp = ownerAndAdminRelay.value
                if let index = temp.firstIndex(where: { $0.userID == info.userID }) {
                    temp[index] = info
                    ownerAndAdminRelay.accept(temp)
                }
            } else {
                var temp = membersRelay.value
                if let index = temp.firstIndex(where: { $0.userID == info.userID }) {
                    temp[index] = info
                    membersRelay.accept(temp)
                }
            }
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupMemberAdded.subscribe(onNext: { [weak self] info in

            guard let self, let info, groupInfo.groupID == info.groupID else { return }
            
            if info.isOwnerOrAdmin {
                var temp = ownerAndAdminRelay.value
                temp.append(info)
                ownerAndAdminRelay.accept(temp)
            } else {
                var temp = membersRelay.value
                temp.append(info)
                membersRelay.accept(temp)
            }
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupMemberDeleted.subscribe(onNext: { [weak self] info in

            guard let self, let info, groupInfo.groupID == info.groupID else { return }
            
            if info.isOwnerOrAdmin {
                var temp = ownerAndAdminRelay.value
                temp = temp.filter { $0.userID != info.userID }
                ownerAndAdminRelay.accept(temp)
            } else {
                var temp = membersRelay.value
                temp = temp.filter { $0.userID != info.userID }
                membersRelay.accept(temp)
            }
        }).disposed(by: _disposeBag)
    }
    
    func resetMembersArray() {
        self.offset = 0
        self.membersRelay.accept([])
    }

    func getMoreMembers(completion: ((Bool) -> Void)? = nil) {
        IMController.shared.getGroupMemberList(groupId: groupInfo.groupID, filter: offset == 0 ? .all : .member, offset: offset, count: limit) { [weak self] (ms: [GroupMemberInfo]) in
            guard let self else { return }

            var tempResult = ms.sorted(by: { $0.isOwnerOrAdmin && !$1.isOwnerOrAdmin })
            
            if offset == 0 {
                let oa = Array(tempResult.prefix(while: { $0.isOwnerOrAdmin }))
                ownerAndAdminRelay.accept(oa)
                tempResult = Array(tempResult.suffix(from: oa.count))
            }
            
            if !ms.isEmpty {
                offset += min(limit, ms.count)
            }
            
            var temp = membersRelay.value
            temp.append(contentsOf: tempResult)

            temp.reduce([], { (partialResult: [GroupMemberInfo], m) in
                partialResult.contains(where: { $0.userID == m.userID }) ? partialResult : partialResult + [m]
            })
            
            if tempResult.isEmpty, completion != nil {
                completion?(true)
                return
            }
            membersRelay.accept(temp)
            completion?(tempResult.count < limit ? true : false)
            limit = 100

        }
    }

    func getUsersAt(indexPaths: [IndexPath]) -> [GroupMemberInfo] {
        var users: [GroupMemberInfo] = []
        for indexPath in indexPaths {
            let user = contactSections[indexPath.section][indexPath.row]
            users.append(user)
        }
        return users
    }

    private func divideUsersInSection(users: [GroupMemberInfo], completion: ((Bool)-> Void)?) {
        DispatchQueue.global().async { [weak self] in
            var letterSet: Set<String> = []
            for user in users {
                if let firstLetter = user.nickname?.getFirstPinyinUppercaseCharactor() {
                    letterSet.insert(firstLetter)
                }
            }

            var letterArr: [String] = Array(letterSet)
            var isContainsSharp = false
            if letterArr.contains("#") {
                isContainsSharp = true
                letterArr.removeAll { (value: String) in
                    return value == "#"
                }
            }
            var ret = letterArr.sorted()
            if isContainsSharp {
                ret.append("#")
            }
            var sections: [[GroupMemberInfo]] = []
            for letter in ret {
                var sectionArr: [GroupMemberInfo] = []
                for user in users {
                    if let first = user.nickname?.getFirstPinyinUppercaseCharactor(), first == letter {
                        sectionArr.append(user)
                    }
                }
                sections.append(sectionArr)
            }
            self?.contactSections = sections
            DispatchQueue.main.async { [self] in
                completion?(false)
                self?.lettersRelay.accept(ret)
                var indexPath: IndexPath?
                for (section, contacts) in sections.enumerated() {
                    for (row, contact) in contacts.enumerated() {
                        if contact.userID == self?.targetUserId {
                            indexPath = IndexPath.init(row: row, section: section)
                        }
                    }
                }
                self?.targetIndexRelay.accept(indexPath)
            }
        }
    }
    
    func searchGroupMembers(keywords: [String]) async -> [GroupMemberInfo] {
        let param = SearchGroupMemberParam(groupID: groupInfo.groupID, keywordList: keywords)
        
        do {
            let r = try await IMController.shared.searchGroupMembers(param: param)
            
            return r
        } catch (let e) {
            return []
        }
        
        return []
    }
}
