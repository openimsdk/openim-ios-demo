
import OUICore
import OUICoreView
import ProgressHUD
import RxSwift
import Localize_Swift
import YYText

#if ENABLE_CALL
import OUICalling
#endif

#if ENABLE_LIVE_ROOM
import OUILive
#endif

open class ChatListViewController: UIViewController, UITableViewDelegate {
    
    public var tapTab = false
        
    private var reInstall = false
    
    public func refreshConversations() {
        _viewModel.getAllConversations()
    }
    
    public func refreshUserInfo(userInfo: UserInfo? = nil) {
        _headerView.avatarImageView.setAvatar(url: userInfo?.faceURL?.defaultThumbnailURLString, text: userInfo?.nickname)
        _headerView.nameLabel.text = userInfo?.nickname
    }
    
    public func clearRecord() {
        _viewModel.conversationsRelay.accept([])
    }
    
    private lazy var _headerView: ChatListHeaderView = {
        let v = ChatListHeaderView()
        return v
    }()

    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.className)
        v.delegate = self
        v.separatorStyle = .none
        v.rowHeight = 68.h
        
        let refresh: UIRefreshControl = {
            let v = UIRefreshControl(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
            v.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self, weak v] in
                self?._viewModel.getSelfInfo()
                v?.endRefreshing()
            }).disposed(by: _disposeBag)
            return v
        }()
        v.refreshControl = refresh
        v.backgroundColor = .clear
        
        return v
    }()
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if tapTab {
            navigationController?.setNavigationBarHidden(true, animated: false)
            tapTab = false
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !tapTab {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    private func createMenuItems() -> [PopoverTableViewController.MenuItem] {
        let addFriendItem = PopoverTableViewController.MenuItem(title: "addFriend".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_add_friend_icon")) { [weak self] in
            let vc = SearchFriendIndexViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
            vc.didSelectedItem = { [weak self] id in
                let vc = UserDetailTableViewController(userId: id, groupId: nil)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }

        let addGroupItem = PopoverTableViewController.MenuItem(title: "addGroup".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_add_group_icon")) { [weak self] in
            let vc = SearchGroupIndexViewController()
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
            
            vc.didSelectedItem = { [weak self] id in
                let vc = GroupDetailViewController(groupId: id)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        let createWorkGroupItem = PopoverTableViewController.MenuItem(title: "createGroup".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_create_work_group_icon")) { [weak self] in
            #if ENABLE_ORGANIZATION
            let vc = MyContactsViewController(types: [.friends, .staff], multipleSelected: true)
            #else
            let vc = MyContactsViewController(types: [.friends], multipleSelected: true, selectMaxCount: 50, enableChangeSelectedModel: true)
            #endif
            vc.selectedContact(blocked: [IMController.shared.uid]) { [weak self] (r: [ContactInfo]) in
                guard let sself = self else { return }
                
                let users = r.map {UserInfo(userID: $0.ID!, nickname: $0.name, faceURL: $0.faceURL)}
                
                if users.count > 0 {
                    let vc = NewGroupViewController(users: users, groupType: .working)
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    guard let userID = users.first?.userID else { return }
                    ProgressHUD.animate()
                    sself._viewModel.createSingleChat(userID: userID) { [sself] conversation in
                        ProgressHUD.dismiss()
                        sself.toChat(conversation: conversation)
                    }
                }
            }
            vc.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        var items = [addFriendItem, addGroupItem, createWorkGroupItem]
        
        return items
    }
    
    private let _disposeBag = DisposeBag()
    private let _viewModel = ChatListViewModel()
    private let _contactViewModel = ContactsViewModel()

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        NotificationCenter.default.addObserver(self, selector: #selector(setText), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
        YYTextAsyncLayer.swizzleDisplay
        
        initView()
        bindData()
    }
    
    @objc private func setText() {
        _tableView.reloadData()
    }

    private func initView() {
        view.addSubview(_headerView)
        _headerView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.top.equalTo(_headerView.snp.bottom)
            make.leading.bottom.trailing.equalToSuperview()
        }
    }
    
    private func toChat(conversation: ConversationInfo) {
        do {
            let toMap = JsonTool.toJson(fromObject: conversation)
            iLogger.print("\(type(of: self)) \(#function) conversation is: \(toMap)")
        } catch (let e) {
            iLogger.print("\(type(of: self)) \(#function) throw error: \(e.localizedDescription)")
        }
        let vc = ChatViewControllerBuilder().build(conversation, hiddenInputBar: conversation.conversationType == .notification)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func bindData() {
        
        IMController.shared.connectionRelay.subscribe(onNext: { [weak self] result in
            print("=====Connection status: \(result)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
                
                let status = result.status
                let install = result.reInstall
                
                if status == .syncStart {
                    self?.reInstall = install ?? false
                    
                    if self?.reInstall == true {
                        ProgressHUD.animate(ConnectionStatus.syncStart.title, interaction: false)
                    }
                } else if status == .syncProgress {
                    
                    if self?.reInstall == true {
                        let p = CGFloat(result.progress!) / 100.0

                        ProgressHUD.progress(ConnectionStatus.syncStart.title, p, interaction: false)
                    }
                } else if status == .syncComplete {
                    ProgressHUD.dismiss()
                    self?._viewModel.getAllConversations()
                }
                
                if self?.reInstall == false || (self?.reInstall == true && (status == .connectFailure || status == .syncFailure)) {
                    self?._headerView.updateConnectionStatus(status: status)
                }
            }
        })
        
        _headerView.addBtn.rx.tap.subscribe(onNext: { [weak self] in
            guard let self else { return }
            let popover = PopoverTableViewController(items: createMenuItems())
            popover.topInset = 0
            popover.show(in: self, sender: _headerView.addBtn, permittedArrowDirections: [], sourceViewReviseOffset: 60.h)
        }).disposed(by: _disposeBag)

        _viewModel.conversationsRelay.bind(to: _tableView.rx.items(cellIdentifier: ChatTableViewCell.className, cellType: ChatTableViewCell.self)) { (row, item, cell) in
     
            let placeholderName: String = item.conversationType == .c2c ? "contact_my_friend_icon" : "contact_my_group_icon"
            cell.avatarImageView.setAvatar(url: item.faceURL, text: item.conversationType == .c2c ? item.showName : nil, placeHolder: placeholderName)
            cell.muteImageView.isHidden = item.recvMsgOpt == .receive
            
            cell.titleLabel.text = item.showName
            cell.subtitleLabel.attributedText = MessageHelper.getAbstructOf(conversation: item, highlight: false)
            var unreadShouldHide: Bool = false
            if item.recvMsgOpt != .receive {
                unreadShouldHide = true
            }
            if item.unreadCount <= 0 {
                unreadShouldHide = true
            }
            cell.unreadLabel.isHidden = unreadShouldHide
            cell.unreadLabel.text =  item.unreadCount > 99 ? "99+" : "\(item.unreadCount)"
            cell.muteImageView.isHidden = item.recvMsgOpt == .receive
            cell.timeLabel.text = Date.timeString(timeInterval: TimeInterval(item.latestMsgSendTime))
            
        }.disposed(by: _disposeBag)

        _tableView.rx.modelSelected(ConversationInfo.self).subscribe(onNext: { [weak self] (conversation: ConversationInfo) in
            
            self?.toChat(conversation: conversation)
        }).disposed(by: _disposeBag)

        _viewModel.loginUserPublish.subscribe(onNext: { [weak self] (userInfo: UserInfo?) in
            self?._headerView.avatarImageView.setAvatar(url: userInfo?.faceURL?.defaultThumbnailURLString, text: userInfo?.nickname, onTap: nil)
            self?._headerView.nameLabel.text = userInfo?.nickname
            self?._contactViewModel.getFriendApplications()
            self?._contactViewModel.getGroupApplications()
        }).disposed(by: _disposeBag)
    }
}

extension YYTextAsyncLayer {
    static let swizzleDisplay: Void = {
        guard #available(iOS 17, *) else { return }
        
        let originalSelector = #selector(display)
        let swizzledSelector = #selector(swizzing_display)
        
        guard let originalMethod = class_getInstanceMethod(YYTextAsyncLayer.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(YYTextAsyncLayer.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    @objc func swizzing_display() {
        if bounds.size.width <= 0 || bounds.size.height <= 0 {
            contents = nil
            return
        } else {
            swizzing_display()
        }
    }
}
