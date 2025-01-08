
import ChatLayout
import Foundation
import OUICore
import Kingfisher

#if ENABLE_CALL
import OUICalling
#endif

final class DefaultChatController: ChatController {
    
    weak var delegate: ChatControllerDelegate?
    
    private let dataProvider: DataProvider
    
    private var typingState: TypingState = .idle
    
    private let dispatchQueue = DispatchQueue(label: "DefaultChatController", qos: .userInteractive)
    
    private var lasReceiptInfos: [ReceiptInfo]?
    
    private var groupReadedInfos: [GroupMessageReadInfo]? 
    
    private var unReadCount: Int = 0 
    
    private var lastReceivedString: String?
    
    private let receiverId: String 
    
    private let senderID: String 
    
    private let conversationType: ConversationType 
    
    private var conversation: ConversationInfo
    
    private var groupInfo: GroupInfo? 
    
    private var groupMembers: [GroupMemberInfo]?
    
    private var otherInfo: FriendInfo?
    
    private var me: UserInfo?
    
    private var messages: [MessageInfo] = []
    
    private var selecteMessages: [MessageInfo] = [] 

    private var selectedUsers: [String] = [] 
    
    private var isAdminOrOwner = false
    
    private var canRevokeMessage = false
        
    private var mutedTimer: Timer?
    
    private var recvMessageIsCurrentChat = false
        
    init(dataProvider: DataProvider, senderID: String, conversation: ConversationInfo) {
        self.dataProvider = dataProvider
        self.receiverId = conversation.conversationType == .c2c ?
        conversation.userID! : conversation.groupID!
        self.senderID = senderID
        self.conversationType = conversation.conversationType
        self.conversation = conversation
    }
    
    deinit {
        iLogger.print("\(type(of: self)) - \(#function)")
        mutedTimer = nil
        clearUnreadCount()
        resetGroupPrefix()
        unSubscribeUsersStatus()
        FileDownloadManager.manager.pauseAllDownloadRequest()
    }

    
    func loadInitialMessages(completion: @escaping ([Section]) -> Void) {
        dataProvider.loadInitialMessages { [weak self] messages in
            self?.appendConvertingToMessages(messages, removeAll: true)
            self?.markAllMessagesAsReceived { [weak self] in
                self?.markAllMessagesAsRead { [weak self] in
                    self?.propagateLatestMessages { [weak self] sections in
                        completion(sections)
                        
                        guard let self else { return }
                        
                        if conversationType == .c2c {
                            self.getOtherInfo { [weak self] info in
                                self?.delegate?.friendInfoChanged(info: info)
                            }
                            
                            self.getInputStatus()
                        }
                        else if conversationType == .superGroup {
                            self.getGroupInfo(force: true) { [weak self] info in
                                self?.delegate?.groupInfoChanged(info: info)
                                self?.repopulateMessages(requiresIsolatedProcess: true)
                            }
                            self.getGroupMembers(userIDs: nil, memory: false) { _ in }
                            
                            self.resetGroupPrefix()
                        }
                        
                        if conversation.unreadCount != 0 {
                            iLogger.print("\(type(of: self)): \(#function) [\(#line)]")
                            self.markMessageAsReaded { [weak self] in
                                self?.getUnReadTotalCount()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadPreviousMessages(completion: @escaping ([Section]) -> Void) {
        dataProvider.loadPreviousMessages(completion: { [weak self] messages in
            self?.appendConvertingToMessages(messages)
            self?.markAllMessagesAsReceived { [weak self] in
                self?.markAllMessagesAsRead { [weak self] in
                    self?.propagateLatestMessages { [weak self]  sections in
                        completion(sections)
                    }
                }
            }
        })
    }
    
    func loadMoreMessages(completion: @escaping ([Section]) -> Void) {
        dataProvider.loadMoreMessages(completion: { [weak self] messages in
            self?.insertConvertingToMessages(messages)
            self?.markAllMessagesAsReceived { [weak self] in
                self?.markAllMessagesAsRead { [weak self] in
                    self?.propagateLatestMessages { [weak self]  sections in
                        completion(sections)
                    }
                }
            }
        })
    }
    
    func getTitle() {
        switch conversationType {
        case .undefine:
            break
        case .c2c:

            let otherInfo = FriendInfo()
            otherInfo.nickname = conversation.showName
            otherInfo.userID = receiverId
            delegate?.friendInfoChanged(info: otherInfo)
            
            subscribeUsersStatus()
        case .superGroup:

            let groupInfo = GroupInfo(groupID: receiverId, groupName: conversation.showName)
            delegate?.groupInfoChanged(info: groupInfo)
        case .notification:

            let otherInfo = FriendInfo()
            otherInfo.nickname = "SystemNotice".innerLocalized()
            otherInfo.userID = receiverId
            delegate?.friendInfoChanged(info: otherInfo)
        }
    }
    
    func messageIsExsit(with id: String) -> Bool {
        messages.contains(where: { $0.clientMsgID == id })
    }
    
    func defaultSelecteMessage(with id: String?, onlySelect: Bool = false) {
        if let id {
            selecteMessages.removeAll()
            if !onlySelect {
                resetSelectedStatus()
                selecteMessage(with: id)
            } else {
                seleteMessageHelper(with: id)
            }
            iLogger.print("selecteMessages: \(selecteMessages.map({ $0.clientMsgID }))")
        } else {
            if !onlySelect {
                resetSelectedStatus()
            }
            selecteMessages.removeAll()
        }
    }
    
    func defaultSelecteUsers(with usersID: [String]) {
        selectedUsers.append(contentsOf: usersID)
    }

    private func resetSelectedStatus() {
        messages.forEach { $0.isSelected = false }
    }
    
    func deleteMessage(completion: (() -> Void)?) {
        deleteMessage(requiresIsolatedProcess: true, completion: completion)
    }
    
    func deleteMessage(requiresIsolatedProcess: Bool = true, completion: (() -> Void)?) {

        let temp = selecteMessages
        selecteMessages.removeAll()
        
        deleteMessages(messages: temp) { [weak self] result in
            guard let self else { return }
            messages.removeAll { fm in
                return result.contains(where: { $0.clientMsgID == fm.clientMsgID })
            }
            completion?()
            repopulateMessages(requiresIsolatedProcess: true)
        }
    }
    
    func forwardMessage(merge: Bool, usersID: [String]?, groupsID: [String]?, title: String, attachMessage: String?) {
        
        let users = usersID ?? []
        let groups = groupsID ?? []
        
        var usersCount = users.count
        var groupsCount = groups.count
        
        func resetSelectedMessagesStatus() {
            if usersCount == 0 && groupsCount == 0 {
                selecteMessages.removeAll()
                resetSelectedStatus()
            }
        }
        
        users.forEach({ userID in
            if merge {
                sendMergeMessage(to: userID, or: nil, title: title, attachMessage: attachMessage) { [weak self] section in
                    usersCount -= 1
                    resetSelectedMessagesStatus()
                }
            } else {
                sendForwardMessage(to: userID, or: nil, attachMessage: attachMessage) { [weak self] section in
                    usersCount -= 1
                    resetSelectedMessagesStatus()
                }
            }
        })
        
        groups.forEach({ groupID in
            if merge {
                sendMergeMessage(to: nil, or: groupID, title: title, attachMessage: attachMessage) { [weak self] section in
                    groupsCount -= 1
                    resetSelectedMessagesStatus()
                }
            } else {
                sendForwardMessage(to: nil, or: groupID, attachMessage: attachMessage) { [weak self] section in
                    groupsCount -= 1
                    resetSelectedMessagesStatus()
                }
            }
        })
    }
    
    func getConversation() -> ConversationInfo {
        return conversation
    }
    
    func getGroupMembers(userIDs: [String]?, memory: Bool, completion: @escaping ([GroupMemberInfo]) -> Void) {
        if memory, let userIDs {
            if let ms = groupMembers?.filter({ userIDs.contains($0.userID!)} ) {
                completion(ms)
            }
        } else {
            if let userIDs {
                dataProvider.getGroupMembers(userIDs: userIDs, handler: completion, isAdminHandler: nil)
            } else {
                if groupMembers == nil {
                    dataProvider.getGroupMembers(userIDs: userIDs) { [weak self] ms in
                        completion(ms)
                        self?.groupMembers = ms
                    } isAdminHandler: { [weak self] admin in
                        self?.isAdminOrOwner = admin
                    }
                } else {
                    completion(groupMembers!)
                }
            }
        }
    }
    
    func getMentionUsers(completion: @escaping ([GroupMemberInfo]) -> Void) {
        getGroupMembers(userIDs: nil, memory: true) { ms in
            var us = ms.filter({ $0.userID != IMController.shared.uid })
            let metionAll = GroupMemberInfo()
            metionAll.userID = IMController.shared.atAllTag()
            metionAll.nickname = "所有人".innerLocalized()
            us.insert(metionAll, at: 0)
            
            completion(us)
        }
    }
    
    func getUsersInfo(userIDs: [String], completion: @escaping ([UserInfo]) -> Void) {
        IMController.shared.getUserInfo(uids: userIDs) { ps in
            completion(ps.map({ $0.toUserInfo() }))
        }
    }
    
    func getMentionAllFlag() -> (tag: String, text: String) {
        return (IMController.shared.atAllTag(), "everyone".innerLocalized())
    }
    
    func getMessageInfo(ids: [String]) -> [MessageInfo] {
        return messages.filter({ ids.contains($0.clientMsgID) })
    }
    
    private func getBasicInfo(completion: @escaping () -> Void) {
        if conversationType == .c2c {
            getOtherInfo { _ in
                completion()
            }
        } else {
            getGroupInfo(force: false) { _ in
                completion()
            }
        }
    }
    
    func getOtherInfo(completion: @escaping (FriendInfo) -> Void) {
        if otherInfo == nil {

            otherInfo = FriendInfo(userID: receiverId, nickname: conversation.showName)
            
            dataProvider.getUserInfo { [weak self] f in
                completion(f)
                self?.otherInfo = f
            } mine: { [weak self] u in
                self?.me = u
            }
            completion(otherInfo!)
        } else {
            completion(otherInfo!)
        }
    }

    func getGroupInfo(force: Bool, completion: @escaping (GroupInfo) -> Void) {
        if groupInfo == nil {

            groupInfo = GroupInfo(groupID: receiverId, groupName: conversation.showName)
            completion(groupInfo!)
        }
        
        if !force, groupInfo != nil {
            completion(groupInfo!)
            return
        }
        
        if me == nil {
            dataProvider.getUserInfo(otherInfo: nil, mine: { [weak self] info in
                self?.me = info
            })
        }
        
        dataProvider.getGroupInfo { [weak self] group in
            completion(group)
            self?.groupInfo = group
        }
    }
    
    func getSelectedMessages() -> [MessageInfo] {
        selecteMessages
    }
    
    func getSelfInfo() -> UserInfo? {
        IMController.shared.currentUserRelay.value
    }
    
    func getIsAdminOrOwner() -> Bool {
        isAdminOrOwner
    }
    
    func canRevokeMessage(msg: Message) -> Bool {
        guard case .sent(_) = msg.status else {
            return false
        }
        
        if conversationType == .c2c {
            
            return msg.type == .outgoing && msg.date.timeIntervalSinceNow > -24 * 60 * 60
        } else {
            if groupInfo?.isMine == true ||
                (isAdminOrOwner && msg.owner.id != groupInfo?.ownerUserID) {
                if case .text(let source) = msg.data {
                    return source.type != .notice
                }
                return true
            } else {
                return msg.type == .outgoing && msg.date.timeIntervalSinceNow > -24 * 60 * 60
            }
        }
    }
    
    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        let reqMsg = "\(IMController.shared.currentUserRelay.value!.nickname)请求添加你为好友"
        IMController.shared.addFriend(uid: receiverId, reqMsg: reqMsg, onSuccess: onSuccess, onFailure: onFailure)
    }

    func revokeMessage(with id: String, completion: @escaping (Bool) -> Void) {
        
        if var msg = messages.first(where: { $0.clientMsgID == id}) {
            let contentType = msg.contentType
            
            IMController.shared.revokeMessage(conversationID: conversation.conversationID,
                                              clientMsgID: id) { [weak self] r in
                guard let self, let r else {
                    completion(false)
                    
                    return
                }
                
                let info = MessageRevoked()
                info.clientMsgID = msg.clientMsgID
                info.revokerNickname = IMController.shared.currentUserRelay.value?.nickname
                info.revokerID = IMController.shared.currentUserRelay.value?.userID
                info.sourceMessageSendID = msg.sendID
                info.sourceMessageSendTime = msg.sendTime
                info.sourceMessageSenderNickname = msg.senderNickname
                info.revokeTime = NSDate().timeIntervalSince1970
                info.sessionType = msg.sessionType
                msg.content = JsonTool.toJson(fromObject: info)
                msg.contentType = .revoke
                
                if contentType == .text {
                    msg.contentType = contentType
                }
                
                completion(true)
                
                repopulateMessages(requiresIsolatedProcess: true)
            }
        }
    }
    
    func markMessageAsReaded(messageID: String? = nil, completion: (() -> Void)? = nil) {
        iLogger.print("\(type(of: self)) - \(#function)[\(#line)]")
        if messageID == nil, conversation.unreadCount == 0 {
            completion?()
    
            return
        }
        
        IMController.shared.markMessageAsReaded(byConID: conversation.conversationID) { [weak self] r in
            
            completion?()
        } onFailure: { errCode, errMsg in
            completion?()
        }
        
        if let messageID, conversationType == .superGroup, let groupInfo = groupInfo {
            resetGroupPrefix()
            
            if !groupInfo.displayIsRead {
                completion?()
                return
            }
            
            IMController.shared.sendGroupMessageReadReceipt(conversationID: conversation.conversationID, clientMsgIDs: [messageID]) { [weak self] r in
                completion?()
            }
        }
        
        if let msg = messages.first(where: { $0.clientMsgID == messageID}) {
            print("out message: markMessageAsReaded begin: \(msg.textElem?.content), \(msg.isRead)")
            let timestamp = Date().timeIntervalSince1970 * 1000
            msg.isRead = true
            msg.attachedInfoElem?.hasReadTime = timestamp
        }
    }
    
    func updateMessageLocalEx(messageID: String, ex: MessageEx) {
        let json = JsonTool.toJson(fromObject: ex)
        messages.first(where: { $0.clientMsgID == messageID })?.localEx = json
        IMController.shared.setMessageLocalEx(conversationID: conversation.conversationID, clientMsgID: messageID, ex: json)
    }
    
    func clearUnreadCount() {
        guard conversation.unreadCount > 0 else { return }
        
        iLogger.print("\(type(of: self)): \(#function) [\(#line)]")
        IMController.shared.markMessageAsReaded(byConID: conversation.conversationID) { r in
            
        }
    }
    
    func saveDraft(text: String?) {
        if text?.isEmpty == true {
            if conversation.draftText?.isEmpty == false {
                conversation.draftText = text ?? ""
                IMController.shared.saveDraft(conversationID: conversation.conversationID, text: text)
            }
        } else {
            conversation.draftText = text ?? ""
            IMController.shared.saveDraft(conversationID: conversation.conversationID, text: text)
        }
    }
    
    func uploadFile(image: UIImage, progress: @escaping (CGFloat) -> Void, completion: @escaping (String?) -> Void) {
        let r = FileHelper.shared.saveImage(image: image)

        IMController.shared.uploadFile(fullPath: r.fullPath) { p in
            progress(p)
        } onSuccess: { [weak self] r in
            if let r {
                KingfisherManager.shared.cache.store(image, forKey: r)
            }
            completion(r)
        }
    }
    
    func typing(doing: Bool) {
        guard conversation.conversationType == .c2c else { return }

        IMController.shared.typingStatusUpdate(conversationID: conversation.conversationID, focus: doing)
    }

    
    func searchLocalMediaMessage(completion: @escaping ([Message]) -> Void) {
        IMController.shared.searchLocalMessages(conversationID: conversation.conversationID, messageTypes: [.image, .video,]) { [weak self] ms in
            guard let self else { return }
            let result = ms.reversed().flatMap({ self.convertMessage($0) })
            
            completion(result)
        }
    }

    
    func sendMessage(_ data: Message.Data, completion: @escaping ([Section]) -> Void) {
        switch data {
        case .text(let source):
            let quoteMsg = selecteMessages.first
            
            if selectedUsers.count > 0 {
                sendAtMessage(text: source.text, quoteMessage: quoteMsg, completion: completion)
            } else {
                sendText(text: source.text, quoteMessage: quoteMsg, completion: completion)
            }
            saveDraft(text: nil)
        case .url(let url, isLocallyStored: _):
            break
            
        case .image(let source, isLocallyStored: _):
            sendImage(source: source, completion: completion)
            
        case .video(let source, isLocallyStored: _):
            sendVideo(source: source, completion: completion)
            
        case .audio(let source, isLocallyStored: _):
            sendAudio(source: source, completion: completion)
    
        case .file(let source, isLocallyStored: let isLocallyStored):
            sendFile(source: source, completion: completion)
            
        case .card(let source):
            sendCard(user: source.user, completion: completion)
            
        case .location(let source):
            sendLocation(location: source, completion: completion)
            
        case .face(let source, _):
            sendFace(face: source, completion: completion)
                            
        case .attributeText(_), .custom(_), .notice(_), .none:
            break
        }
    }
    
    private func resend(messageID: String) {
        guard let index = messages.firstIndex(where: { $0.clientMsgID == messageID }) else { return }
        
        IMController.shared.sendMessage(message: messages[index], to: receiverId, conversationType: conversationType) { [weak self] r in
            if r.status != .sendFailure {
                self?.messages[index] = r
                self?.repopulateMessages(requiresIsolatedProcess: false)
            }
        }
    }
    
    private func sendText(text: String, to: String? = nil, conversationType: ConversationType? = nil, quoteMessage: MessageInfo? = nil, completion: (([Section]) -> Void)?) {
        IMController.shared.sendTextMessage(text: text,
                                            quoteMessage: quoteMessage,
                                            to: to ?? receiverId,
                                            conversationType: conversationType ?? self.conversationType) { [weak self] msg in
            guard let completion else { return }
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            guard let completion else { return }

                self?.appendMessage(msg, completion: completion)
                self?.selecteMessages.removeAll()
                self?.selectedUsers.removeAll()

        }
    }
    
    private func sendImage(source: MediaMessageSource, completion: @escaping ([Section]) -> Void) {
        
        var path = source.source.url!.path
        path = path.hasPrefix("file://") ? path : "file://" + path
        
        DefaultImageCacher.cacheLocalData(path: path) { [self] data in
            if data?.imageFormat == .gif {
                IMController.shared.sendImageMessage(path: source.source.relativePath!,
                                                     to: receiverId,
                                                     conversationType: conversationType) { [weak self] msg in
                    self?.appendMessage(msg, completion: completion)
                } onComplete: { [weak self] msg in

                    if let data, let thumbUrl = msg.pictureElem?.snapshotPicture?.url?.defaultThumbnailURLString,
                       let url = msg.pictureElem?.sourcePicture?.url {
                        DefaultImageCacher.cacheLoacalGIF(path: thumbUrl, data: data)
                        DefaultImageCacher.cacheLoacalGIF(path: url, data: data)
                    }
                    self?.appendMessage(msg, completion: completion)
                }
            } else {
                IMController.shared.sendImageMessage(path: source.source.relativePath!,
                                                     to: receiverId,
                                                     conversationType: conversationType) { [weak self] msg in
                    self?.appendMessage(msg, completion: completion)
                } onComplete: { [weak self] msg in

                    if let data, let image = UIImage(data: data), 
                        let thumbUrl = msg.pictureElem?.snapshotPicture?.url?.defaultThumbnailURLString,
                       let url = msg.pictureElem?.sourcePicture?.url {
                        DefaultImageCacher.cacheLocalImage(path: thumbUrl, image: image)
                        DefaultImageCacher.cacheLocalImage(path: url, image: image)
                    }
                    self?.appendMessage(msg, completion: completion)
                }
            }
        }
    }
    
    private func sendVideo(source: MediaMessageSource, completion: @escaping ([Section]) -> Void) {
        
        var path = source.thumb!.url.path
        let image = DefaultImageCacher.cacheLocalImage(path: path)
                
        IMController.shared.sendVideoMessage(path: source.source.relativePath!,
                                             duration: source.duration!,
                                             snapshotPath: (source.thumb?.url.relativeString)!,
                                             to: receiverId,
                                             conversationType: conversationType) { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            if let image, let snapshotUrl = msg.videoElem?.snapshotUrl {
                DefaultImageCacher.cacheLocalImage(path: snapshotUrl, image: image)
                DefaultImageCacher.cacheLocalImage(path: snapshotUrl.defaultThumbnailURLString, image: image)
            }
            self?.appendMessage(msg, completion: completion)
        }
    }
    
    private func sendAudio(source: MediaMessageSource, completion: @escaping ([Section]) -> Void) {
        IMController.shared.sendAudioMessage(path: source.source.relativePath!,
                                             duration: source.duration!,
                                             to: receiverId,
                                             conversationType: conversationType) { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        }
        
    }
    
    private func sendFile(source: FileMessageSource, completion: @escaping ([Section]) -> Void) {
        let filePath = source.url!.path
        
        IMController.shared.sendFileMessage(filePath: filePath,
                                            to: receiverId,
                                            conversationType: conversationType) { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        }
    }
    
    private func sendMergeMessage(to userID: String?, or groupID: String?, title: String, attachMessage: String? = nil, completion: @escaping ([Section]) -> Void) {
        assert(userID != nil || groupID != nil)
        
        let type: ConversationType = userID != nil ? .c2c : .superGroup
        let sourceID = (type == .c2c ? userID : groupID)!
        let tempSelectedMessages = selecteMessages.sorted(by: { $0.sendTime < $1.sendTime })
        
        IMController.shared.getConversation(sessionType: type, sourceId: sourceID) { [weak self] conversation in
            guard let self else { return }
            
            IMController.shared.sendMergeMessage(messages: tempSelectedMessages,
                                                 title: title,
                                                 to: sourceID,
                                                 conversationType: type) { [weak self] msg in
                if sourceID == self?.receiverId {
                    self?.appendMessage(msg, completion: completion)
                }
            } onComplete: { [weak self] msg in
                if sourceID == self?.receiverId {
                    if let attachMessage, !attachMessage.isEmpty {
                        self?.sendText(text: attachMessage, to: sourceID, conversationType: type) {_ in
                            self?.appendMessage(msg, completion: completion)
                        }
                    } else {
                        self?.appendMessage(msg, completion: completion)
                    }
                } else {
                    if let attachMessage, !attachMessage.isEmpty {
                        self?.sendText(text: attachMessage, to: sourceID, conversationType: type) {_ in
                        }
                    }
                    completion([])
                }
            }
        }
    }
    
    private func sendForwardMessage(to userID: String?, or groupID: String?, attachMessage: String? = nil, completion: @escaping ([Section]) -> Void) {
        assert(userID != nil || groupID != nil)
        
        let type: ConversationType = userID != nil ? .c2c : .superGroup
        let recvID = (type == .c2c ? userID : groupID)!

        let tempSelectedMessage = selecteMessages.first!
        tempSelectedMessage.status = .sendSuccess
        
        IMController.shared.sendForwardMessage(message: tempSelectedMessage,
                                               to: recvID,
                                               conversationType: type) { [weak self] msg in
            if recvID == self?.receiverId {
                self?.appendMessage(msg, completion: completion)
            }
        } onComplete: { [weak self] msg in
            if recvID == self?.receiverId {
                if let attachMessage, !attachMessage.isEmpty {
                    self?.sendText(text: attachMessage, to: recvID, conversationType: type) {_ in
                        self?.appendMessage(msg, completion: completion)
                    }
                } else {
                    self?.appendMessage(msg, completion: completion)
                }
            } else {
                if let attachMessage, !attachMessage.isEmpty {
                    self?.sendText(text: attachMessage, to: recvID, conversationType: type) {_ in
                    }
                }
                completion([])
            }
        }

    }
    
    private func sendCard(user: User, completion: @escaping ([Section]) -> Void) {
        let card = CardElem(userID: user.id, nickname: user.name, faceURL: user.faceURL)

        IMController.shared.sendCardMessage(card: card,
                                            to: receiverId,
                                            conversationType: conversationType) { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        }
    }
    
    private func sendLocation(location: LocationMessageSource, completion: @escaping ([Section]) -> Void) {
        IMController.shared.sendLocation(latitude: location.latitude,
                                         longitude: location.longitude,
                                         desc: location.desc,
                                         to: receiverId,
                                         conversationType: conversationType) { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        }
    }
    
    private func sendFace(face: FaceMessageSource, completion: @escaping ([Section]) -> Void) {
        let param = ["url": face.url.absoluteString, "width": 60, "height": 60] as [String : Any]
        if let json = try? JSONSerialization.data(withJSONObject: param, options: .fragmentsAllowed), let jsonStr = String(data: json, encoding: .utf8) {
            
            if let localPath = face.localPath {
                DefaultImageCacher.cacheLocalData(path: localPath)
            }
            
            IMController.shared.sendFaceMessage(data: jsonStr,
                                                index: -1,
                                                to: receiverId,
                                                conversationType: conversationType) { [weak self] msg in
                self?.appendMessage(msg, completion: completion)
            } onComplete: { [weak self] msg in
                self?.appendMessage(msg, completion: completion)
            }
        }
    }
    
    private func sendAtMessage(text: String, quoteMessage: MessageInfo? = nil, completion: @escaping ([Section]) -> Void) {
        
        var atUsers: [AtInfo] = []
        var tempText = text
        
        selectedUsers.forEach { id in
            if id == IMController.shared.atAllTag() {
                let atAllText = "所有人".innerLocalized();
                let all = IMController.shared.createAtAllFlag(displayText: atAllText)
                atUsers.append(all)
                tempText = tempText.replacingOccurrences(of: atAllText, with: id)
            }
            if let first = groupMembers?.first(where: { $0.userID == id }) {
                atUsers.append(AtInfo(atUserID: first.userID!, groupNickname: first.nickname!))
                tempText = tempText.replacingOccurrences(of: "@\(first.nickname!)", with: "@\(first.userID!)")
            }
        }
        
        if !selectedUsers.isEmpty {
            tempText += " " // There is a problem on the desktop/flutter side, "@member" must be followed by a space. eg: "@Jhon "
        }
        
        IMController.shared.sendAtTextMessage(text: tempText, atUsers: atUsers, quoteMessage: quoteMessage, to: receiverId, conversationType: conversationType) { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
        } onComplete: { [weak self] msg in
            self?.appendMessage(msg, completion: completion)
            self?.selecteMessages.removeAll()
            self?.selectedUsers.removeAll()
        }
    }

    private func appendMessage(_ message: MessageInfo, completion: @escaping ([Section]) -> Void) {

        var exist = false
        
        for (i, item) in messages.enumerated() {
            if item.clientMsgID == message.clientMsgID {
                messages[i] = message
                exist = true
                break
            }
        }
        
        if !exist {
            messages.append(message)
        }
        
        propagateLatestMessages(completion: completion)
    }
    
    private func replaceMessage(_ message: MessageInfo) {
        for (i, item) in messages.enumerated() {
            if item.clientMsgID == message.clientMsgID {
                messages[i] = message
                break
            }
        }
    }
    
    private func appendConvertingToMessages(_ rawMessages: [MessageInfo], removeAll: Bool = false) {

        if removeAll {
            messages.removeAll()
        }
        
        guard !rawMessages.isEmpty else { return }

        let validMessages = rawMessages.compactMap { msg -> MessageInfo? in
            guard let attachedInfo = msg.attachedInfoElem, attachedInfo.isPrivateChat else {
                return msg  // Non-private messages are valid by default
            }

            let hasReadTime = attachedInfo.hasReadTime

            if hasReadTime > 0 {
                let duration = attachedInfo.burnDuration == 0 ? 30 : attachedInfo.burnDuration
                let currentTime = NSDate().timeIntervalSince1970 * 1000
                let expirationTime = hasReadTime + (duration * 1000)
                let countdownTime = max(0, expirationTime - currentTime)

                return countdownTime > 0 ? msg : nil  // Only include if time left
            }

            return msg.isRead ? nil : msg  // Include unread messages if no read time set
        }

        messages.append(contentsOf: validMessages)
        messages.sort(by: { $0.sendTime < $1.sendTime })
        #if !DEBUG
        iLogger.print("\(#function)[\(messages.count)]: \(messages.map({ $0.clientMsgID }))")
        #endif
    }
    
    private func insertConvertingToMessages(_ rawMessages: [MessageInfo]) {
        var messages = messages
        messages.insert(contentsOf: rawMessages, at: 0)
        self.messages = messages.sorted(by: { $0.sendTime < $1.sendTime })
    }
    
    private func propagateLatestMessages(completion: @escaping ([Section]) -> Void) {
        dispatchQueue.async { [weak self] in
            guard let self else { return }

            let messagesSplitByDay = self.groupMessagesByDay(self.messages)
            let cells = self.createCellsFromGroupedMessages(messagesSplitByDay)

            DispatchQueue.main.async {
                completion([Section(id: 0, title: "", cells: cells)])
            }
        }
    }

    private func groupMessagesByDay(_ messages: [MessageInfo]) -> [[Message]] {
        let messagesSplitByDay = self.messages
            .map { self.convertMessage($0) }
            .reduce(into: [[Message]]()) { result, message in
                guard var section = result.last,
                      let prevMessage = section.last else {
                    let section = [message]
                    result.append(section)
                    return
                }
                if Calendar.current.isDate(prevMessage.date, equalTo: message.date, toGranularity: .hour) {
                    section.append(message)
                    result[result.count - 1] = section
                } else {
                    let section = [message]
                    result.append(section)
                }
            }
        
        return messagesSplitByDay
    }

    private func createCellsFromGroupedMessages(_ groupedMessages: [[Message]]) -> [Cell] {
        let cells = groupedMessages.enumerated().map { index, messages -> [Cell] in 
            var cells: [Cell] = Array(messages.enumerated().map { index, message -> [Cell] in 
                
                if message.contentType == .system, case .attributeText(let value) = message.data {
                    
                    let systemCell = Cell.systemMessage(SystemGroup(id: message.id, value: value))
                    return [systemCell]
                }
                
                return [.message(message, bubbleType: .normal)]
            }.joined())
            
            if let firstMessage = messages.first {
                let dateCell = Cell.date(DateGroup(id: firstMessage.id, date: firstMessage.date))
                cells.insert(dateCell, at: 0)
            }
            /*
            if self.typingState == .typing,
               index == groupedMessages.count - 1 {
                cells.append(.typingIndicator)
            }
            */
            return cells // Section(id: sectionTitle.hashValue, title: sectionTitle, cells: cells)
        }.joined()
        
        return Array(cells)
    }
    
    private func convertMessage(_ msg: MessageInfo) -> Message {
        
        func configStatus(_ msg: MessageInfo) -> MessageStatus {

            guard msg.status != .sendFailure else { return .sentFailure }
            guard msg.status != .sending else { return .sending }
            
            var info = AttachInfo(readedStatus: msg.sessionType == .c2c ? .signalReaded(msg.isRead) : .groupReaded(msg.isRead, msg.isRead))
            
            return .sent(info)
        }
        
        var type = msg.contentType.rawValue > MessageContentType.face.rawValue ? MessageRawType.system : MessageRawType.normal

        if msg.contentType == .custom && (msg.customElem?.type == .deletedByFriend || msg.customElem?.type == .blockedByFriend) {
            type = .system
        }
        
        return Message(id: msg.clientMsgID,
                       date: Date(timeIntervalSince1970: msg.sendTime / 1000),
                       contentType: type,
                       sessionType: msg.sessionType == .superGroup ? .group : (msg.sessionType == .notification ? .oaNotice : .single),
                       data: convert(msg),
                       owner: User(id: msg.sendID, name: msg.senderNickname ?? "", faceURL: msg.senderFaceUrl),
                       type: msg.isOutgoing ? .outgoing : .incoming,
                       status: configStatus(msg),
                       isSelected: msg.isSelected,
                       isAnchor: msg.isAnchor)
    }
    
    private func convert(_ msg: MessageInfo) -> Message.Data {
        
        do {
            var isSending = msg.serverMsgID == nil // To send locally, first render the message to the interface; after the sending is successful, replace the original message.
            
            switch msg.contentType {
                
            case .text:
                let textElem = msg.textElem!
                
                let source = TextMessageSource(text: textElem.content)
                
                return .text(source)
                
            case .image:
                let pictureElem = msg.pictureElem!
                let thumbURL = isSending ? pictureElem.sourcePath?.toFileURL() : URL(string: pictureElem.snapshotPicture?.url?.defaultThumbnailURLString ?? "")!
                let url = isSending ? pictureElem.sourcePath!.toFileURL() : pictureElem.sourcePicture!.url!.toURL()
                let isPresentLocally = KingfisherManager.shared.cache.isCached(forKey: thumbURL?.absoluteString ?? "")
                let size = CGSize(width: pictureElem.sourcePicture!.width, height: pictureElem.sourcePicture!.height)
                
                let source = MediaMessageSource(source: MediaMessageSource.Info(url: url, size: size), thumb: MediaMessageSource.Info(url: thumbURL, size: size))
                
                return .image(source, isLocallyStored: isPresentLocally)
                
            case .video:
                let videoElem = msg.videoElem!
                var localPath = videoElem.videoPath ?? ""
                
                var url = isSending ? localPath.toFileURL() : videoElem.videoUrl?.toURL()
                
                if !isSending {
                    let subPath = localPath.components(separatedBy: "Documents").last
                    let sandboxPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
                    localPath = sandboxPath + subPath!
                    
                    let localVideoCanLoad = FileManager.default.fileExists(atPath: localPath)
                    url = localVideoCanLoad ? localPath.toFileURL() : url
                }
                
                let thumbURL = isSending ? videoElem.snapshotPath!.toFileURL() : URL(string: videoElem.snapshotUrl?.defaultThumbnailURLString ?? "")
                let isPresentLocally = thumbURL == nil ? false : KingfisherManager.shared.cache.isCached(forKey: thumbURL!.absoluteString)
                let duration = msg.videoElem!.duration
                let size = CGSize(width: videoElem.snapshotWidth, height: videoElem.snapshotHeight)
                let fileSize = msg.videoElem?.videoSize

                let source = MediaMessageSource(source: MediaMessageSource.Info(url: url, size: size),
                                                thumb: MediaMessageSource.Info(url: thumbURL, size: size),
                                                duration: duration,
                                                fileSize: fileSize)
                
                return .video(source, isLocallyStored: isPresentLocally)
                
            case .audio:
                let soundElem = msg.soundElem!
                let url = isSending ? soundElem.soundPath!.toFileURL() : soundElem.sourceUrl!.toURL()!
                let duration = soundElem.duration
                let isLocallyStored = FileHelper.shared.exsit(path: url.relativeString) != nil
                
                var source = MediaMessageSource(source: MediaMessageSource.Info(url: url), duration: duration)

                if let ex = msg.localEx {
                    let ex = JsonTool.fromJson(ex, toClass: MessageEx.self)
                    source.ex = ex
                } else {
                    source.ex = MessageEx()
                }
                
                return .audio(source, isLocallyStored: isLocallyStored)
                
            case .file:
                let fileElem = msg.fileElem!
                let url = isSending ? fileElem.filePath?.toFileURL() : fileElem.sourceUrl!.toURL()
                
                let size = fileElem.fileSize
                let name = fileElem.fileName!

                var isLocallyStored = false
                if let filePath = fileElem.filePath {
                    isLocallyStored = FileHelper.shared.exsit(path: filePath, name: name) != nil
                    if !isLocallyStored, let url = fileElem.sourceUrl {
                        isLocallyStored = FileHelper.shared.exsit(path: url, name: name) != nil
                    }
                } else {
                    if let url = fileElem.sourceUrl {
                        isLocallyStored = FileHelper.shared.exsit(path: url, name: name) != nil
                    }
                }
                
                let source = FileMessageSource(url: url, length: size, name: name)
                
                return .file(source, isLocallyStored: isLocallyStored)
                
            case .card:
                let cardElem = msg.cardElem
                
                let source = CardMessageSource(user: User(id: cardElem?.userID ?? "", name: cardElem?.nickname ?? "", faceURL: cardElem?.faceURL ?? ""))
                
                return .card(source)
                
            case .location:
                let location = msg.locationElem!
                let longitude = location.longitude
                let latitude = location.latitude
                let desc = location.desc ?? ""
                
                let param = try? JSONSerialization.jsonObject(with: desc.data(using: .utf8)!) as? [String: Any]
                let name = param?["name"] as? String
                let address = param?["addr"] as? String
                let url = LocationViewController.getStaticMapURL(longitude: longitude, latitude: latitude)
                let source = LocationMessageSource(url: url, name: name, address: address, latitude: latitude, longitude: longitude)
                
                return .location(source)
        
            case .oaNotification:
                let noti = msg.notificationElem!
                
                let source = NoticeMessageSource(type:.oa, detail: noti.detail)
                
                return .notice(source)
                
            case .face:
                let faceElem = msg.faceElem!
                
                let temp = faceElem.url!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                let url = URL(string: temp)!
                let isPresentLocally = KingfisherManager.shared.cache.isCached(forKey: url.customThumbnailURL()!.absoluteString)
                
                let source = FaceMessageSource(url: url, index: 0)
                
                return .face(source, isLocallyStored: isPresentLocally)
                
            case .custom:
                let value = msg.customMessageDetailAttributedString
                
                if msg.customElem?.type == .deletedByFriend || msg.customElem?.type == .blockedByFriend {
                    
                    return .attributeText(value)
                } else {
                    let source = CustomMessageSource(data: msg.customElem?.data, attributedString: value)
                    
                    return .custom(source)
                }
            default:
                let value = msg.systemNotification()
                
                return .attributeText(value ?? NSAttributedString())
            }
        } catch (let e) {
            print("\(#function) throws error: \(e)")
        }
    }
        
    private func repopulateMessages(requiresIsolatedProcess: Bool = false) {
        propagateLatestMessages { [weak self] sections in
            self?.delegate?.update(with: sections, requiresIsolatedProcess: requiresIsolatedProcess)
        }
    }

    
    private func deleteMessages(messages: [MessageInfo], completion: @escaping ([MessageInfo]) -> Void) {
        var result: [MessageInfo] = []
        var count = 0
        
        for (i, msg) in messages.enumerated() {
            iLogger.print("\(#function) - \(i): \(msg.clientMsgID)")
            IMController.shared.deleteMessage(conversation: conversation.conversationID,
                                              clientMsgID: msg.clientMsgID) { [weak self] r in
                guard let self else { return }
                
                result.append(msg)
                count += 1
                
                if count == messages.count {
                    completion(result)
                }
            } onFailure: { errCode, errMsg in
                count += 1
                
                if errCode == 10005 {
                    result.append(msg)
                }
                
                if count == messages.count {
                    completion(result)
                }
            }
        }
    }

    private func getUnReadTotalCount() {
        IMController.shared.getTotalUnreadMsgCount { [weak self] count in
            self?.unReadCount = count
            self?.delegate?.updateUnreadCount(count: count)
        }
    }
    
    private func subscribeUsersStatus() {
        guard conversationType == .c2c else { return }
        
        IMController.shared.subscribeUsersStatus(userIDs: [receiverId]) { [weak self] status in
            guard let self, let s = status.first(where: { $0.userID == self.receiverId }) else { return }
            
            delegate?.onlineStatus(status: s)
        }
    }
    
    private func unSubscribeUsersStatus() {
        guard conversationType == .c2c else { return }
        
        IMController.shared.unsubscribeUsersStatus(userIDs: [receiverId]) { r in
            
        }
    }
    
    private func resetGroupPrefix() {        
        IMController.shared.resetConversationGroupAtType(conversationID: conversation.conversationID) { r in
            
        }
    }
    
    private func getInputStatus() {
        guard conversation.conversationType == .c2c else { return }
        
        IMController.shared.getInputStatus(conversationID: conversation.conversationID, userID: receiverId) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let platformIDs):
                
                self.typingState = !platformIDs.isEmpty ? .typing : .idle
                
                if self.typingState == .typing {
                    self.typingStateChanged(to: self.typingState)
                }
            case .failure(let err):
                self.typingState = .idle

                self.typingStateChanged(to: self.typingState)
            }
        }
    }
}

extension DefaultChatController: DataProviderDelegate {

    func conversationChanged(info: OUICore.ConversationInfo) {
        conversation = info
    }
    
    func unreadCountChanged(count: Int) {
        if !recvMessageIsCurrentChat {
            delegate?.updateUnreadCount(count: count)
        }
    }
    
    func groupMembersChanged(added: Bool, info: GroupMemberInfo) {
        if info.groupID == receiverId {
            if added {
                groupMembers?.append(info)
            } else {
                groupMembers?.removeAll(where: { $0.userID == info.userID })
            }
        }
    }
    
    func friendInfoChanged(info: OUICore.FriendInfo) {
        if info.userID == otherInfo?.userID {
            if otherInfo?.faceURL != info.faceURL {
                
                for msg in messages {
                    if msg.sendID == info.userID {
                        msg.senderFaceUrl = info.faceURL
                        msg.senderNickname = info.showName
                    }
                }
                repopulateMessages(requiresIsolatedProcess: true)
            }
            otherInfo = info
        }
        delegate?.friendInfoChanged(info: info)
    }
    
    func myUserInfoChanged(info: UserInfo) {
        for msg in messages {
            if msg.sendID == info.userID {
                msg.senderFaceUrl = info.faceURL
                msg.senderNickname = info.nickname
            }
        }
        repopulateMessages(requiresIsolatedProcess: true)
    }
    
    func groupMemberInfoChanged(info: GroupMemberInfo) {
        if info.isSelf {
        } else {
            if let index = groupMembers?.firstIndex(where: { $0.userID == info.userID }) {
                groupMembers![index] = info
            }
        }
        
        for msg in messages {
            if msg.sendID == info.userID {
                msg.senderFaceUrl = info.faceURL
                msg.senderNickname = info.nickname
            }
        }
        repopulateMessages(requiresIsolatedProcess: true)
    }
    
    func groupInfoChanged(info: GroupInfo) {
        groupInfo = info
        
        delegate?.groupInfoChanged(info: info)
    }
    
    func isInGroup(with isIn: Bool) {
        delegate?.isInGroup(with: isIn)
    }
    
    func received(messages: [MessageInfo], forceReload: Bool) {
        
        if forceReload {
            appendConvertingToMessages(messages, removeAll: true)
            markAllMessagesAsReceived { [weak self] in
                self?.markAllMessagesAsRead { [weak self] in
                    self?.repopulateMessages()
                }
            }
            
            return
        }
        
        guard let message = messages.first else { return }
        
        let sendID = message.sendID
        let receivID = message.recvID
        let msgGroupID = message.groupID
        let msgSessionType = message.sessionType
        let conversationType = conversation.conversationType
        let userID = conversation.userID
        let groupID = conversation.groupID
        
        let isCurSingleChat = msgSessionType == .c2c && conversationType == .c2c && (sendID == userID || sendID == IMController.shared.uid && receivID == userID)
        let isCurGroupChat = msgSessionType == .superGroup && conversationType == .superGroup && groupID == msgGroupID
        
        if isCurGroupChat || isCurSingleChat {
            recvMessageIsCurrentChat = true
            
            appendConvertingToMessages([message])
            markAllMessagesAsReceived { [weak self] in
                self?.markAllMessagesAsRead { [weak self] in
                    self?.repopulateMessages()
                }
            }
        } else {
            recvMessageIsCurrentChat = false

            if !message.isMine {
                unReadCount += 1

            }
        }
    }
    
    func receivedRevokedInfo(info: MessageRevoked) {
        for item in self.messages {
            if item.clientMsgID == info.clientMsgID {
                item.contentType = .revoke
                item.content = JsonTool.toJson(fromObject: info)
            }
            
            if item.contentType == .quote, item.quoteElem?.quoteMessage?.clientMsgID == info.clientMsgID {
                item.quoteElem?.quoteMessage?.contentType = .revoke
                item.quoteElem?.quoteMessage?.content = JsonTool.toJson(fromObject: info)
            }
        }
        
        repopulateMessages()
    }
    
    func typingStateChanged(to state: TypingState) {
        typingState = state
        delegate?.typingStateChanged(to: state)

    }
    
    func lastReadIdsChanged(signal receiptInfos: [ReceiptInfo]?, group readInfos: [GroupMessageReadInfo]?) {
        lasReceiptInfos = receiptInfos
        groupReadedInfos = readInfos
        markAllMessagesAsRead { [weak self] in
            self?.repopulateMessages(requiresIsolatedProcess: true)
        }
    }
    
    func lastReceivedIdChanged(to id: String) {
        lastReceivedString = id
        markAllMessagesAsReceived { [weak self] in

        }
    }
    
    func markAllMessagesAsReceived(completion: @escaping () -> Void) {
        completion()

    }
    
    func markAllMessagesAsRead(completion: @escaping () -> Void) {
        guard lasReceiptInfos?.isEmpty == false || groupReadedInfos?.isEmpty == false else {
            completion()
            return
        }
        
        if let info = groupInfo, !info.displayIsRead {
            completion()
            return
        }
        
        dispatchQueue.async { [weak self] in
            guard let self else { return }
            
            if let groupReadedInfos {
                for (_, item) in groupReadedInfos.enumerated() {
                    var msg = messages.first(where: { $0.clientMsgID == item.clientMsgID })
                    msg?.attachedInfoElem?.groupHasReadInfo?.unreadCount = item.unreadCount
                    msg?.attachedInfoElem?.groupHasReadInfo?.hasReadCount = item.hasReadCount
                }
            } else {
                self.messages = self.messages.map { [weak self] message in
                    guard let self, !message.isRead else { return message }
                    
                    for (_, item) in self.lasReceiptInfos!.enumerated() {
                        if item.msgIDList?.contains(message.clientMsgID) == true {
                            message.isRead = true
                            message.attachedInfoElem?.hasReadTime = Double(item.readTime)
                      
                            iLogger.print("\(type(of: self)) \(#function) clientMsgID: \(message.clientMsgID) isRead: \(message.isRead) hasReadTime: \(message.attachedInfoElem?.hasReadTime ?? 0) readTime: \(item.readTime) message.attachedInfoElem == nil: \(message.attachedInfoElem == nil)")
                            break
                        }
                    }
                    
                    return message
                }
            }
            groupReadedInfos = nil
            lasReceiptInfos?.removeAll()
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func onlineStatus(status: UserStatusInfo) {
        if conversationType == .c2c {
            delegate?.onlineStatus(status: status)
        }
    }
    
    func clearMessage() {
        messages.removeAll()
        repopulateMessages()
    }
}

extension DefaultChatController: ReloadDelegate {
    
    func reloadMessage(with id: String) {
        repopulateMessages()
    }
    
    func didTapContent(with id: String, data: Message.Data) {
        
        delegate?.didTapContent(with: id, data: data)
    }
    
    func resendMessage(messageID: String) {
        resend(messageID: messageID)
    }
    
    func removeMessage(messageID: String, completion:(() -> Void)?) {
        iLogger.print("\(type(of: self)) - \(#function)[\(#line)]: \(messageID)")
        defaultSelecteMessage(with: messageID)
        deleteMessage(completion: completion)
    }
}

extension DefaultChatController: EditingAccessoryControllerDelegate {

    func selecteMessage(with id: String) {
        seleteMessageHelper(with: id)
        repopulateMessages(requiresIsolatedProcess: true)
    }
    
    private func seleteMessageHelper(with id: String) {

        if let index = selecteMessages.firstIndex(where: { $0.clientMsgID == id}) {
            selecteMessages.remove(at: index)
            messages.first(where: { $0.clientMsgID == id})?.isSelected = false
        } else {
            if let item = messages.first(where: { $0.clientMsgID == id}) {
                item.isSelected = true 
                selecteMessages.append(item)
            }
        }
    }
}
