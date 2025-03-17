
import OUICore
import RxRelay
import RxSwift

class ChatListViewModel {
    var conversationsRelay: BehaviorRelay<[ConversationInfo]> = .init(value: [])
    let loginUserPublish: PublishSubject<UserInfo?> = .init()
    let conversationStorage = ConversationStorage()
    private let pageSize = 300
    
    init() {
        addObserver()
        
        let c = conversationStorage.conversations
        if !c.isEmpty {
            refreshPartCoversations(newList: c) {
                conversationsRelay.accept(conversationStorage.conversations)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func getSelfInfo() {
        IMController.shared.getSelfInfo { [weak self] (userInfo: UserInfo?) in
            self?.loginUserPublish.onNext(userInfo)
        }
    }

    func getAllConversations() {
        Task {
            var temp: [ConversationInfo] = []
            
            while (true) {
                let result = await IMController.shared.getConversationsSplit(offset: temp.count, count: pageSize)
                
                temp.append(contentsOf: result)
                
                sortConversations(temp)
                
                if result.count < pageSize {
                    break
                }
            }
        }
    }
    
    func refreshPartCoversations(newList: [ConversationInfo], elseTodo: (() -> Void)) {
        if (newList.count > pageSize) {
            var tempList = newList
            
            while (true) {
                let temp = tempList.prefix(pageSize)
                
                var list = conversationsRelay.value
                list.insert(contentsOf: temp, at: 0)
                
                sortConversations(list)
                
                if tempList.count <= pageSize {
                    break
                }
                
                let range = 0..<pageSize
                tempList.removeSubrange(range)
            }
        } else {
            elseTodo()
        }
    }

    func setConversation(id: String, status: ReceiveMessageOpt) {
        IMController.shared.setConversationRecvMessageOpt(conversationID: id, status: status, completion: nil)
    }

    func addObserver() {
        IMController.shared.newConversationSubject.subscribe(onNext: { [weak self] (conversations: [ConversationInfo]) in
            guard let sself = self else { return }
            
            sself.refreshPartCoversations(newList: conversations) { [sself] in
                var origin = sself.conversationsRelay.value
                
                for (index, item) in conversations.enumerated() {
                    if !origin.contains(where: { info in
                        return info.conversationID == item.conversationID
                    }) {
                        origin.append(item)
                    }
                }
                
                sself.sortConversations(origin)
            }
        }).disposed(by: _disposeBag)

        IMController.shared.conversationChangedSubject.subscribe(onNext: { [weak self] (conversations: [ConversationInfo]) in
            guard let sself = self, !conversations.isEmpty else { return }
            
            sself.refreshPartCoversations(newList: conversations) { [sself] in
                
                let changedIds: [String] = conversations.compactMap { $0.conversationID }
                var origin = sself.conversationsRelay.value
                var ret = origin.filter { (chat: ConversationInfo) -> Bool in
                    !changedIds.contains(chat.conversationID)
                }
                
                iLogger.print("======conversationChangedSubject:\(conversations.first?.showName), unread count:\(conversations.first?.unreadCount)")
                ret.append(contentsOf: conversations)
                sself.sortConversations(ret)
            }
            
            DispatchQueue.global().async {
                var uList: [ContactInfo] = []
                for conversation in conversations {
                    if conversation.conversationType == .c2c {
                        let user = ContactInfo(ID: conversation.userID!, name: conversation.showName, faceURL: conversation.faceURL)
                        uList.append(user)
                    }
                }
                if !uList.isEmpty {
                    IMController.shared.setFrequentUsers(uList)
                }
            }
        }).disposed(by: _disposeBag)
        
        IMController.shared.currentUserRelay.subscribe { [weak self] info in
            guard let info else { return }
            self?.loginUserPublish.onNext(info)
        }.disposed(by: _disposeBag)

        JNNotificationCenter.shared.observeEvent { [weak self] (_: EventLoginSucceed) in
            self?.getAllConversations()
        }.disposed(by: _disposeBag)

        JNNotificationCenter.shared.observeEvent { [weak self] (_: EventRecordClear) in
            self?.getAllConversations()
        }
        
        JNNotificationCenter.shared.observeEvent { [weak self] (event: EventGroupDismissed) in
            guard let sself = self else { return }
            sself.removeConversation(event.conversationId)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func appWillTerminate() {
        let conversations = conversationsRelay.value
            
        if !conversations.isEmpty {
            conversationStorage.save(conversations)
        }
    }
    
    private func removeConversation(_ conversationID: String) {
        var origin = conversationsRelay.value
        
        var changed = false
        for (index, item) in conversationsRelay.value.enumerated() {
            if item.conversationID == conversationID {
                origin.remove(at: index)
                changed = true
            }
        }
        
        if changed {
            conversationsRelay.accept(origin)
        }
    }

    private func sortConversations(_ conversations: [ConversationInfo]) {
        var sorted = conversations.sorted { (lhs: ConversationInfo, rhs: ConversationInfo) in
            lhs.latestMsgSendTime > rhs.latestMsgSendTime
        }
        var pinned: [ConversationInfo] = []
        var normal: [ConversationInfo] = []
        for conversation in sorted {
            if conversation.isPinned {
                pinned.append(conversation)
            } else {
                normal.append(conversation)
            }
        }
        pinned.append(contentsOf: normal)
        conversationsRelay.accept(pinned)
    }
    
    func createSingleChat(userID: String, onComplete: @escaping (ConversationInfo) -> Void) {
        
        IMController.shared.getConversation(sessionType: .c2c, sourceId: userID) { [weak self] (conversation: ConversationInfo?) in
            guard let conversation else { return }

            onComplete(conversation)
        }
    }

    private let _disposeBag = DisposeBag()
}

class ConversationStorage {
    
    private var storeConversationsKey = "storeConversationsKey"
    
    init() {
        storeConversationsKey = "storeConversationsKey-\(IMController.shared.uid)"
    }
    
    var conversations: [ConversationInfo] {
        guard let json = UserDefaults.standard.object(forKey: storeConversationsKey) as? Data else { return [] }
        let conversations = try? JSONDecoder().decode([ConversationInfo].self, from: json)
        
        return conversations ?? []
    }
    
    func save(_ conversations: [ConversationInfo]) {
        let json = try? JSONEncoder().encode(conversations)
        UserDefaults.standard.set(json, forKey: storeConversationsKey)
        UserDefaults.standard.synchronize()
    }
}
