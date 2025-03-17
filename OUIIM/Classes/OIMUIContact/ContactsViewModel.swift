
import OUICore
import RxRelay
import RxSwift
import OUICoreView

#if ENABLE_ORGANIZATION
import OUIOrganization
#endif

public class ContactsViewModel {
    let newFriendCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let newGroupCountRelay: BehaviorRelay<Int> = .init(value: 0)
    let frequentContacts: BehaviorRelay<[ContactInfo]> = .init(value: [])
    private let _disposeBag = DisposeBag()
    let companyDepartments: BehaviorRelay<[Department]> = .init(value: [])
    
    init() {
        Observable.combineLatest(newFriendCountRelay, newGroupCountRelay) { (friendCount: Int, groupCount: Int) -> Int in
            friendCount + groupCount
        }.bind(to: IMController.shared.contactUnreadSubject).disposed(by: _disposeBag)

        IMController.shared.friendApplicationChangedSubject.subscribe(onNext: { [weak self] _ in
            self?.getFriendApplications()
        }).disposed(by: _disposeBag)

        IMController.shared.groupApplicationChangedSubject.subscribe(onNext: { [weak self] _ in
            self?.getGroupApplications()
        }).disposed(by: _disposeBag)

        IMController.shared.conversationChangedSubject.subscribe(onNext: { [weak self] (conversations: [ConversationInfo]) in
            var uList: [ContactInfo] = []
            for conversation in conversations {
                if conversation.conversationType == .c2c {
                    let user = ContactInfo(ID: conversation.userID!, name: conversation.showName, faceURL: conversation.faceURL)
                    uList.append(user)
                }
            }
            if !uList.isEmpty {
                IMController.shared.setFrequentUsers(uList)
                self?.getFrequentUsers()
            }
        }).disposed(by: _disposeBag)

        IMController.shared.friendInfoChangedSubject.subscribe(onNext: { [weak self] (userInfo: FriendInfo?) in
            guard let userInfo = userInfo, let sself = self else { return }
            var oldValues = sself.frequentContacts.value
            if let index = oldValues.firstIndex(where: { $0.ID == userInfo.userID }) {
                var nickname = userInfo.nickname
                if let remark = userInfo.remark {
                    nickname = nickname?.append(string: "(\(remark))")
                }
                let newValue = ContactInfo(ID: userInfo.userID, name: nickname, faceURL: userInfo.faceURL)
                oldValues[index] = newValue
                sself.frequentContacts.accept(oldValues)
            }
        }).disposed(by: _disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(applicationCountChangedHandler), name: ContactsViewModel.NotificationApplicationCountChanged, object: nil)
    }

    func getFriendApplications() {
        IMController.shared.getFriendApplicationListAsRecipient { [weak self] (applications: [FriendApplication]) in
            guard let self else { return }

            let ret = applications.compactMap { $0.handleResult == .normal ? $0 : nil }
            let result = ret.filter({ $0.createTime > ApplicationStorage.lastFriendApplicationReadTime })
            
            if result.isEmpty {
                newFriendCountRelay.accept(0)
            } else {
                newFriendCountRelay.accept(result.count)
                if let nowMax = ret.max(by: { $0.createTime < $1.createTime })?.createTime {
                    ApplicationStorage.lastFriendApplicationTime = nowMax
                }
            }
        }
    }

    func getGroupApplications() {
        IMController.shared.getGroupApplicationListAsRecipient { [weak self] (applications: [GroupApplicationInfo]) in
            guard let self else { return }

            let ret = applications.compactMap { $0.handleResult == .normal ? $0 : nil }
            let result = ret.filter({ $0.reqTime! > ApplicationStorage.lastGroupApplicationReadTime })
            
            if result.isEmpty {
                newGroupCountRelay.accept(0)
            } else {
                newGroupCountRelay.accept(result.count)
                if let nowMax = ret.max(by: { $0.reqTime! < $1.reqTime! })?.reqTime {
                    ApplicationStorage.lastGroupApplicationTime = nowMax
                }
            }
        }
    }

    func getFrequentUsers() {
        let items = IMController.shared.getFrequentUsers()
        frequentContacts.accept(items)
    }
    
    func queryMyDepartmentInfo() {
#if ENABLE_ORGANIZATION
        DispatchQueue.global(qos: .utility).async {
            var t: [Department] = []
            var t2: OrganizationInfo?
            var hasDept: Bool = true
            
            let group = DispatchGroup()
            
            group.enter()
            OUIOrganization.DefaultDataProvider.queryOrganizationInfo { info in
                t2 = info
                group.leave()
            }
            
            group.enter()

            OUIOrganization.DefaultDataProvider.queryDepartment() { (r: [DepartmentInfo]?) in
                if let r {
                    let toDepts = r.map({Department(isHost: true, id: $0.departmentID, name: $0.name)})
                    t.insert(contentsOf: toDepts, at: 0)
                }
                group.leave()
            }
            
            group.enter()
            OUIOrganization.DefaultDataProvider.queryUserInDepartment(userIDs: [IMController.shared.uid]) { r in
                if let r = r {
                    let d = r.map { Department(isHost: false, id: $0.department?.departmentID, name: $0.department?.name)}
                    t.append(contentsOf: d)
                } else {
                    hasDept = false
                }
                group.leave()
            }
            
            group.notify(queue: .main) { [weak self] in
                let canDisplay = t2?.name?.isEmpty != true && hasDept
                
                self?.companyDepartments.accept(canDisplay ? t : [])
            }
        }
#endif
    }

    @objc private func applicationCountChangedHandler() {
        getFriendApplications()
        getGroupApplications()
    }
    
    

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    static let NotificationApplicationCountChanged = NSNotification.Name(rawValue: "OIMNotificationApplicationCountChanged")

    struct Department {
        let isHost: Bool
        let id: String?
        let name: String?
    }
}

let lastFriendApplicationTimeKey = "lastFriendApplicationTimeKey"
let lastGroupApplicationTimeKey = "lastGroupApplicationTimeKey"

let lastFriendApplicationIsReadKey = "lastFriendApplicationIsReadKey"
let lastGroupApplicationIsReadKey = "lastGroupApplicationIsReadKey"

let exsitFriendApplicationKey = "exsitFriendApplicationKey"
let exsitGroupApplicationKey = "exsitGroupApplicationKey"

class ApplicationStorage: NSObject {
    
    static var exsitFriendApplication: Bool {
        get {
            UserDefaults.standard.bool(forKey: exsitFriendApplicationKey)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: exsitFriendApplicationKey)
        }
    }
    
    static var exsitGroupApplication: Bool {
        get {
            UserDefaults.standard.bool(forKey: exsitGroupApplicationKey)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: exsitGroupApplicationKey)
        }
    }
    
    static var lastFriendApplicationReadTime: Int {
        get {
            UserDefaults.standard.integer(forKey: lastFriendApplicationIsReadKey)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: lastFriendApplicationIsReadKey)
        }
    }
    
    static var lastGroupApplicationReadTime: Int {
        get {
            UserDefaults.standard.integer(forKey: lastGroupApplicationIsReadKey)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: lastGroupApplicationIsReadKey)
        }
    }
    
    
    static var lastFriendApplicationTime: Int {
        get {
            UserDefaults.standard.integer(forKey: lastFriendApplicationTimeKey)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: lastFriendApplicationTimeKey)
        }
    }
    
    static var lastGroupApplicationTime: Int {
        get {
            UserDefaults.standard.integer(forKey: lastGroupApplicationTimeKey)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: lastGroupApplicationTimeKey)
        }
    }
}
