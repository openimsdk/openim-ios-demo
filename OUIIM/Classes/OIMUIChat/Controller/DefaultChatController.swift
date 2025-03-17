
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
        
    private let dispatchQueue = DispatchQueue(label: "DefaultChatController", qos: .userInteractive)
            
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
                        }
                        else if conversationType == .superGroup {
                            self.getGroupInfo(force: true) { [weak self] info in
                                self?.delegate?.groupInfoChanged(info: info)
                                self?.repopulateMessages(requiresIsolatedProcess: true)
                            }
                            self.getGroupMembers(userIDs: nil, memory: false) { _ in }
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
    
    func getUsersInfo(userIDs: [String], completion: @escaping ([UserInfo]) -> Void) {
        IMController.shared.getUserInfo(uids: userIDs) { ps in
            completion(ps.map({ $0.toUserInfo() }))
        }
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
    
    func addFriend(onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        let reqMsg = "\(IMController.shared.currentUserRelay.value!.nickname)请求添加你为好友"
        IMController.shared.addFriend(uid: receiverId, reqMsg: reqMsg, onSuccess: onSuccess, onFailure: onFailure)
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
            sendText(text: source.text, quoteMessage: quoteMsg, completion: completion)
            
        case .image(let source, isLocallyStored: _):
            sendImage(source: source, completion: completion)
            
        default:
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

    private func getUnReadTotalCount() {
        IMController.shared.getTotalUnreadMsgCount { [weak self] count in
            self?.unReadCount = count
            self?.delegate?.updateUnreadCount(count: count)
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
    
    func markAllMessagesAsReceived(completion: @escaping () -> Void) {
        completion()

    }
    
    func markAllMessagesAsRead(completion: @escaping () -> Void) {
        completion()
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
