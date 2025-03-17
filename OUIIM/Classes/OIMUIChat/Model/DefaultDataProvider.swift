
import Foundation
import UIKit
import OUICore
import RxSwift

#if ENABLE_CALL
import OUICalling
#endif

protocol DataProvider {
    
    func loadInitialMessages(completion: @escaping ([MessageInfo]) -> Void)
    
    func loadPreviousMessages(completion: @escaping ([MessageInfo]) -> Void)
    
    func loadMoreMessages(completion: @escaping ([MessageInfo]) -> Void)
    
    func getGroupInfo(groupInfoHandler: @escaping (GroupInfo) -> Void)
    
    func getGroupMembers(userIDs: [String]?, handler: @escaping ([GroupMemberInfo]) -> Void, isAdminHandler: ((Bool) -> Void)?)
    
    func getUserInfo(otherInfo: ((FriendInfo) -> Void)?, mine: ((UserInfo) -> Void)?)
    
    func isJoinedGroup(groupID: String, handler: @escaping (Bool) -> Void)
}

final class DefaultDataProvider: DataProvider {
    
    private let _disposeBag = DisposeBag()
    
    weak var delegate: DataProviderDelegate?
    
    private var startClientMsgID: String?
        
    private var reverseStartClientMsgID: String?
    
    private var isEnd = false
    
    private var reverseIsEnd = false

    private var conversation: ConversationInfo!
    
    private var startingTimestamp = Date().timeIntervalSince1970
        
    private let users: [String] = []
    
    private let receiverId: String!
    
    private var lastMessageIndex: Int = 0
    
    private var lastReadString: String?
    
    private var lastReceivedString: String?
    
    private let enableNewMessages = true
    
    private var anchorMessage: MessageInfo?
    
    private var messageStorage: [MessageInfo] = [] // message cache
    
    private let pageSize = 20
    
    init(conversation: ConversationInfo, anchorMessage: MessageInfo? = nil) {
        self.conversation = conversation
        self.receiverId = conversation.conversationType == .c2c ? conversation.userID! : conversation.groupID!
        self.anchorMessage = anchorMessage
        
        addObservers()
    }
    
    deinit {
        iLogger.print("\(type(of: self)) - \(#function)")
    }
    
    func loadInitialMessages(completion: @escaping ([MessageInfo]) -> Void) {
        if anchorMessage != nil {
            startClientMsgID = anchorMessage?.clientMsgID
            reverseStartClientMsgID = anchorMessage?.clientMsgID
            anchorMessage?.isAnchor = true
            
            var r = [anchorMessage!]
            
            getHistoryMessageListFromStorage(loadInitial: true, reverse: true) { ms in
                r = ms + r
                completion(r)
            }
        } else {
            startClientMsgID = nil
            getHistoryMessageListFromStorage(loadInitial: true, completion: completion)
        }
    }
    
    func loadPreviousMessages(completion: @escaping ([MessageInfo]) -> Void) {
        getHistoryMessageListFromStorage(completion: completion)
    }
    
    func loadMoreMessages(completion: @escaping ([MessageInfo]) -> Void) {
        guard let anchorMessage else {
            completion([])
            return
        }
        getHistoryMessageListFromStorage(reverse: true, completion: completion)
    }
    
    func getGroupInfo(groupInfoHandler: @escaping (GroupInfo) -> Void) {
        IMController.shared.getGroupInfo(groupIds: [receiverId]) { [weak self] (infos: [GroupInfo]) in
            guard let self, let groupInfo = infos.first else {
                return
            }
            groupInfoHandler(groupInfo)
            
            IMController.shared.isJoinedGroup(groupID: receiverId) { [self] isIn in
                self.delegate?.isInGroup(with: isIn)
            }
        }
    }
    
    func getGroupMembers(userIDs: [String]?, handler: @escaping ([GroupMemberInfo]) -> Void, isAdminHandler: ((Bool) -> Void)?) {
        
        if let userIDs, !userIDs.isEmpty {
            IMController.shared.getGroupMembersInfo(groupId: receiverId, uids: userIDs) { infos in
                handler(infos)
            }
        } else {
            Task {
                let ms = await IMController.shared.getAllGroupMembers(groupID: receiverId)
          
                await MainActor.run {
                    handler(ms)
                    
                    if let isAdminHandler, let r = ms.first(where: { $0.userID == IMController.shared.uid }) {
                        isAdminHandler(r.isOwnerOrAdmin)
                    }
                }
            }
        }
    }
    
    func isJoinedGroup(groupID: String, handler: @escaping (Bool) -> Void) {
        IMController.shared.isJoinedGroup(groupID: groupID) { r in
            handler(r)
        }
    }
    
    func getUserInfo(otherInfo: ((FriendInfo) -> Void)?, mine: ((UserInfo) -> Void)?) {
        if let me = IMController.shared.currentUserRelay.value {
            mine?(me)
        }
        if let otherInfo {
            IMController.shared.getFriendsInfo(userIDs: [receiverId]) { [weak self] friendInfos in
                guard let self else { return }
                
                if let friendInfo = friendInfos.first {
                    otherInfo(friendInfo)
                } else {
                    otherInfo(FriendInfo(userID: receiverId, nickname: conversation.showName, faceURL: conversation.faceURL))
                }
            }
        }
    }
    
    private func getHistoryMessageListFromStorage(loadInitial: Bool = false, reverse: Bool = false, completion: (([MessageInfo]) -> Void)?) {
        
        if loadInitial {
            getHistoryMessageList(reverse: reverse, count: reverse ? pageSize : pageSize * 4) { [weak self] ms in
                guard let self else { return }
                
                messageStorage.append(contentsOf: ms)
                let r = Array(messageStorage.suffix(pageSize))

                messageStorage.removeLast(r.count)
                
                completion?(r)
            }
        } else {
            if !messageStorage.isEmpty {
                let r = Array(messageStorage.suffix(pageSize))
                messageStorage.removeLast(r.count)
                
                completion?(r)
            }
            getHistoryMessageList(reverse: reverse, count: messageStorage.isEmpty ? pageSize : (reverse ? pageSize : pageSize * 3)) { [weak self] ms in
                guard let self else { return }
                
                if messageStorage.isEmpty {
                    messageStorage.insert(contentsOf: ms, at: 0)
                    
                    let r = Array(messageStorage.suffix(pageSize))
                    messageStorage.removeLast(r.count)
                    completion?(r)
                } else {
                    messageStorage.insert(contentsOf: ms, at: 0)
                }
            }
        }
    }
    
    private func getHistoryMessageList(reverse: Bool = false, count: Int = 20, completion: @escaping ([MessageInfo]) -> Void) {

        if reverse {
            guard !reverseIsEnd else {
                completion([])
                
                return
            }
            IMController.shared.getHistoryMessageListReverse(conversationID: conversation.conversationID,
                                                             startCliendMsgId: reverseStartClientMsgID,
                                                             count: count) { [weak self] isEnd, ms in
                guard let self else {
                    completion([])
                    return
                }
                self.reverseIsEnd = isEnd

                if ms.isEmpty {
                    completion([])
                } else {
                    self.reverseStartClientMsgID = ms.last?.clientMsgID
                    completion(ms)
                }
            }
        } else {
            guard !isEnd else {
                completion([])
                
                return
            }
            IMController.shared.getHistoryMessageList(conversationID: conversation.conversationID,
                                                      conversationType: conversation.conversationType,
                                                      startCliendMsgId: startClientMsgID,
                                                      count: count) { [weak self] isEnd, ms in
                guard let self else {
                    completion([])
                    return
                }
                
                self.isEnd = isEnd
                
                if ms.isEmpty {
                    completion([])
                } else {
                    self.startClientMsgID = ms.first?.clientMsgID
                    completion(ms)
                }
            }
        }
    }
    
    private func addObservers() {
#if ENABLE_CALL
        CallingManager.manager.endCallingHandler = { [weak self] msg in
            self?.receivedNewMessages(messages: [msg.toMessageInfo()])
        }
#endif
        IMController.shared.connectionRelay.skip(1).subscribe(onNext: { [weak self] value in
            guard value.status == .syncComplete, let self else { return }
            startClientMsgID = nil
            isEnd = false
            let count = messageStorage.count < pageSize  ? 4 * pageSize : messageStorage.count
            
            getHistoryMessageList(reverse: false, count: count) { [self] ms in
                self.messageStorage.removeAll()
                self.messageStorage.append(contentsOf: ms)
                
                self.delegate?.received(messages: ms, forceReload: true)
            }
            
        }).disposed(by: _disposeBag)
        
        IMController.shared.newMsgReceivedSubject.subscribe(onNext: { [weak self] (message: MessageInfo) in
            guard let self else { return }
            
            let con = IMController.shared.connectionRelay.value
            
            if con.status == .syncProgress, (message.recvID == conversation.userID || message.recvID == conversation.groupID) {
                let count = messageStorage.count < pageSize  ? 4 * pageSize : messageStorage.count
                
                IMController.shared.getHistoryMessageList(conversationID: conversation.conversationID,
                                                          conversationType: conversation.conversationType,
                                                          startCliendMsgId: nil,
                                                          count: count) { [weak self] seq, ms in
                    guard let self else { return }
                
                    receivedNewMessages(messages: ms, forceReload: true)
                }
            } else {
                receivedNewMessages(messages: [message])
            }
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupMemberInfoChange.subscribe(onNext: { [weak self] info in
            guard let self, let info, info.groupID == receiverId else { return }
            
            for msg in messageStorage {
                if msg.sendID == info.userID {
                    msg.senderNickname = info.nickname
                    msg.senderFaceUrl = info.faceURL
                }
            }
            
            delegate?.groupMemberInfoChanged(info: info)
        }).disposed(by: _disposeBag)
        
        IMController.shared.joinedGroupAdded.subscribe(onNext: { [weak self] info in
            guard let self, self.receiverId == info?.groupID else { return }
            
            delegate?.isInGroup(with: true)
            
        }).disposed(by: _disposeBag)
        
        IMController.shared.joinedGroupDeleted.subscribe(onNext: { [weak self] info in
            guard let self, self.receiverId == info?.groupID else { return }
            
            delegate?.isInGroup(with: false)
            
        }).disposed(by: _disposeBag)
        
        IMController.shared.friendInfoChangedSubject.subscribe(onNext:  { [weak self] (friendInfo: FriendInfo?) in
            guard let self, let friendInfo, friendInfo.userID == receiverId else { return }
            
            for msg in messageStorage {
                if msg.sendID == friendInfo.userID {
                    msg.senderNickname = friendInfo.showName
                    msg.senderFaceUrl = friendInfo.faceURL
                }
            }
            delegate?.friendInfoChanged(info: friendInfo)
        }).disposed(by: _disposeBag)
        
        IMController.shared.onBlackAddedSubject.subscribe(onNext:  { [weak self] (blcakInfo: BlackInfo?) in
            guard let blcakInfo else { return }
        }).disposed(by: _disposeBag)
        
        IMController.shared.onBlackDeletedSubject.subscribe(onNext:  { [weak self] (blcakInfo: BlackInfo?) in
            guard let blcakInfo else { return }
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupInfoChangedSubject.subscribe(onNext:  { [weak self] (groupInfo: GroupInfo?) in
            guard let groupInfo, groupInfo.groupID == self?.receiverId else { return }
            
            self?.delegate?.groupInfoChanged(info: groupInfo)
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupMemberAdded.subscribe(onNext:  { [weak self] member in
            guard let member, member.groupID == self?.receiverId else { return }
            
            self?.delegate?.groupMembersChanged(added: true, info: member)
        }).disposed(by: _disposeBag)
        
        IMController.shared.groupMemberDeleted.subscribe(onNext:  { [weak self] member in
            guard let member, member.groupID == self?.receiverId else { return }
            
            self?.delegate?.groupMembersChanged(added: false, info: member)
        }).disposed(by: _disposeBag)
        
        IMController.shared.totalUnreadSubject.subscribe(onNext: { [weak self] count in
            
            self?.delegate?.unreadCountChanged(count: count)
        }).disposed(by: _disposeBag)
        
        IMController.shared.currentUserRelay.subscribe(onNext: { [weak self] info in
            
            guard let info else { return }
            
            self?.delegate?.myUserInfoChanged(info: info)
        }).disposed(by: _disposeBag)
        
        IMController.shared.conversationChangedSubject.subscribe(onNext: { [weak self] conversations in
            guard let self, let info = conversations.first(where: ({ $0.conversationID == self.conversation.conversationID })) else { return }
            
            self.delegate?.conversationChanged(info: info)
        }).disposed(by: _disposeBag)
        
        JNNotificationCenter.shared.observeEvent { [weak self] (_: EventRecordClear) in
            self?.messageStorage.removeAll()
            self?.delegate?.clearMessage()
        }
    }
    
    private func receivedNewMessages(messages: [MessageInfo], forceReload: Bool = false) {
        guard enableNewMessages else {
            return
        }
        
        delegate?.received(messages: messages, forceReload: forceReload)
    }
}
