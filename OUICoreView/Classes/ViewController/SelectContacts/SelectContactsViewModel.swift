
import OUICore
import RxRelay
import RxSwift
#if ENABLE_ORGANIZATION
import OUIOrganization 
#endif

class SelectContactsViewModel {    
    let tabSelected: BehaviorRelay<ContactType> = .init(value: .friends)
    let lettersRelay: BehaviorRelay<[String]> = .init(value: [])
    var contacts: [ContactInfo] = []
    var contactsSections: [[ContactInfo]] = []
    let loadingSubject: BehaviorSubject<Bool> = .init(value: false)

    private var friends: [ContactInfo] = []
    private var groups: [ContactInfo] = []
    private var members: [ContactInfo] = []
    private var staff: [ContactInfo] = []
    private let _disposeBag = DisposeBag()
    
    init() {
        tabSelected.subscribe(onNext: { [weak self] (type: ContactType) in
            guard let self else { return }
            
            switch type {
            case .friends:
                self.divideContactsInSection(self.friends)
            case .members:
                self.divideContactsInSection(self.members)
            case .groups:
                self.divideContactsInSection(self.groups)
            case .staff:
                self.divideContactsInSection(self.staff)
            default:
                break
            }
        }).disposed(by: _disposeBag)
    }
    
    func getMyFriendList() {
        loadingSubject.onNext(true)
        
        Task {
            var count = 1000
            contacts = []
            
            while (true) {
                let r = await IMController.shared.getFriendsSplit(offset: contacts.count, count: count)
                let temp = r.map{ContactInfo(ID: $0.userID, name: $0.nickname, faceURL: $0.faceURL, type: .user)}
                
                contacts.append(contentsOf: temp)
                divideContactsInSection(contacts)
                
                if r.count < count {
                    break
                }
            }
            
            friends = contacts
        
            await MainActor.run {
                loadingSubject.onNext(false)
            }
        }
    }
    
    func getGroups() {
        IMController.shared.getJoinedGroupList { [weak self] g in
            guard let self else { return }
            self.contacts = g.map{ContactInfo(ID: $0.groupID, name: $0.groupName, faceURL: $0.faceURL, type: .group)}
            self.groups.append(contentsOf: self.contacts)
            if self.tabSelected.value == .undefine { 
                self.divideContactsInSection(self.contacts)
            }
        }
    }
    
    func getGroupMemberList(groupID: String) {
        Task {
            let ms = await IMController.shared.getAllGroupMembers(groupID: groupID)

            contacts = ms.compactMap({ info in
                if !info.isSelf {
                    return ContactInfo(ID: info.userID, name: info.nickname, faceURL: info.faceURL, sub: info.roleLevelString, type: .user)
                } else {
                    return nil
                }
            })
            members.append(contentsOf: contacts)
            divideContactsInSection(contacts)
        }
    }
    
    func getContactAt(indexPaths: [IndexPath]) -> [ContactInfo] {
        var users: [ContactInfo] = []
        for indexPath in indexPaths {
            let user = contactsSections[indexPath.section][indexPath.row]
            users.append(user)
        }
        return users
    }
    
    func getContact(by ID: String) -> ContactInfo? {
        return contacts.first(where: {$0.ID == ID})
    }

    func getContactIndexPath(by ID: String) -> IndexPath? {
        for (row, objectRow) in contactsSections.enumerated() {
            for (col, object) in objectRow.enumerated() {
                if object.ID == ID {
                    return IndexPath(row: col, section: row)
                }
            }
        }
        return nil
    }

    private func divideContactsInSection(_ contacts: [ContactInfo]) {

        var categorizedUsers: [String: [ContactInfo]] = [:]
        
        for user in contacts {
            if let letter = user.name?.getFirstPinyinUppercaseCharactor() {
                if categorizedUsers[letter] != nil {
                    categorizedUsers[letter]!.append(user)
                } else {
                    categorizedUsers[letter] = [user]
                }
            }
        }
        
        var sections: [[ContactInfo]] = []
        
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
            contactsSections = sections
            lettersRelay.accept(sortedKeys)
        }
    }
}
