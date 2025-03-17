
import RxSwift
import OUICore
import OUICoreView
import MJRefresh
import ProgressHUD

class MemberListViewController: UIViewController {
    public var onTap: ((GroupMemberInfo) -> Void)?
    
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.rowHeight = 64.h
        v.separatorColor = .clear
        v.tableFooterView = UIView()
        
        let footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?._viewModel.getMoreMembers(completion: { (isNoMore: Bool) in
                if isNoMore {
                    v.mj_footer?.endRefreshingWithNoMoreData()
                } else {
                    v.mj_footer?.endRefreshing()
                }
            })
        })
        footer.isAutomaticallyRefresh = false
        v.mj_footer = footer
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        
        return v
    }()
    
    lazy var headerTableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.separatorColor = .clear
        v.rowHeight = 64.h
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        v.tableFooterView = UIView()
        
        return v
    }()
    
    lazy var header: UIView = {
        let v = UIView()
        
        return v
    }()
    
    private let _viewModel: MemberListViewModel
    private let _disposeBag = DisposeBag()
    
    private lazy var addItem: PopoverTableViewController.MenuItem = {
        let v = PopoverTableViewController.MenuItem(title: "invite".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_add_friend_icon")) { [weak self] in
            guard let self else { return }
            
#if ENABLE_ORGANIZATION
            let vc = MyContactsViewController(types: [.friends, .staff], multipleSelected: true)
#else
            let vc = MyContactsViewController(types: [.friends], multipleSelected: true)
#endif
            vc.title = "邀请群成员".innerLocalized()
            let blocked = _viewModel.membersRelay.value.compactMap({ $0.userID }) + [IMController.shared.uid]
            
            vc.selectedContact(blocked: blocked) { [weak self] (r: [ContactInfo]) in
                guard let self else { return }
                
                ProgressHUD.animate()
                let groupID = self._viewModel.groupInfo.groupID
                let uids = r.compactMap { $0.ID }
                IMController.shared.inviteUsersToGroup(groupId: groupID, uids: uids) { [weak vc, self] in
                    ProgressHUD.success("invitationSuccessful".innerLocalized())
                    self.navigationController?.popToViewController(self, animated: true)
                }
            }
            navigationController?.pushViewController(vc, animated: true)
        }
        
        return v
    }()
    
    private lazy var deleteItem: PopoverTableViewController.MenuItem = {
        let v = PopoverTableViewController.MenuItem(title: "移除".innerLocalized() + "成员".innerLocalized(), icon: UIImage(nameInBundle: "chat_menu_create_work_group_icon")) { [weak self] in
            guard let self else { return }
            
            let vc = SelectContactsViewController(types: [.members], sourceID: self._viewModel.groupInfo.groupID)
            let owner = self._viewModel.ownerAndAdminRelay.value.first(where: { [weak self] m in
                return m.roleLevel == .owner
            })?.userID
            
            var blocked = _viewModel.ownerAndAdminRelay.value.compactMap({ $0.userID })
            
            if owner == IMController.shared.uid {
                blocked = [IMController.shared.uid]
            }
            
            vc.selectedContact(hasSelected: [], blocked: blocked != nil ? blocked : []) { [weak vc] (_, users: [ContactInfo]) in
                let groupID = self._viewModel.groupInfo.groupID
                
                ProgressHUD.animate()
                let uids = users.compactMap { $0.ID }
                IMController.shared.kickGroupMember(groupId: groupID, uids: uids) { [self] _ in
                    ProgressHUD.dismiss()
                    self.navigationController?.popToViewController(self, animated: true)
                }
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        return v
    }()
    
    init(viewModel: MemberListViewModel) {
        _viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    private let _menuView = PopoverTableViewController()
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "groupMember".innerLocalized()
        navigationItem.hidesSearchBarWhenScrolling = false
        
        initView()
        bindData()
        _tableView.mj_footer?.beginRefreshing()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.searchController?.isActive = false
    }
    
    private func initView() {
        definesPresentationContext = true
        
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        _tableView.tableHeaderView = headerTableView
        
        _menuView.items = [addItem]
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .init(nameInBundle: "common_more_btn_icon"), style: .done, target: self, action: #selector(tapMore(_:)))
    }
    
    @objc func tapMore(_ sender: UIBarButtonItem) {
        _menuView.show(in: self, itemSender: sender)
    }
    
    private func bindData() {
        
        _viewModel.ownerAndAdminRelay.subscribe(onNext: { [weak self] infos in
            guard let sself = self else { return }
            var headerFrame = sself.headerTableView.frame
            
            headerFrame.size.height = CGFloat(infos.count) * 64.h
            sself.headerTableView.frame = headerFrame
            sself._tableView.tableHeaderView = sself.headerTableView
            
            if infos.contains(where: { member in
                return member.userID == IMController.shared.uid
            }) {
                sself._menuView.items = [sself.addItem, sself.deleteItem]
            } else {
                sself._menuView.items = [sself.addItem]
            }
        })
        
        _viewModel.ownerAndAdminRelay.bind(to: headerTableView.rx.items(cellIdentifier: FriendListUserTableViewCell.className,
                                                                        cellType: FriendListUserTableViewCell.self)) {[weak self] _, model, cell in
            
            cell.titleLabel.text = model.nickname

            if model.isOwnerOrAdmin {
                cell.trainingLabel.textColor = .c8E9AB0
                cell.trainingLabel.font = .f17
                cell.trainingLabel.text = model.roleLevelString
            } else {
                cell.trainingLabel.text = nil
            }
            cell.avatarImageView.setAvatar(url: model.faceURL, text: model.nickname)
        }.disposed(by: _disposeBag)
        
        headerTableView.rx.modelSelected(GroupMemberInfo.self).subscribe(onNext: { [weak self] member in
            guard let self, _viewModel.groupInfo.lookMemberInfo == 0 else { return }
            
            let vc = UserDetailTableViewController(userId: member.userID ?? "", groupId: member.groupID)
            navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)
        
        _viewModel.membersRelay.bind(to: _tableView.rx.items(cellIdentifier: FriendListUserTableViewCell.className,
                                                             cellType: FriendListUserTableViewCell.self)) {[weak self] _, model, cell in
            cell.titleLabel.text = model.nickname
            cell.avatarImageView.setAvatar(url: model.faceURL, text: model.nickname)
            
        }.disposed(by: _disposeBag)
        
        _tableView.rx.modelSelected(GroupMemberInfo.self).subscribe(onNext: { [weak self] member in
            guard let self, _viewModel.groupInfo.lookMemberInfo == 0 else { return }
            if onTap != nil {
                onTap!(member)
            } else {
                let vc = UserDetailTableViewController(userId: member.userID ?? "", groupId: member.groupID)
                navigationController?.pushViewController(vc, animated: true)
            }
        }).disposed(by: _disposeBag)
    }
    
    private func imageWithUIView(view: UIView) -> UIImage {
        UIGraphicsBeginImageContext(view.bounds.size)
        let ctx = UIGraphicsGetCurrentContext()
        view.layer.render(in: ctx!)
        let tImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return tImage!;
    }
    
    
    deinit {
        print("dealloc \(type(of: self))")
    }
}
