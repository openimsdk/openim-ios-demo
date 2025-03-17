
import ChatLayout
import DifferenceKit
import Foundation
import InputBarAccessoryView
import UIKit
import OUICore
import OUICoreView
import ProgressHUD
import MJRefresh

#if ENABLE_CALL
import OUICalling
#endif


final class ChatViewController: UIViewController {
    
    private enum ReactionTypes {
        case delayedUpdate
    }
    
    private var ignoreInterfaceActions = true
    
    private enum InterfaceActions {
        case changingKeyboardFrame
        case changingContentInsets
        case changingFrameSize
        case sendingMessage
        case scrollingToTop
        case scrollingToBottom
        case showingPreview
        case showingAccessory
        case updatingCollectionInIsolation
    }
    
    private enum ControllerActions {
        case loadingInitialMessages
        case loadingPreviousMessages
        case loadingMoreMessages
        case updatingCollection
    }
    
    private var currentInterfaceActions: SetActor<Set<InterfaceActions>, ReactionTypes> = SetActor()
    private var currentControllerActions: SetActor<Set<ControllerActions>, ReactionTypes> = SetActor()
    private let editNotifier: EditNotifier
    private let swipeNotifier: SwipeNotifier
    private var collectionView: UICollectionView!
    private var chatLayout = CollectionViewChatLayout()
    private let inputBarView = CoustomInputBarAccessoryView()
    
    private var oldLeftBarButtonItem: UIBarButtonItem?
    
    private let chatController: ChatController
    private let dataSource: ChatCollectionDataSource
    private var animator: ManualAnimator?
    
    private var translationX: CGFloat = 0
    private var currentOffset: CGFloat = 0
    private var lastContentOffset: CGFloat = 0
    
    private var hiddenInputBar: Bool = false
    private var scrollToTop: Bool = false
    
    private var titleView = ChatTitleView()
    private var bottomTipsView: EditingBottomTipsView?
    private var inputBarViewBottomAnchor: NSLayoutConstraint!
    private var contentStackViewBottomAnchor: NSLayoutConstraint?
    private var contentStackView: UIStackView!
        
    private var otherIsInBlacklist = false
    
    private var keepContentOffsetAtBottom = true {
        didSet {
            chatLayout.keepContentOffsetAtBottomOnBatchUpdates = keepContentOffsetAtBottom
        }
    }
    
    private var popover: PopoverCollectionViewController?
    
    private var isDismissed: Bool = false
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleRevealPan(_:)))
        gesture.delegate = self
        
        return gesture
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        
        return gesture
    }()
    
    lazy var settingButton: UIBarButtonItem = {
        let v = UIBarButtonItem(image: UIImage(nameInBundle: "common_more_btn_icon"), style: .done, target: self, action: #selector(settingButtonAction))
        v.tintColor = .black
        v.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        v.isEnabled = false
        
        return v
    }()
    
    @objc
    private func settingButtonAction() {
        popover?.dismiss()

        let conversation = self.chatController.getConversation()
        let conversationType = conversation.conversationType
        switch conversationType {
        case .undefine, .notification:
            break
        case .c2c:
            chatController.getOtherInfo { [weak self] others in
                guard let self else { return }
                
                let viewModel = SingleChatSettingViewModel(conversation: conversation, userInfo: others.toUserInfo())
                let vc = SingleChatSettingTableViewController(viewModel: viewModel, style: .grouped)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case .superGroup:
            chatController.getGroupInfo(force: false) { [weak self] info in
                guard let self else { return }

                chatController.getGroupMembers(userIDs: nil, memory: true) { [self] ms in
                    
                    let vc = GroupChatSettingTableViewController(conversation: conversation, groupInfo: info, groupMembers: ms, style: .grouped)
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    lazy var mediaButton: UIBarButtonItem = {
        let v = UIBarButtonItem(image: UIImage(nameInBundle: "chat_call_btn_icon"), style: .done, target: self, action: #selector(mediaButtonAction))
        v.tintColor = .black
        v.imageInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)

        return v
    }()
    
    @objc
    private func mediaButtonAction() {
        popover?.dismiss()
        
        showMediaLinkSheet()
    }
    
    private let loadMoreView = UIActivityIndicatorView()
    
    private let watermarkView: WatermarkBackgroundView = {
        let v = WatermarkBackgroundView()
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private var typingDebounceTimer: Timer?
    
    init(chatController: ChatController,
         dataSource: ChatCollectionDataSource,
         editNotifier: EditNotifier,
         swipeNotifier: SwipeNotifier,
         hiddenInputBar: Bool = false,
         scrollToTop: Bool = false) {
        self.chatController = chatController
        self.dataSource = dataSource
        self.editNotifier = editNotifier
        self.swipeNotifier = swipeNotifier
        self.hiddenInputBar = hiddenInputBar
        self.scrollToTop = scrollToTop
        super.init(nibName: nil, bundle: nil)
        
        loadInitialMessages()
    }
    
    @available(*, unavailable, message: "Use init(messageController:) instead")
    override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }
    
    @available(*, unavailable, message: "Use init(messageController:) instead")
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        iLogger.print("\(type(of: self)) - \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupNavigationBar()
        setupWatermarkView()
        setupInputBar()
        updateUnreadCount(count: 0)
        
        chatLayout.settings.interItemSpacing = 10
        chatLayout.settings.interSectionSpacing = 4
        chatLayout.settings.additionalInsets = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
        
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: chatLayout)
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = dataSource
        chatLayout.delegate = dataSource
        collectionView.delegate = self
        collectionView.keyboardDismissMode = .interactive


        collectionView.isPrefetchingEnabled = false
        
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.automaticallyAdjustsScrollIndicatorInsets = true
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        dataSource.prepare(with: collectionView)
        
        setupRefreshControl()
        
        inputBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBarView)
        
        contentStackView = UIStackView(arrangedSubviews: [collectionView])
        contentStackView.axis = .vertical
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            
            inputBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        configInputView(hidden: hiddenInputBar)
        
        inputBarViewBottomAnchor = inputBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        inputBarViewBottomAnchor.isActive = true
        
        KeyboardListener.shared.add(delegate: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isDismissed = false

        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isDismissed = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard isViewLoaded else {
            return
        }
        currentInterfaceActions.options.insert(.changingFrameSize)
        let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setNeedsLayout()
        coordinator.animate(alongsideTransition: { _ in


            self.collectionView.performBatchUpdates(nil)
        }, completion: { _ in
            if let positionSnapshot,
               !self.isUserInitiatedScrolling {



                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.currentInterfaceActions.options.remove(.changingFrameSize)
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        swipeNotifier.setAccessoryOffset(UIEdgeInsets(top: view.safeAreaInsets.top,
                                                      left: view.safeAreaInsets.left + chatLayout.settings.additionalInsets.left,
                                                      bottom: view.safeAreaInsets.bottom,
                                                      right: view.safeAreaInsets.right + chatLayout.settings.additionalInsets.right))
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if inputBarView.superview == nil,
           topMostViewController() is ChatViewController {
            DispatchQueue.main.async { [weak self] in
                self?.reloadInputViews()
            }
        }
    }
    
    private func configInputView(hidden: Bool) {
        contentStackViewBottomAnchor?.isActive = false
        contentStackViewBottomAnchor = contentStackView.bottomAnchor.constraint(equalTo: hidden ? view.bottomAnchor : inputBarView.topAnchor, constant: 0)
        contentStackViewBottomAnchor!.isActive = true
    }
    
    @objc
    private func loadInitialMessages() {
        guard !currentControllerActions.options.contains(.loadingInitialMessages) else { return }
        
        currentControllerActions.options.insert(.loadingInitialMessages)
        chatController.loadInitialMessages { [weak self] sections in
            self?.processUpdates(with: sections, animated: false, requiresIsolatedProcess: true) {
                self?.currentControllerActions.options.remove(.loadingInitialMessages)
                self?.ignoreInterfaceActions = false
            }
        }
    }
    
    private func setRightButtons(show: Bool) {
        if show {
#if ENABLE_CALL
            navigationItem.rightBarButtonItems = chatController.getConversation().conversationType == .superGroup ? [settingButton] : [settingButton, mediaButton]
#else
            navigationItem.rightBarButtonItems = [settingButton]
#endif
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }
    
    private func setupNavigationBar() {
        chatController.getTitle()
        navigationItem.titleView = titleView
        
        if let navigationBar = navigationController?.navigationBar {
            let underline = UIView()
            underline.backgroundColor = .cE8EAEF
            underline.translatesAutoresizingMaskIntoConstraints = false
            
            navigationBar.addSubview(underline)
            NSLayoutConstraint.activate([
                underline.heightAnchor.constraint(equalToConstant: 1),
                underline.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
                underline.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
                underline.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor)
            ])
        }
    }
    
    private func setupWatermarkView() {
        view.insertSubview(watermarkView, at: 0)
        
        NSLayoutConstraint.activate([
            watermarkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            watermarkView.topAnchor.constraint(equalTo: view.topAnchor),
            watermarkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            watermarkView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupInputBar() {
        inputBarView.delegate = self
        inputBarView.shouldAnimateTextDidChangeLayout = true
        inputBarView.maxTextViewHeight = 120.h
        
        if let userID = chatController.getSelfInfo()?.userID {
            inputBarView.identity = userID
        }
        inputBarView.isHidden = hiddenInputBar
    }
    
    private func setupRefreshControl() {
        let header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(handleRefresh))
        header.stateLabel?.isHidden = true
        header.lastUpdatedTimeLabel?.isHidden = true
        header.isCollectionViewAnimationBug = true

    }
    
    @objc private func handleRefresh() {
        if !currentControllerActions.options.contains(.loadingPreviousMessages) {
            currentControllerActions.options.insert(.loadingPreviousMessages)
        }

        chatController.loadPreviousMessages { [weak self] sections in
            guard let self else {
                return
            }

            let animated = !self.isUserInitiatedScrolling
            self.processUpdates(with: sections, animated: false, requiresIsolatedProcess: true) {
                self.collectionView.mj_header?.endRefreshing()

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                    self.currentControllerActions.options.remove(.loadingPreviousMessages)
                }
            }
        }
    }

    private func showMediaLinkSheet() {

        resetOffset(newBottomInset: 0)
        inputBarView.inputResignFirstResponder()
        
        let conversation = chatController.getConversation()
        
        if conversation.conversationType == .superGroup {
            presentAlert(title: "Not Support Group Chat".innerLocalized())
            
            return
        }

    #if ENABLE_CALL
        if CallingManager.isBusy {
            presentAlert(title: "callingBusy".innerLocalized())
            
            return
        }
    #endif
        presentMediaActionSheet { [weak self] in
            guard let self else { return }
            
            if otherIsInBlacklist {
                presentAlert(title: "otherIsInblacklistHit".innerLocalizedFormat(arguments: "voice".innerLocalized()), cancelTitle: "iSee".innerLocalized())
            } else {
                startMedia(isVideo: false)
            }
        } videoHandler: { [weak self] in
            guard let self else { return }
            
            if otherIsInBlacklist {
                presentAlert(title: "otherIsInblacklistHit".innerLocalizedFormat(arguments: "video".innerLocalized()), cancelTitle: "iSee".innerLocalized())
            } else {
                startMedia(isVideo: true)
            }
        }
    }

    private func startMedia(isVideo: Bool) {
        guard mediaButton.isEnabled else { return }

        resetOffset(newBottomInset: 0)
#if ENABLE_CALL
        let conversation = chatController.getConversation()

            let user = CallingUserInfo(userID: conversation.userID!, nickname: conversation.showName, faceURL: conversation.faceURL)
            let me = chatController.getSelfInfo()
            let inviter = CallingUserInfo(userID: me?.userID, nickname: me?.nickname, faceURL: me?.faceURL)
            
            CallingManager.manager.startLiveChat(inviter: inviter,
                                                 others: [user],
                                                 isVideo: isVideo)
#endif
    }

    func inputTextViewResignFirstResponder() {
        inputBarView.inputTextView.resignFirstResponder()
        resetOffset(newBottomInset: 0)
    }
}

extension ChatViewController: UIScrollViewDelegate {
    
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard scrollView.contentSize.height > 0,
              !currentInterfaceActions.options.contains(.showingAccessory),
              !currentInterfaceActions.options.contains(.showingPreview),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return false
        }



        currentInterfaceActions.options.insert(.scrollingToTop)
        return true
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard !currentControllerActions.options.contains(.loadingInitialMessages),
              !currentControllerActions.options.contains(.loadingPreviousMessages) else {
            return
        }
        currentInterfaceActions.options.remove(.scrollingToTop)
        loadPreviousMessages()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        popover?.dismiss()
        
        if collectionView.isTracking {
            let bottomInset = scrollView.contentInset.bottom
            
            if scrollView.contentOffset.y < lastContentOffset && scrollView.contentOffset.y > -bottomInset {

                let scrollViewHeight = scrollView.frame.height
                let contentHeight = scrollView.contentSize.height
                
                if scrollView.contentOffset.y + scrollViewHeight < contentHeight {


                    if inputBarView.inputTextView.isFirstResponder {
                        inputBarView.inputTextView.resignFirstResponder()
                        resetOffset(newBottomInset: 0)
                    }
                }
            }
        }
        
        lastContentOffset = scrollView.contentOffset.y

        if currentControllerActions.options.contains(.updatingCollection), collectionView.isDragging {


            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates({}, completion: { _ in
                    let context = ChatLayoutInvalidationContext()
                    context.invalidateLayoutMetrics = false
                    self.collectionView.collectionViewLayout.invalidateLayout(with: context)
                })
            }
        }
        guard !currentControllerActions.options.contains(.loadingInitialMessages),
              !currentControllerActions.options.contains(.loadingPreviousMessages),
              !currentControllerActions.options.contains(.loadingMoreMessages),
              !currentInterfaceActions.options.contains(.scrollingToTop),
              !currentInterfaceActions.options.contains(.scrollingToBottom) else {
            return
        }
        
        if scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + scrollView.bounds.height {
            loadPreviousMessages()
        } else {
            if !currentControllerActions.options.contains(.loadingPreviousMessages), !keepContentOffsetAtBottom {
                chatLayout.keepContentOffsetAtBottomOnBatchUpdates = collctionViewIsAtBottom
            }
            
            let contentOffsetY = scrollView.contentOffset.y

            let contentSizeH = scrollView.contentSize.height
            let scrollViewBoundsH = scrollView.bounds.size.height
            let footerViewY = max(contentSizeH, scrollViewBoundsH) + scrollView.contentInset.bottom
            
            let footerViewFullApperance = contentOffsetY + scrollViewBoundsH
            let isCanRefreshing = footerViewFullApperance - footerViewY - 50 > 0
            
            if scrollView.isDragging, isCanRefreshing {
                loadMoreMessages()
            }
        }
    }
    
    private func loadPreviousMessages() {


        if !currentControllerActions.options.contains(.loadingPreviousMessages) {
            currentControllerActions.options.insert(.loadingPreviousMessages)
        }
        
        chatController.loadPreviousMessages { [weak self] sections in
            guard let self else {
                return
            }

            let animated = !self.isUserInitiatedScrolling
            self.processUpdates(with: sections, animated: animated, requiresIsolatedProcess: false) {
                self.currentControllerActions.options.remove(.loadingPreviousMessages)
            }
        }
    }
    
    private func loadMoreMessages() {


        currentControllerActions.options.insert(.loadingMoreMessages)
        chatLayout.keepContentOffsetAtBottomOnBatchUpdates = false
        chatController.loadMoreMessages { [weak self] sections in
            guard let self else {
                return
            }

            let animated = !self.isUserInitiatedScrolling
            self.processUpdates(with: sections, animated: false, requiresIsolatedProcess: true) {
                self.chatLayout.keepContentOffsetAtBottomOnBatchUpdates = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                    self.currentControllerActions.options.remove(.loadingMoreMessages)
                }
            }
        }
    }
    
    fileprivate var isUserInitiatedScrolling: Bool {
        collectionView.isDragging || collectionView.isDecelerating
    }
    
    private var collctionViewIsAtBottom: Bool {
        let contentOffsetAtBottom = CGPoint(x: collectionView.contentOffset.x,
                                            y: chatLayout.collectionViewContentSize.height - collectionView.frame.height + collectionView.adjustedContentInset.bottom)
        
        return contentOffsetAtBottom.y <= collectionView.contentOffset.y
    }
    
    func scrollToBottom(animated: Bool = true, completion: (() -> Void)? = nil) {

        let contentOffsetAtBottom = CGPoint(x: collectionView.contentOffset.x,
                                            y: chatLayout.collectionViewContentSize.height - collectionView.frame.height + collectionView.adjustedContentInset.bottom)
        
        guard contentOffsetAtBottom.y > collectionView.contentOffset.y else {
            completion?()
            return
        }
        
        let initialOffset = collectionView.contentOffset.y
        let delta = contentOffsetAtBottom.y - initialOffset
        if abs(delta) > chatLayout.visibleBounds.height {

            animator = ManualAnimator()
            animator?.animate(duration: TimeInterval(animated ? 0.25 : 0.1), curve: .easeInOut) { [weak self] percentage in
                guard let self else {
                    return
                }
                self.collectionView.contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y: initialOffset + (delta * percentage))
                if percentage == 1.0 {
                    self.animator = nil
                    let positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .footer, edge: .bottom)
                    self.chatLayout.restoreContentOffset(with: positionSnapshot)
                    self.currentInterfaceActions.options.remove(.scrollingToBottom)
                    completion?()
                }
            }
        } else {
            currentInterfaceActions.options.insert(.scrollingToBottom)
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.collectionView.setContentOffset(contentOffsetAtBottom, animated: true)
            }, completion: { [weak self] _ in
                self?.currentInterfaceActions.options.remove(.scrollingToBottom)
                completion?()
            })
        }
    }
}

extension ChatViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("=====\(#function)")
        popover?.dismiss()
        dataSource.didSelectItemAt(collectionView, indexPath: indexPath)
    }
}


extension ChatViewController: ChatControllerDelegate {
    
    func configMeiaResource(msg: Message.Data) -> MediaResource? {
                
        if case .image(let source, _) = msg {
            return MediaResource(thumbUrl: source.thumb?.url,
                                 url: source.source.url,
                                 type: .image)
        }
        
        return nil
    }
    
    func previewMedias(id: String, data: Message.Data) {
        guard let item = configMeiaResource(msg: data) else { return }
        
        var vc = MediaPreviewViewController(resources: [item])
                        
        vc.showIn(controller: self) { [self] idx in

            if let ID = item.ID, let tag = self.dataSource.mediaImageViews[ID] {
                return self.collectionView.viewWithTag(tag)
            }
            
            return nil
        }
    }
    
    func didTapContent(with id: String, data: Message.Data) {
        popover?.dismiss()
        
        switch data {
        case .url(let uRL, let isLocallyStored):
            if uRL.absoluteString.hasPrefix(linkSchme) {
                let userID = uRL.absoluteString.replacingOccurrences(of: linkSchme, with: "")
                
                if !userID.isEmpty {
                    viewUserDetail(user: User(id: userID, name: ""))
                }
            } else if uRL.absoluteString.hasPrefix(sendFriendReqSchme) {
                ProgressHUD.animate()
                chatController.addFriend { r in
                    ProgressHUD.success("sendSuccessfully".innerLocalized())
                } onFailure: { errCode, errMsg in
                    ProgressHUD.error("canNotAddFriends".innerLocalized())
                }
            } else {
                UIApplication.shared.open(uRL)
            }
        case .image(let source, let isLocallyStored):
            if source.ex?.isFace == true {
                var media = MediaResource(thumbUrl: source.thumb?.url,
                                          url: source.source.url,
                                          ID: id)
     
                let vc = MediaPreviewViewController(resources: [media])
                
                vc.showIn(controller: self) { [weak self] _ in
                    if let tag = self?.dataSource.mediaImageViews[id] {
                        return self?.collectionView.viewWithTag(tag)
                    }
                    
                    return nil
                }
            } else {
                previewMedias(id: id, data: data)
            }
        default:
            break
        }
        print("\(#function)")
    }
    
    func friendInfoChanged(info: FriendInfo) {
        titleView.mainLabel.text = info.showName
        titleView.mainTailLabel.isHidden = true
        
        guard !hiddenInputBar else { return }
        
        let type = chatController.getConversation().conversationType
        
        setRightButtons(show: type == .c2c)
        settingButton.isEnabled = true
    }
    
    func groupInfoChanged(info: GroupInfo) {
        titleView.mainLabel.text = "\(info.groupName!)"
        titleView.mainTailLabel.text = "(\(info.memberCount))"
        
        guard !hiddenInputBar else { return }
        
        setRightButtons(show: info.status == .ok || info.status == .muted)
        settingButton.isEnabled = info.memberCount > 0
    }
    
    func updateUnreadCount(count: Int) {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: count > 0 ? (count > 99 ? "99+" : "\(count)") : nil, image: UIImage(nameInBundle: "common_back_icon")) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    func isInGroup(with isIn: Bool) {
        guard !hiddenInputBar else { return }
        
        inputBarView.isHidden = !isIn
        
        if isIn {
            bottomTipsView?.removeFromSuperview()
            bottomTipsView = nil
            setRightButtons(show: true)
        } else {
            if bottomTipsView == nil {
                bottomTipsView = EditingBottomTipsView()
                view.addSubview(bottomTipsView!)

                NSLayoutConstraint.activate([
                    bottomTipsView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    bottomTipsView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    bottomTipsView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
            setRightButtons(show: false)
        }
    }
    
    func update(with sections: [Section], requiresIsolatedProcess: Bool) {
        processUpdates(with: sections, animated: true, requiresIsolatedProcess: requiresIsolatedProcess)
    }
    
    private func processUpdates(with sections: [Section], animated: Bool = true, requiresIsolatedProcess: Bool, completion: (() -> Void)? = nil) {
        guard isViewLoaded else {
            dataSource.sections = sections
            return
        }
        
        guard currentInterfaceActions.options.isEmpty ||
                ignoreInterfaceActions else {
            let reaction = SetActor<Set<InterfaceActions>, ReactionTypes>.Reaction(type: .delayedUpdate,
                                                                                   action: .onEmpty,
                                                                                   executionType: .once,
                                                                                   actionBlock: { [weak self] in
                guard let self else {
                    return
                }
                self.processUpdates(with: sections, animated: animated, requiresIsolatedProcess: requiresIsolatedProcess, completion: completion)
            })
            currentInterfaceActions.add(reaction: reaction)
            return
        }
        
        func process() {
            
            if ignoreInterfaceActions { // only first load
                var changeSet = StagedChangeset(source: dataSource.sections, target: sections).flattenIfPossible()
                guard !changeSet.isEmpty else {
                    completion?()
                    return
                }
                guard let data = changeSet.last?.data else { 
                    completion?()
                    return
                }
                
                dataSource.sections = data
                
                if requiresIsolatedProcess {
                    chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = true
                    currentInterfaceActions.options.insert(.updatingCollectionInIsolation)
                }
                
                let positionSnapshot: ChatLayoutPositionSnapshot!
                if self.scrollToTop {
                    positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .header, edge: .top)
                } else {
                    positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: sections.count - 1), kind: .footer, edge: .bottom)
                }
                
                self.collectionView.reloadData()

                self.chatLayout.restoreContentOffset(with: positionSnapshot)
                
                self.chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
                if requiresIsolatedProcess {
                    self.currentInterfaceActions.options.remove(.updatingCollectionInIsolation)
                }
                completion?()
                self.currentControllerActions.options.remove(.updatingCollection)
                
                return
            }


            var changeSet = StagedChangeset(source: dataSource.sections, target: sections).flattenIfPossible()
            guard !changeSet.isEmpty else {
                completion?()
                return
            }

            if requiresIsolatedProcess {
                chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = true
                currentInterfaceActions.options.insert(.updatingCollectionInIsolation)
            }
            currentControllerActions.options.insert(.updatingCollection)
            collectionView.reload(using: changeSet,
                                  interrupt: { changeSet in
                guard changeSet.sectionInserted.isEmpty else {
                    return true
                }
                return false
            },
                                  onInterruptedReload: {
                let positionSnapshot: ChatLayoutPositionSnapshot!
                if self.scrollToTop {
                    positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: 0), kind: .header, edge: .top)
                } else {
                    positionSnapshot = ChatLayoutPositionSnapshot(indexPath: IndexPath(item: 0, section: sections.count - 1), kind: .footer, edge: .bottom)
                }
                self.collectionView.reloadData()

                self.chatLayout.restoreContentOffset(with: positionSnapshot)
            },
                                  completion: { _ in
                DispatchQueue.main.async { [self] in
                 
                    self.chatLayout.processOnlyVisibleItemsOnAnimatedBatchUpdates = false
                    if requiresIsolatedProcess {
                        self.currentInterfaceActions.options.remove(.updatingCollectionInIsolation)
                    }
                    completion?()
                    self.currentControllerActions.options.remove(.updatingCollection)
                }
            },
                                  setData: { data in
                self.dataSource.sections = data
            })
        }
        
        if animated {
            process()
        } else {
            UIView.performWithoutAnimation {
                process()
            }
        }
    }
    
}


extension ChatViewController: UIGestureRecognizerDelegate {
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        inputBarView.inputResignFirstResponder()
        resetOffset(newBottomInset: 0)
        popover?.dismiss()
    }
    
    @objc private func handleRevealPan(_ gesture: UIPanGestureRecognizer) {
        guard let collectionView = gesture.view as? UICollectionView else {
            currentInterfaceActions.options.remove(.showingAccessory)
            return
        }
        
        switch gesture.state {
        case .began:
            currentInterfaceActions.options.insert(.showingAccessory)
        case .changed:
            translationX = gesture.translation(in: gesture.view).x
            currentOffset += translationX
            
            gesture.setTranslation(.zero, in: gesture.view)
            updateTransforms(in: collectionView)
        default:
            UIView.animate(withDuration: 0.25, animations: { () in
                self.translationX = 0
                self.currentOffset = 0
                self.updateTransforms(in: collectionView, transform: .identity)
            }, completion: { _ in
                self.currentInterfaceActions.options.remove(.showingAccessory)
            })
        }
    }
    
    private func updateTransforms(in collectionView: UICollectionView, transform: CGAffineTransform? = nil) {
        collectionView.indexPathsForVisibleItems.forEach {
            guard let cell = collectionView.cellForItem(at: $0) else { return }
            updateTransform(transform: transform, cell: cell, indexPath: $0)
        }
    }
    
    private func updateTransform(transform: CGAffineTransform?, cell: UICollectionViewCell, indexPath: IndexPath) {
        var x = currentOffset
        
        let maxOffset: CGFloat = -100
        x = max(x, maxOffset)
        x = min(x, 0)
        
        swipeNotifier.setSwipeCompletionRate(x / maxOffset)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        [gestureRecognizer, otherGestureRecognizer].contains(panGesture)
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gesture = gestureRecognizer as? UIPanGestureRecognizer, gesture == panGesture {
            let translation = gesture.translation(in: gesture.view)
            return (abs(translation.x) > abs(translation.y)) && (gesture == panGesture)
        }
        
        return true
    }
    
}


extension ChatViewController: CoustomInputBarAccessoryViewDelegate {
    
    private func completionHandler() -> ([Section]) -> Void {
        let completion: ([Section]) -> Void = { [weak self] sections in
            self?.inputBarView.sendButton.stopAnimating()
            self?.currentInterfaceActions.options.remove(.sendingMessage)
            self?.processUpdates(with: sections, animated: true, requiresIsolatedProcess: false)
        }
        
        return completion
    }
    
    func uploadFile(image: UIImage,  completion: @escaping (URL) -> Void) {
        ProgressHUD.animate()
        chatController.uploadFile(image: image) { p in
            ProgressHUD.progress(p)
        } completion: { u in
            guard let u, let url = URL(string: u) else { return }
            completion(url)
            ProgressHUD.dismiss()
        }
    }
    
    public func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        guard !currentInterfaceActions.options.contains(.sendingMessage) else {
            return
        }
        scrollToBottom()
    }
    
    public func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let messageText = inputBar.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        let completion = completionHandler()
        
        currentInterfaceActions.options.insert(.sendingMessage)
        
        guard !messageText.isEmpty else {
            self.currentInterfaceActions.options.remove(.sendingMessage)
            return
        }
        
        keepContentOffsetAtBottom = true
        
        self.scrollToBottom(completion: {
            inputBar.sendButton.startAnimating()
            self.chatController.sendMessage(.text(TextMessageSource(text: messageText)), completion: completion)
        })
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [CustomAttachment]) {

        let completion = completionHandler()
        
        currentInterfaceActions.options.insert(.sendingMessage)
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        
        guard !attachments.isEmpty else {
            currentInterfaceActions.options.remove(.sendingMessage)
            return
        }
        keepContentOffsetAtBottom = true

        scrollToBottom(completion: {

            inputBar.sendButton.startAnimating()
            attachments.forEach { attachment in

                switch attachment {
                    
                case .image(let relativePath, let path):
                    let source = MediaMessageSource(source: MediaMessageSource.Info(url: URL(string: path)!, relativePath: relativePath))
                    
                    self.chatController.sendMessage(.image(source, isLocallyStored: true),
                                                    completion: completion)
                    
                    default:
                    break
                }
            }
        })
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressPadItemWith type: PadItemType) {
        switch type {
        case .media:
            showMediaLinkSheet()
        default:
            break
        }
    }
}


extension ChatViewController: KeyboardListenerDelegate {
    
    func keyboardWillChangeFrame(info: KeyboardInfo) {
        guard !currentInterfaceActions.options.contains(.changingFrameSize),
              !currentInterfaceActions.options.contains(.showingPreview),
              collectionView.contentInsetAdjustmentBehavior != .never,
              let keyboardFrame = collectionView.window?.convert(info.frameEnd, to: view),
              keyboardFrame.minY > 0,
              inputBarView.inputTextView.isFirstResponder else { // The keyboard on the presented view will affect this.
            return
        }
                
        currentInterfaceActions.options.insert(.changingKeyboardFrame)
        let newBottomInset = UIScreen.main.bounds.height - keyboardFrame.minY
                
        if collectionView.contentInset.bottom != newBottomInset {
            let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)

            if currentControllerActions.options.contains(.updatingCollection) {
                UIView.performWithoutAnimation {
                    self.collectionView.performBatchUpdates({})
                }
            }

            currentInterfaceActions.options.insert(.changingContentInsets)
            inputBarViewBottomAnchor.constant = -newBottomInset
            
            UIView.animate(withDuration: info.animationDuration, animations: {
                
                self.view.layoutIfNeeded()
                
                if let positionSnapshot, !self.isUserInitiatedScrolling {
                    self.chatLayout.restoreContentOffset(with: positionSnapshot)
                }
                if #available(iOS 13.0, *) {
                } else {


                    self.collectionView.collectionViewLayout.invalidateLayout()
                }
            }, completion: { _ in
                self.currentInterfaceActions.options.remove(.changingContentInsets)
            })
        }
        
        if newBottomInset == 0,
            info.frameEnd.minY == UIScreen.main.bounds.height,
            info.frameEnd.minY > info.frameBegin.minY,
           inputBarView.inputTextView.inputView == nil { // If there is emoji/pad input, it will not be hidden.
            resetOffset(newBottomInset: newBottomInset, duration: info.animationDuration)
        }
    }
    
    func resetOffset(newBottomInset: CGFloat, duration: CGFloat = 0.25) {
        let positionSnapshot = chatLayout.getContentOffsetSnapshot(from: .bottom)
        inputBarViewBottomAnchor.constant = -newBottomInset
        
        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
        })

        if let positionSnapshot, !self.isUserInitiatedScrolling {
            self.chatLayout.restoreContentOffset(with: positionSnapshot)
        }
        self.currentInterfaceActions.options.remove(.changingContentInsets)
    }
    
    func keyboardDidChangeFrame(info: KeyboardInfo) {
        guard currentInterfaceActions.options.contains(.changingKeyboardFrame) else {
            return
        }
        currentInterfaceActions.options.remove(.changingKeyboardFrame)
    }
    
    func keyboardWillShow(info: KeyboardInfo) {
        scrollToBottom(animated: false)
    }
}

extension ChatViewController {
    private func createContactsViewController() -> MyContactsViewController {
    #if ENABLE_ORGANIZATION
        return MyContactsViewController(types: [.friends, .groups, .staff, .recent], multipleSelected: true)
    #else
        return MyContactsViewController(types: [.friends, .groups, .recent], multipleSelected: true)
    #endif
    }

    private func extractUserAndGroupIDs(from infos: [ContactInfo]) -> (usersID: [String], groupsID: [String]) {
        var usersID: [String] = []
        var groupsID: [String] = []
        
        infos.forEach { info in
            if info.type == .group {
                groupsID.append(info.ID!)
            } else {
                usersID.append(info.ID!)
            }
        }
        
        return (usersID, groupsID)
    }

    private func dismissViewControllerStack(vc: MyContactsViewController) {
        if let presentedVC = self.presentedViewController {
            if let presented2 = presentedVC.presentedViewController {
                presented2.dismiss(animated: true)
            } else {
                dismiss(animated: true)
            }
        } else {
            vc.navigationController?.popToViewController(self, animated: true)
        }
    }

    private func presentOrPushViewController(_ vc: UIViewController) {
        if let presented = presentedViewController {
            let nav = UINavigationController(rootViewController: vc)
            
            let closeButtonItem = UIBarButtonItem(title: "关闭") {
                presented.dismiss(animated: true)
            }
            vc.navigationItem.leftBarButtonItem = closeButtonItem
            
            presented.present(nav, animated: true)
        } else {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

}

extension ChatViewController: GestureDelegate {
    
    func didTapAvatar(with user: User) {
        popover?.dismiss()
        
        viewUserDetail(user: user)
    }
    
    func viewUserDetail(user: User) {
        if chatController.getConversation().conversationType == .superGroup {
            chatController.getGroupInfo(force: false, completion: { [weak self] info in
                guard let self else { return }
                
                if info.lookMemberInfo != 1 || chatController.getIsAdminOrOwner() {
                    chatController.getGroupMembers(userIDs: [user.id], memory: false) { [weak self] mi in
                        guard !mi.isEmpty else { return }

                        let vc = UserDetailTableViewController(userId: user.id, groupInfo: info, groupMemberInfo: mi[0], userInfo: user.toSimplePublicUserInfo())
                        self?.navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            })
        } else {
            let vc = UserDetailTableViewController(userId: user.id, groupId: chatController.getConversation().groupID, userInfo: user.toSimplePublicUserInfo())
            navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func onTapEdgeAligningView() {
        popover?.dismiss()
    }
}
