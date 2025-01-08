

import ChatLayout
import Foundation
import UIKit
import RxSwift


typealias TextMessageCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, TextMessageView, ChatAvatarView>>>

@available(iOS 13, *)
typealias URLCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, URLView, ChatAvatarView>>>

typealias ImageCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, ImageView, ChatAvatarView>>>
typealias VideoCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, VideoView, ChatAvatarView>>>
typealias AudioCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, AudioView, ChatAvatarView>>>
typealias FileCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, FileView, ChatAvatarView>>>
typealias CardCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, CardView, ChatAvatarView>>>
typealias LocationCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, LocationView, ChatAvatarView>>>
typealias NoticeCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, NoticeView, ChatAvatarView>>>
typealias OANoticeCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, OANoticeView, ChatAvatarView>>>
typealias CustomViewCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, CustomView, ChatAvatarView>>>
typealias BlankCustomViewCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<ChatAvatarView, BlankCustomView, ChatAvatarView>>>


typealias UserTitleCollectionCell = ContainerCollectionViewCell<SwappingContainerView<EdgeAligningView<UILabel>, UIImageView>>
typealias TitleCollectionCell = ContainerCollectionViewCell<SystemTipsView>
typealias TypingIndicatorCollectionCell = ContainerCollectionViewCell<MessageContainerView<EditingAccessoryView, MainContainerView<VoidViewFactory, TypingIndicator, VoidViewFactory>>>

typealias TextTitleView = ContainerCollectionReusableView<UILabel>

final class DefaultChatCollectionDataSource: NSObject, ChatCollectionDataSource {
    
    private var reloadDelegate: ReloadDelegate
    
    public unowned var gestureDelegate: GestureDelegate?
    
    private unowned var editingDelegate: EditingAccessoryControllerDelegate
    
    private let editNotifier: EditNotifier
    
    private let swipeNotifier: SwipeNotifier
            
    var sections: [Section] = [] {
        didSet {
            oldSections = oldValue
        }
    }
    
    var mediaImageViews: [String: Int] = [:]
    
    private var oldSections: [Section] = []
    
    init(editNotifier: EditNotifier,
         swipeNotifier: SwipeNotifier,
         reloadDelegate: ReloadDelegate,
         editingDelegate: EditingAccessoryControllerDelegate) {
        self.reloadDelegate = reloadDelegate
        self.editingDelegate = editingDelegate
        self.editNotifier = editNotifier
        self.swipeNotifier = swipeNotifier
    }
    
    deinit {
        print("====\(self) deinit")
    }
    
    func prepare(with collectionView: UICollectionView) {
        collectionView.register(TextMessageCollectionCell.self, forCellWithReuseIdentifier: TextMessageCollectionCell.reuseIdentifier)
        collectionView.register(ImageCollectionCell.self, forCellWithReuseIdentifier: ImageCollectionCell.reuseIdentifier)
        collectionView.register(VideoCollectionCell.self, forCellWithReuseIdentifier: VideoCollectionCell.reuseIdentifier)
        collectionView.register(AudioCollectionCell.self, forCellWithReuseIdentifier: AudioCollectionCell.reuseIdentifier)
        collectionView.register(FileCollectionCell.self, forCellWithReuseIdentifier: FileCollectionCell.reuseIdentifier)
        collectionView.register(CardCollectionCell.self, forCellWithReuseIdentifier: CardCollectionCell.reuseIdentifier)
        collectionView.register(LocationCollectionCell.self, forCellWithReuseIdentifier: LocationCollectionCell.reuseIdentifier)
        collectionView.register(NoticeCollectionCell.self, forCellWithReuseIdentifier: NoticeCollectionCell.reuseIdentifier)
        collectionView.register(OANoticeCollectionCell.self, forCellWithReuseIdentifier: OANoticeCollectionCell.reuseIdentifier)
        collectionView.register(CustomViewCollectionCell.self, forCellWithReuseIdentifier: CustomViewCollectionCell.reuseIdentifier)
        collectionView.register(BlankCustomViewCollectionCell.self, forCellWithReuseIdentifier: BlankCustomViewCollectionCell.reuseIdentifier)
        
        collectionView.register(UserTitleCollectionCell.self, forCellWithReuseIdentifier: UserTitleCollectionCell.reuseIdentifier)
        collectionView.register(TitleCollectionCell.self, forCellWithReuseIdentifier: TitleCollectionCell.reuseIdentifier)
        collectionView.register(TypingIndicatorCollectionCell.self, forCellWithReuseIdentifier: TypingIndicatorCollectionCell.reuseIdentifier)
        collectionView.register(TextTitleView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TextTitleView.reuseIdentifier)
        collectionView.register(TextTitleView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: TextTitleView.reuseIdentifier)
        if #available(iOS 13.0, *) {
            collectionView.register(URLCollectionCell.self, forCellWithReuseIdentifier: URLCollectionCell.reuseIdentifier)
        }
    }
    
    func didSelectItemAt(_ collectionView: UICollectionView, indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? TextMessageCollectionCell {
            
            let containerView = cell.customView
            
            if editNotifier.isEditing, let messageId = cell.customView.customView.contentContainer.contentView.customView.controller?.messageID {
                editingDelegate.selecteMessage(with: messageId)
                containerView.accessoryView?.toggleState()
            }
        } else if let cell = collectionView.cellForItem(at: indexPath) as? ImageCollectionCell {
            
            let containerView = cell.customView
            
            if editNotifier.isEditing, let messageId = cell.customView.customView.contentContainer.contentView.customView.controller?.messageID {
                editingDelegate.selecteMessage(with: messageId)
                containerView.accessoryView?.toggleState()
            }
        } else if let cell = collectionView.cellForItem(at: indexPath) as? VideoCollectionCell {
            
            let containerView = cell.customView
            
            if editNotifier.isEditing, let messageId = cell.customView.customView.contentContainer.contentView.customView.controller?.messageID {
                editingDelegate.selecteMessage(with: messageId)
                containerView.accessoryView?.toggleState()
            }
        } else if let cell = collectionView.cellForItem(at: indexPath) as? AudioCollectionCell {
            
            let containerView = cell.customView
            
            if editNotifier.isEditing, let messageId = cell.customView.customView.contentContainer.contentView.customView.controller?.messageID {
                editingDelegate.selecteMessage(with: messageId)
                containerView.accessoryView?.toggleState()
            }
        } else if let cell = collectionView.cellForItem(at: indexPath) as? FileCollectionCell {
            
            let containerView = cell.customView
            
            if editNotifier.isEditing, let messageId = cell.customView.customView.contentContainer.contentView.customView.controller?.messageID {
                editingDelegate.selecteMessage(with: messageId)
                containerView.accessoryView?.toggleState()
            }
        } else if let cell = collectionView.cellForItem(at: indexPath) as? CardCollectionCell {
            
            let containerView = cell.customView
            
            if editNotifier.isEditing, let messageId = cell.customView.customView.contentContainer.contentView.customView.controller?.messageID {
                editingDelegate.selecteMessage(with: messageId)
                containerView.accessoryView?.toggleState()
            }
        } else if let cell = collectionView.cellForItem(at: indexPath) as? LocationCollectionCell {
            
            let containerView = cell.customView
            
            if editNotifier.isEditing, let messageId = cell.customView.customView.contentContainer.contentView.customView.controller?.messageID {
                editingDelegate.selecteMessage(with: messageId)
                containerView.accessoryView?.toggleState()
            }
        } else if let cell = collectionView.cellForItem(at: indexPath) as? NoticeCollectionCell {
            

        } else if let cell = collectionView.cellForItem(at: indexPath) as? OANoticeCollectionCell {
            

        } else if let cell = collectionView.cellForItem(at: indexPath) as? CustomViewCollectionCell {
            
            let containerView = cell.customView
            
            if editNotifier.isEditing, let messageId = cell.customView.customView.contentContainer.contentView.customView.controller?.messageID {
                editingDelegate.selecteMessage(with: messageId)
                containerView.accessoryView?.toggleState()
            }
        }
    }
    
    private func onTapMessage(_ collectionView: UICollectionView, indexPath: IndexPath? = nil, messageID: String, data: Message.Data, useIndexPath: Bool = false) -> Bool {
        if editNotifier.isEditing, let indexPath {
            didSelectItemAt(collectionView, indexPath: indexPath)
            
            return false
        } else {
            if case .none = data, let indexPath {
                didSelectItemAt(collectionView, indexPath: indexPath)
            } else {
                if useIndexPath, let indexPath {
                } else {
                    gestureDelegate?.didTapContent(with: messageID, data: data)
                }
            }
        }
        
        return true
    }
    
    private func createTextCell(collectionView: UICollectionView,
                                message: Message,
                                indexPath: IndexPath,
                                text: String? = nil,
                                attributedString: NSAttributedString? = nil,
                                alignment: ChatItemAlignment,
                                bubbleType: Cell.BubbleType) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextMessageCollectionCell.reuseIdentifier, for: indexPath) as! TextMessageCollectionCell
        
        let container = cell.customView
        let mainMessageView = container.customView
        let bubbleView = mainMessageView.maskedView
        
        setupMessageContainerView(container, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(mainMessageView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType)
        setupSwipeHandlingAccessory(mainMessageView, date: message.date, accessoryConnectingView: cell.customView)
        
        let controller = TextMessageController(messageID: message.id,
                                               text: text,
                                               attributedString: attributedString,
                                               highlight: message.isAnchor,
                                               type: message.type,
                                               bubbleController: buildTextBubbleController(bubbleView: bubbleView,
                                                                                           messageType: message.type,
                                                                                           bubbleType: bubbleType))
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
            
            return nil;
        }
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        cell.delegate = bubbleView.customView
    
        return cell
    }
    
    @available(iOS 13, *)
    private func createURLCell(collectionView: UICollectionView, messageId: String, isSelected: Bool, indexPath: IndexPath, url: URL, date: Date, alignment: ChatItemAlignment, user: User, bubbleType: Cell.BubbleType, status: MessageStatus, messageType: MessageType,
                               sessionType: MessageSessionRawType) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: URLCollectionCell.reuseIdentifier, for: indexPath) as! URLCollectionCell
        setupMessageContainerView(cell.customView, messageId: messageId, isSelected: isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: user, date: date, messageID: messageId, alignment: alignment, bubble: bubbleType, status: status, sessionType: sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        
        setupSwipeHandlingAccessory(cell.customView.customView, date: date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = URLController(url: url,
                                       messageId: messageId,
                                       bubbleController: buildBezierBubbleController(for: bubbleView, messageType: messageType, bubbleType: bubbleType))
        
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        controller.delegate = reloadDelegate
        cell.delegate = bubbleView.customView
        
        return cell
    }
    
    private func createImageCell(collectionView: UICollectionView,
                                 message: Message,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 source: MediaMessageSource,
                                 forVideo: Bool = false,
                                 bubbleType: Cell.BubbleType) -> ImageCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionCell.reuseIdentifier, for: indexPath) as! ImageCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        
        setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = ImageController(source: source,
                                         messageID: message.id,
                                         bubbleController: buildBezierBubbleController(for: bubbleView, messageType: message.type, bubbleType: bubbleType))
        
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
        }
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        mediaImageViews[message.id] = message.id.hash
        
        return cell
    }
    
    private func createVideoCell(collectionView: UICollectionView,
                                 message: Message,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 source: MediaMessageSource,
                                 forVideo: Bool = false,
                                 bubbleType: Cell.BubbleType) -> VideoCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionCell.reuseIdentifier, for: indexPath) as! VideoCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        
        setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = VideoController(source: source,
                                         messageID: message.id,
                                         bubbleController: buildBezierBubbleController(for: bubbleView, messageType: message.type, bubbleType: bubbleType))
        
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
        }
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        mediaImageViews[message.id] = message.id.hash

        return cell
    }
    
    private func createAudioCell(collectionView: UICollectionView,
                                 message: Message,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 source: MediaMessageSource,
                                 forVideo: Bool = false,
                                 bubbleType: Cell.BubbleType) -> AudioCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AudioCollectionCell.reuseIdentifier, for: indexPath) as! AudioCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        
        setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = AudioController(source: source,
                                         messageID: message.id,
                                         messageType: message.type,
                                         bubbleController: buildTextBubbleController(bubbleView: bubbleView,
                                                                                     messageType: message.type,
                                                                                     bubbleType: bubbleType))
        
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        
        controller.onTap = { [weak self] data in
            return self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data, useIndexPath: true)
        }
        
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView

        return cell
    }
    
    private func createFileCell(collectionView: UICollectionView,
                                message: Message,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 source: FileMessageSource,
                                isLocallyStored: Bool = false,
                                 bubbleType: Cell.BubbleType) -> FileCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileCollectionCell.reuseIdentifier, for: indexPath) as! FileCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = FileController(source: source,
                                        isLocallyStored: isLocallyStored,
                                        messageID: message.id,
                                         bubbleController: buildBlankBubbleController(bubbleView: bubbleView,
                                                                                      messageType: message.type,
                                                                                     bubbleType: bubbleType))
        
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
        }
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        
        return cell
    }
    
    private func createCardCell(collectionView: UICollectionView,
                                message: Message,
                                indexPath: IndexPath,
                                source: CardMessageSource,
                                alignment: ChatItemAlignment,
                                bubbleType: Cell.BubbleType) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCollectionCell.reuseIdentifier, for: indexPath) as! CardCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = CardController(source: source,
                                        messageID: message.id,
                                             bubbleController: buildBlankBubbleController(bubbleView: bubbleView,
                                                                                          messageType: message.type,
                                                                                         bubbleType: bubbleType))
        
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
        }
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        
        return cell
    }
    
    private func createLocationCell(collectionView: UICollectionView,
                                    message: Message,
                                    indexPath: IndexPath,
                                    source: LocationMessageSource,
                                    alignment: ChatItemAlignment,
                                    bubbleType: Cell.BubbleType) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LocationCollectionCell.reuseIdentifier, for: indexPath) as! LocationCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = LocationController(source: source,
                                            messageID: message.id,
                                             bubbleController: buildBlankBubbleController(bubbleView: bubbleView,
                                                                                          messageType: message.type,
                                                                                         bubbleType: bubbleType))
        
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
        }
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        
        return cell
    }
    
    private func createGroupNoticeCell(collectionView: UICollectionView,
                                       message: Message,
                                       indexPath: IndexPath,
                                       source: TextMessageSource,
                                       alignment: ChatItemAlignment,
                                       bubbleType: Cell.BubbleType) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoticeCollectionCell.reuseIdentifier, for: indexPath) as! NoticeCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: false, enableSelected: false, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = NoticeViewController(text: source.text,
                                             bubbleController: buildBlankBubbleController(bubbleView: bubbleView,
                                                                                          messageType: message.type,
                                                                                         bubbleType: bubbleType))
        
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
        }
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        
        return cell
    }
    
    private func createNoticeCell(collectionView: UICollectionView,
                                  message: Message,
                                indexPath: IndexPath,
                                source: NoticeMessageSource,
                                alignment: ChatItemAlignment,
                                bubbleType: Cell.BubbleType) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OANoticeCollectionCell.reuseIdentifier, for: indexPath) as! OANoticeCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        
        let bubbleView = cell.customView.customView.maskedView
        let controller = OANoticeViewController(messageID: message.id,
                                                source: source,
                                             bubbleController: buildBlankBubbleController(bubbleView: bubbleView,
                                                                                          messageType: message.type,
                                                                                         bubbleType: bubbleType))
        
        controller.delegate = reloadDelegate
        
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
        }
        
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        
        return cell
    }
    
    private func createCustomCell(collectionView: UICollectionView,
                                  message: Message,
                                  indexPath: IndexPath,
                                  source: CustomMessageSource,
                                  alignment: ChatItemAlignment,
                                  bubbleType: Cell.BubbleType) -> UICollectionViewCell {
        
        if source.type == .meeting {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BlankCustomViewCollectionCell.reuseIdentifier, for: indexPath) as! BlankCustomViewCollectionCell
            
            setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
            setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
                self?.didSelectItemAt(collectionView, indexPath: indexPath)
            }
            setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
            
            let bubbleView = cell.customView.customView.maskedView
            
            let bubbleController = buildBlankBubbleController(bubbleView: bubbleView, messageType: message.type, bubbleType: bubbleType)
            
            let controller = CustomViewController(source: source,
                                                  messageID: message.id,
                                                  highlight: message.isAnchor,
                                                  type: message.type,
                                                  bubbleController: bubbleController)
            
            controller.longPress = { [weak self] sourceView, point in
                self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
            }
            controller.onTap = { [weak self] data in
                self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
            }
            bubbleView.customView.setup(with: controller)
            controller.delegate = reloadDelegate
            cell.delegate = bubbleView.customView
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomViewCollectionCell.reuseIdentifier, for: indexPath) as! CustomViewCollectionCell
            
            setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
            setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
                self?.didSelectItemAt(collectionView, indexPath: indexPath)
            }
            setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
            
            let bubbleView = cell.customView.customView.maskedView
            
            let bubbleController = buildTextBubbleController(bubbleView: bubbleView, messageType: message.type, bubbleType: bubbleType)
            
            let controller = CustomViewController(source: source,
                                                  messageID: message.id,
                                                  highlight: message.isAnchor,
                                                  type: message.type,
                                                  bubbleController: bubbleController)
            
            controller.longPress = { [weak self] sourceView, point in
                self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
            }
            controller.onTap = { [weak self] data in
                self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data)
            }
            bubbleView.customView.setup(with: controller)
            controller.delegate = reloadDelegate
            cell.delegate = bubbleView.customView
            
            return cell
        }
    }
    
    private func createFaceCell(collectionView: UICollectionView,
                                message: Message,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 source: FaceMessageSource,
                                 forVideo: Bool = false,
                                 bubbleType: Cell.BubbleType) -> ImageCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCollectionCell.reuseIdentifier, for: indexPath) as! ImageCollectionCell
        
        setupMessageContainerView(cell.customView, messageId: message.id, isSelected: message.isSelected, alignment: alignment)
        setupMainMessageView(cell.customView.customView, user: message.owner, date: message.date, messageID: message.id, alignment: alignment, bubble: bubbleType, status: message.status, sessionType: message.sessionType) { [weak self] in
            self?.didSelectItemAt(collectionView, indexPath: indexPath)
        }
        
        setupSwipeHandlingAccessory(cell.customView.customView, date: message.date, accessoryConnectingView: cell.customView)
        
        let imageSrouce = MediaMessageSource(source: MediaMessageSource.Info(url: source.url), thumb: MediaMessageSource.Info(url: source.url), ex: MessageEx(isFace: true))
        let bubbleView = cell.customView.customView.maskedView
        let controller = ImageController(source: imageSrouce,
                                         messageID: message.id,
                                         bubbleController: buildBezierBubbleController(for: bubbleView, messageType: message.type, bubbleType: bubbleType))
        
        controller.longPress = { [weak self] sourceView, point in
            self?.gestureDelegate?.longPress(with: message, sourceView: sourceView, point: point)
        }
        controller.onTap = { [weak self] data in
            self?.onTapMessage(collectionView, indexPath: indexPath, messageID: message.id, data: data, useIndexPath: true)
        }
        controller.delegate = reloadDelegate
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.delegate = bubbleView.customView
        mediaImageViews[message.id] = message.id.hash

        return cell
    }
    
    private func createTypingIndicatorCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TypingIndicatorCollectionCell.reuseIdentifier, for: indexPath) as! TypingIndicatorCollectionCell
        let alignment = ChatItemAlignment.leading
        cell.customView.alignment = alignment
        let bubbleView = cell.customView.customView.maskedView
        
        let controller = TypingIndicatorController(bubbleController: buildBlankBubbleController(bubbleView: bubbleView,
                                                                                                messageType: .incoming,
                                                                                                bubbleType: .normal))
        bubbleView.customView.setup(with: controller)
        controller.view = bubbleView.customView
        cell.customView.accessoryView?.isHiddenSafe = true
        
        return cell
    }

    private func createGroupTitle(collectionView: UICollectionView, indexPath: IndexPath, alignment: ChatItemAlignment, title: String) -> UserTitleCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserTitleCollectionCell.reuseIdentifier, for: indexPath) as! UserTitleCollectionCell
        cell.customView.spacing = 2
        
        cell.customView.customView.customView.text = title
        cell.customView.customView.customView.preferredMaxLayoutWidth = (collectionView.collectionViewLayout as? CollectionViewChatLayout)?.layoutFrame.width ?? collectionView.frame.width
        cell.customView.customView.customView.font = .f10
        cell.customView.customView.flexibleEdges = [.top]
        cell.customView.accessoryView.isHidden = true
        cell.contentView.layoutMargins = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 52)
        
        return cell
    }

    private func createTipsTitle(collectionView: UICollectionView,
                                 indexPath: IndexPath,
                                 alignment: ChatItemAlignment,
                                 title: String? = nil,
                                 attributeTitle: NSAttributedString? = nil, 
                                 enableBackgroundColor: Bool = false) -> TitleCollectionCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitleCollectionCell.reuseIdentifier, for: indexPath) as! TitleCollectionCell
        
        let bubbleView = cell.customView
        let controller = SystemTipsViewController(text: title,
                                               attributedString: attributeTitle,
                                                  enableBackgroundColor: enableBackgroundColor)
        controller.onTap = { [weak self] data in
            self?.gestureDelegate?.didTapContent(with: "", data: data)
            
            return true
        }
        bubbleView.setup(with: controller)
        controller.delegate = reloadDelegate
        cell.delegate = bubbleView
        
        return cell
    }
    
    private let disposeBag = DisposeBag()

    private func setupMessageContainerView(_ messageContainerView: MessageContainerView<EditingAccessoryView, some Any>, messageId: String, isSelected: Bool, enableSelected: Bool = true, alignment: ChatItemAlignment) {

        messageContainerView.alignment = alignment
        if let accessoryView = messageContainerView.accessoryView {
            editNotifier.add(delegate: accessoryView)
            accessoryView.setIsEditing(editNotifier.isEditing)
            
            let controller = EditingAccessoryController(messageId: messageId)
            controller.view = accessoryView
            controller.delegate = editingDelegate
            accessoryView.setup(with: controller, isSelected: isSelected, enableSelected: enableSelected)
        }
    }
    
    private func setupMainMessageView(_ cellView: MainContainerView<ChatAvatarView, some Any, ChatAvatarView>,
                                      user: User,
                                      date: Date,
                                      messageID: String,
                                      alignment: ChatItemAlignment,
                                      bubble: Cell.BubbleType,
                                      status: MessageStatus,
                                      sessionType: MessageSessionRawType,
                                      onTap: (() -> Void)? = nil) {
        cellView.containerView.customView.onTap = onTap
        cellView.containerView.alignment = .top
        cellView.containerView.leadingView?.isHiddenSafe = !alignment.isIncoming
        cellView.containerView.leadingView?.alpha = alignment.isIncoming ? 1 : 0
        cellView.containerView.trailingView?.isHiddenSafe = alignment.isIncoming
        cellView.containerView.trailingView?.alpha = alignment.isIncoming ? 0 : 1
    
        cellView.contentContainer.setTitle(title: sessionType == .oaNotice ? user.name : "\(sessionType == .single ? "" : user.name) \(Date.timeString(date: date))", messageType: alignment.isIncoming ? .incoming : .outgoing)
        cellView.contentContainer.showStutusIndicator(false)
        
        switch status {
        case .sentFailure:
            cellView.contentContainer.showStutusIndicator(false)
        case .sending:
                cellView.contentContainer.showStutusIndicator()
        case .received:
            cellView.contentContainer.showStutusIndicator(false)
        case .sent(let info):
            cellView.contentContainer.showStutusIndicator(false)
        }
        
        if let avatarView = cellView.containerView.leadingView {
            let avatarViewController = AvatarViewController(user: user, bubble: bubble)
            avatarView.setup(with: avatarViewController)
            avatarViewController.view = avatarView
            
            avatarViewController.onTap = { [weak self] userID in
                self?.gestureDelegate?.didTapAvatar(with: user)
            }
        }
        
        if let avatarView = cellView.containerView.trailingView {
            let avatarViewController = AvatarViewController(user: user, bubble: bubble)
            avatarView.setup(with: avatarViewController)
            avatarViewController.view = avatarView
            
            avatarViewController.onTap = { [weak self] userID in
                self?.gestureDelegate?.didTapAvatar(with: user)
            }
        }
    }

    private func setupSwipeHandlingAccessory(_ cellView: MainContainerView<ChatAvatarView, some Any, ChatAvatarView>,
                                             date: Date,
                                             accessoryConnectingView: UIView) {
        cellView.accessoryConnectingView = accessoryConnectingView
        cellView.accessoryView.setup(with: DateAccessoryController(date: date))
        cellView.accessorySafeAreaInsets = swipeNotifier.accessorySafeAreaInsets
        cellView.swipeCompletionRate = swipeNotifier.swipeCompletionRate
        swipeNotifier.add(delegate: cellView)
    }
    
    private func buildFileBubbleController(bubbleView: BezierMaskedView<some Any>,
                                           messageType: MessageType,
                                           bubbleType: Cell.BubbleType) -> BubbleController {
        let textBubbleController = FileBubbleController(bubbleView: bubbleView, type: messageType, bubbleType: bubbleType)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: textBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
    
    private func buildReplyBubbleController(bubbleView: BezierMaskedView<some Any>,
                                           messageType: MessageType,
                                           bubbleType: Cell.BubbleType) -> BubbleController {
        let textBubbleController = ReplyBubbleController(bubbleView: bubbleView, type: messageType, bubbleType: bubbleType)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: textBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
    
    private func buildBlankBubbleController(bubbleView: BezierMaskedView<some Any>,
                                           messageType: MessageType,
                                           bubbleType: Cell.BubbleType) -> BubbleController {
        let textBubbleController = BlankBubbleController(bubbleView: bubbleView, type: messageType, bubbleType: bubbleType)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: textBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
    
    private func buildTextBubbleController(bubbleView: BezierMaskedView<some Any>,
                                           messageType: MessageType,
                                           bubbleType: Cell.BubbleType) -> BubbleController {
        let textBubbleController = TextBubbleController(bubbleView: bubbleView, type: messageType, bubbleType: bubbleType)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: textBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
    
    private func buildBezierBubbleController(for bubbleView: BezierMaskedView<some Any>,
                                             messageType: MessageType,
                                             bubbleType: Cell.BubbleType) -> BubbleController {
        let contentBubbleController = FullCellContentBubbleController(bubbleView: bubbleView)
        let bubbleController = BezierBubbleController(bubbleView: bubbleView, controllerProxy: contentBubbleController, type: messageType, bubbleType: bubbleType)
        return bubbleController
    }
}

extension DefaultChatCollectionDataSource: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].cells.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = sections[indexPath.section].cells[indexPath.item]
        switch cell {
            
        case let .date(group):
            let cell = createTipsTitle(collectionView: collectionView, indexPath: indexPath, alignment: cell.alignment, title: group.value, enableBackgroundColor: true)
            
            return cell
        case let .systemMessage(group):
            let cell = createTipsTitle(collectionView: collectionView, indexPath: indexPath, alignment: cell.alignment, attributeTitle: group.value)
            
            return cell
        case let .messageGroup(group):
            let cell = createGroupTitle(collectionView: collectionView, indexPath: indexPath, alignment: cell.alignment, title: group.title)
            
            return cell
        case let .message(message, bubbleType: bubbleType):
            switch message.data {
            case let .text(source):
                if source.type == .text {
                    let cell = createTextCell(collectionView: collectionView, message: message, indexPath: indexPath, text: source.text, attributedString: source.attributedText, alignment: cell.alignment, bubbleType: bubbleType)
                    
                    return cell
                } else {
                    let cell = createGroupNoticeCell(collectionView: collectionView, message: message, indexPath: indexPath, source: source, alignment: cell.alignment, bubbleType: bubbleType)
                    return cell
                }
            case let .attributeText(text):
                let cell = createTextCell(collectionView: collectionView, message: message, indexPath: indexPath, attributedString: text, alignment: cell.alignment, bubbleType: bubbleType)
                
                return cell
            case let .custom(source):
                let cell = createCustomCell(collectionView: collectionView, message: message, indexPath: indexPath, source: source, alignment: cell.alignment, bubbleType: bubbleType)
                
                return cell
                
            case let .url(url, isLocallyStored: _):
                if #available(iOS 13.0, *) {
                    return createURLCell(collectionView: collectionView, messageId: message.id, isSelected: message.isSelected, indexPath: indexPath, url: url, date: message.date, alignment: cell.alignment, user: message.owner, bubbleType: bubbleType, status: message.status, messageType: message.type, sessionType: message.sessionType)
                } else {
                    return createTextCell(collectionView: collectionView, message: message, indexPath: indexPath, text: url.absoluteString, alignment: cell.alignment, bubbleType: bubbleType)
                }
            case let .image(source, isLocallyStored: _):
                let cell = createImageCell(collectionView: collectionView, message: message, indexPath: indexPath, alignment: cell.alignment, source: source, bubbleType: bubbleType)
                
                return cell
            case let .video(source, isLocallyStored: _):
                let cell = createVideoCell(collectionView: collectionView, message: message, indexPath: indexPath, alignment: cell.alignment, source: source, bubbleType: bubbleType)
                
                return cell
            case let .audio(source, isLocallyStored: _):
                let cell = createAudioCell(collectionView: collectionView, message: message, indexPath: indexPath, alignment: cell.alignment, source: source, bubbleType: bubbleType)
                return cell
                
            case let .file(source, isLocallyStored: isLocallyStored):
                let cell = createFileCell(collectionView: collectionView, message: message, indexPath: indexPath, alignment: cell.alignment, source: source, isLocallyStored: isLocallyStored, bubbleType: bubbleType)
                
                return cell
            case let .card(source):
                let cell = createCardCell(collectionView: collectionView, message: message, indexPath: indexPath, source: source, alignment: cell.alignment, bubbleType: bubbleType)
                
                return cell
            case let .location(source):
                let cell = createLocationCell(collectionView: collectionView, message: message, indexPath: indexPath, source: source, alignment: cell.alignment, bubbleType: bubbleType)
                
                return cell
            case let .notice(source):
                let cell = createNoticeCell(collectionView: collectionView, message: message, indexPath: indexPath, source: source, alignment: cell.alignment, bubbleType: bubbleType)
                return cell
            case let .face(source, isLocallyStored: _):
                let cell = createFaceCell(collectionView: collectionView, message: message, indexPath: indexPath, alignment: cell.alignment, source: source, bubbleType: bubbleType)
                
                return cell
            default:
                fatalError()
            }
            
        case .typingIndicator:
            return createTypingIndicatorCell(collectionView: collectionView, indexPath: indexPath)
        default:
            fatalError()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: TextTitleView.reuseIdentifier,
                                                                       for: indexPath) as! TextTitleView
            view.customView.text = sections[indexPath.section].title
            view.customView.preferredMaxLayoutWidth = 300
            view.customView.textColor = .lightGray
            view.customView.numberOfLines = 0
            view.customView.font = .preferredFont(forTextStyle: .caption2)
            return view
        case UICollectionView.elementKindSectionFooter:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: TextTitleView.reuseIdentifier,
                                                                       for: indexPath) as! TextTitleView
            view.customView.text = " "
            return view
        default:
            fatalError()
        }
    }
}

extension DefaultChatCollectionDataSource: ChatLayoutDelegate {
    
    public func shouldPresentHeader(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        true
    }
    
    public func shouldPresentFooter(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        true
    }
    
    public func sizeForItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ItemSize {
        switch kind {
        case .cell:
            let item = sections[indexPath.section].cells[indexPath.item]
            switch item {
            case let .message(message, bubbleType: _):
                switch message.data {
                case .text, .attributeText, .custom(_), .audio(_):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: 50))
                case let .image(_, isLocallyStored: isDownloaded):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: isDownloaded ? 120 : 80))
                case let .url(_, isLocallyStored: isDownloaded):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: isDownloaded ? 60 : 36))
                case let .video(_, isLocallyStored: isDownloaded):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: isDownloaded ? 120 : 80))
                case .file(_, _):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: 60))
                case .card(_), .location(_), .notice(_), .face(_):
                    return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: 72))
                default:
                    fatalError()
                }
            case .date, .systemMessage:
                return .estimated(CGSize(width: chatLayout.layoutFrame.width, height: 18))
            case .typingIndicator:
                return .estimated(CGSize(width: 60, height: 36))
            case .messageGroup:
                return .estimated(CGSize(width: min(85, chatLayout.layoutFrame.width / 3), height: 18))
            }
        case .footer, .header:
            return .auto
        }
    }
    
    public func alignmentForItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ChatItemAlignment {
        switch kind {
        case .header:
            return .center
        case .cell:
            let item = sections[indexPath.section].cells[indexPath.item]
            switch item {
            case .date, .systemMessage:
                return .center
            case .message:
                return .fullWidth
            case .messageGroup(let msg):
                return msg.type == .incoming ? .leading : .trailing
            case .typingIndicator:
                return .leading
            }
        case .footer:
            return .trailing
        }
    }
    
    public func initialLayoutAttributesForInsertedItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath, modifying originalAttributes: ChatLayoutAttributes, on state: InitialAttributesRequestType) {
        originalAttributes.alpha = 0
        guard state == .invalidation,
              kind == .cell else {
            return
        }
        switch sections[indexPath.section].cells[indexPath.item] {
        case .typingIndicator:
            originalAttributes.transform = .init(scaleX: 0.1, y: 0.1)
            originalAttributes.center.x -= originalAttributes.bounds.width / 5
        default:
            break
        }
    }
    
    public func finalLayoutAttributesForDeletedItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath, modifying originalAttributes: ChatLayoutAttributes) {
        originalAttributes.alpha = 0
        guard kind == .cell else {
            return
        }
        switch oldSections[indexPath.section].cells[indexPath.item] {
        case .typingIndicator:
            originalAttributes.transform = .init(scaleX: 0.1, y: 0.1)
            originalAttributes.center.x -= originalAttributes.bounds.width / 5
        default:
            break
        }
    }
}
