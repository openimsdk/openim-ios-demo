
import OUICore
import ProgressHUD
import RxSwift
import OUICoreView

#if ENABLE_CALL
import OUICalling
#endif

enum UserDetailFor {
    case groupMemberInfo
    case card
}

class SpacerCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = UIColor.cF8F9FA
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UserDetailTableViewController: UIViewController {
    private let avatarView = AvatarView()
    
    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33

        return v
    }()
    
    private lazy var IDLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f14
        v.textColor = UIColor.c8E9AB0
        v.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer()
        v.addGestureRecognizer(tap)
        
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            UIPasteboard.general.string = self?._viewModel.userId
            ProgressHUD.success("ID已复制".innerLocalized())
        }).disposed(by: _disposeBag)
        
        return v
    }()
    
    private lazy var sendMessageBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(nameInBundle: "profile_message_button_icon"), for: .normal)
        v.setTitle("发消息".innerLocalized(), for: .normal)
        v.tintColor = .white
        v.titleLabel?.font = UIFont.f17
        v.backgroundColor = UIColor.c0089FF
        v.layer.cornerRadius = 6
        v.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        v.contentHorizontalAlignment = .center
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            self?._viewModel.createSingleChat(onComplete: { [weak self] info in
                let vc = ChatViewControllerBuilder().build(info)
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
                if let root = self?.navigationController?.viewControllers.first {
                    self?.navigationController?.viewControllers.removeAll(where: { controller in
                        controller != root && controller != vc
                    })
                }
            })
        }).disposed(by: _disposeBag)
        return v
    }()
    
#if ENABLE_CALL
    private lazy var mediaBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(nameInBundle: "profile_media_button_icon"), for: .normal)
        v.setTitle("音视频通话".innerLocalized(), for: .normal)
        v.tintColor = UIColor.c0C1C33
        v.titleLabel?.font = UIFont.f17
        v.backgroundColor = .white
        v.layer.cornerRadius = 6
        v.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        v.contentHorizontalAlignment = .center
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.showMediaLinkSheet()
        }).disposed(by: _disposeBag)
        return v
    }()
#endif

    private lazy var addFriendBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(nameInBundle: "chat_menu_add_friend_icon"), for: .normal)
        v.setTitle(" " + "加好友".innerLocalized(), for: .normal)
        v.tintColor = .white
        v.backgroundColor = UIColor.c0089FF
        v.titleLabel?.font = UIFont.f14
        v.layer.cornerRadius = 6
        v.isHidden = true
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            let vc = ApplyViewController(userID: self?._viewModel.userId)
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)
        return v
    }()

    private let _disposeBag = DisposeBag()
    private let _viewModel: UserDetailViewModel
    private var hasViewAppeared = false

    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.backgroundColor = .clear
        v.separatorStyle = .none
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        
        let headerView: UIView = {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 86))
            v.backgroundColor = .tertiarySystemBackground
            
            let vStack: UIStackView = {
                let v = UIStackView(arrangedSubviews: [nameLabel, IDLabel])
                v.axis = .vertical
                v.distribution = .equalCentering
                v.spacing = 4
                
                return v
            }()
            
            let hStack: UIStackView = UIStackView(arrangedSubviews: [avatarView, vStack, UIView(), addFriendBtn])
            hStack.alignment = .center
            hStack.spacing = 8
            
            v.addSubview(hStack)
            hStack.snp.makeConstraints { make in
                make.edges.lessThanOrEqualToSuperview().inset(8)
            }
            
            addFriendBtn.snp.makeConstraints { make in
                make.width.equalTo(70)
                make.height.equalTo(30)
            }
            return v
        }()
        
        v.tableHeaderView = headerView
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        v.register(MultipleTextLineCell.self, forCellReuseIdentifier: MultipleTextLineCell.className)
        v.register(SpacerCell.self, forCellReuseIdentifier: SpacerCell.className)
        v.delegate = self
        v.dataSource = self
        v.tableFooterView = UIView()
        return v
    }()
    
    private var rowItems: [RowType] = [.spacer]
    private var buttonStack: UIStackView?
    private var offsetY: CGFloat = 0
    
    init(userId: String, groupId: String? = nil, groupInfo: GroupInfo? = nil, groupMemberInfo: GroupMemberInfo? = nil, userInfo: PublicUserInfo? = nil, userDetailFor: UserDetailFor = .groupMemberInfo) {
        _viewModel = UserDetailViewModel(userId: userId, groupId: groupId ?? (groupInfo?.groupID), groupInfo: groupInfo, groupMemberInfo: groupMemberInfo, userInfo: userInfo, userDetailFor: userDetailFor)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("UserDetailTableViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor

        initView()
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _viewModel.getUserOrMemberInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasViewAppeared = true
    }
    
    private func initView() {
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        if _viewModel.userId == IMController.shared.uid {

            return
        }
        
        buttonStack = UIStackView(arrangedSubviews: [sendMessageBtn])
        buttonStack!.isHidden = true
#if ENABLE_CALL
        mediaBtn.snp.makeConstraints { make in
            make.height.equalTo(46)
        }
        buttonStack!.insertArrangedSubview(mediaBtn, at: 0)
#endif
    
        buttonStack!.spacing = 16
        buttonStack!.distribution = .fillEqually
        buttonStack!.alignment = .center
        
        sendMessageBtn.snp.makeConstraints { make in
            make.height.equalTo(46)
        }
        
        view.addSubview(buttonStack!)
        buttonStack!.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-40.h)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
    private func showMediaLinkSheet() {
        presentMediaActionSheet { [weak self] in
            self?.startMedia(isVideo: false)
        } videoHandler: { [weak self] in
            self?.startMedia(isVideo: true)
        }
    }
    
    @objc private func rightButtonAction() {
        let vc = UserProfileTableViewController(userId: self._viewModel.userId, isFriend: _viewModel.isFriend, allowAddFriend: _viewModel.allowAddFriend.value)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func startMedia(isVideo: Bool) {
#if ENABLE_CALL
        CallingManager.manager.startLiveChat(othersID: [_viewModel.userId], isVideo: isVideo)
#endif
    }
    
    private func bindData() {        
        _viewModel.userInfoRelay.subscribe(onNext: { [weak self] userInfo in
            guard let userInfo, let sself = self else { return }
            
            sself.avatarView.setAvatar(url: userInfo.faceURL, text: userInfo.nickname, onTap: { [weak self] in
                guard let self, let avatar = userInfo.faceURL, let url = URL(string: avatar) else { return }
                
                let controller = MediaPreviewViewController(resources: [MediaResource(thumbUrl: url, url: url)])
                
                controller.showIn(controller: sself) { [sself] index in
                    sself.avatarView
                }
            })
            var name = userInfo.nickname
            
            if let remark = userInfo.remark, !remark.isEmpty {
                name = name?.append(string: "(\(remark))")
            }
            sself.nameLabel.text = name
            sself.IDLabel.text = userInfo.userID
            
#if ENABLE_ORGANIZATION

            if !sself._viewModel.organizationInfo.value.isEmpty, !sself.rowItems.contains(.organization) {
                sself.rowItems.append(.spacer)
                sself.rowItems.append(.organization)
            }
#endif
            if !sself.rowItems.contains(.profile) {
                sself.rowItems.append(.spacer)
                sself.rowItems.append(.profile)
#if ENABLE_MOMENTS
                sself.rowItems.append(.moments)
#endif
            }
            
            if !sself._viewModel.isMine, userInfo != nil {
                sself.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(sself.rightButtonAction))
                sself.navigationItem.rightBarButtonItem!.isEnabled = false
            }
            
            sself._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.memberInfoRelay.subscribe(onNext: { [weak self] (memberInfo: GroupMemberInfo?) in
            guard let memberInfo, let sself = self else { return }
            
            sself.avatarView.setAvatar(url: memberInfo.faceURL, text: memberInfo.nickname, onTap: nil)
            sself.nameLabel.text = memberInfo.nickname
            sself.IDLabel.text = memberInfo.userID
            sself.addFriendBtn.isHidden = true
            
            guard sself._viewModel.groupId != nil else { return }
            sself.rowItems = [/*.nickName,*/.spacer, .joinTime, .joinSource]

            sself.rowItems.append(.spacer)
            sself.rowItems.append(.profile)
            
            sself._tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.allowAddFriend.subscribe(onNext: { [weak self] allow in
            self?.addFriendBtn.isHidden = !allow
            self?.navigationItem.rightBarButtonItem?.isEnabled = true
        }).disposed(by: _disposeBag)
        
        _viewModel.allowSendMsg.subscribe(onNext: { [weak self] allow in
            guard let self else { return }
            
            buttonStack?.isHidden = !allow
        }).disposed(by: _disposeBag)
    }
}

extension UserDetailTableViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard hasViewAppeared, buttonStack != nil, scrollView.contentSize.height + (navigationController?.navigationBar.frame.maxY ?? 64) > buttonStack!.frame.minY else { return }
        
        if scrollView.contentOffset.y > offsetY, scrollView.contentOffset.y > 0 {

            UIView.animate(withDuration: 0.2) { [self] in
                buttonStack!.alpha = 0
            } completion: { [self] _ in
                buttonStack!.isHidden = true
            }
            
        } else if scrollView.contentOffset.y < offsetY, !scrollView.isDecelerating {

            UIView.animate(withDuration: 0.2) { [self] in
                buttonStack!.alpha = 1
            } completion: { [self] _ in
                buttonStack!.isHidden = false
            }
        }
        offsetY = scrollView.contentOffset.y;
    }
}

extension UserDetailTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rowItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let rowType: RowType = rowItems[indexPath.row]
        
        if rowType == .spacer {
            return tableView.dequeueReusableCell(withIdentifier: SpacerCell.className, for: indexPath)
        }

        if rowType == .profile  {
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            
            cell.accessoryType = .none
            cell.subtitleLabel.textAlignment = .left
            
            cell.titleLabel.text = rowType.title
            cell.accessoryType = .disclosureIndicator
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
        
        cell.accessoryType = .none
        cell.subtitleLabel.textAlignment = .left
        
        guard let info = _viewModel.memberInfoRelay.value else { return cell }
        cell.titleLabel.text = rowType.title
        cell.spacer.isHidden = true
        
        if rowType == .nickName {
            cell.subtitleLabel.text = info.nickname
        } else if rowType == .joinTime {
            cell.titleLabel.textColor = .c8E9AB0
            cell.subtitleLabel.text = FormatUtil.getFormatDate(formatString: "yyyy-MM-dd", of: info.joinTime / 1000)
        } else if rowType == .joinSource {
            cell.titleLabel.textColor = .c8E9AB0
            cell.subtitleLabel.text = info.joinWay
        }
                
        return cell
    }
    
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.row]
        switch rowType {
        case .profile:
            let vc = ProfileTableViewController(userID: _viewModel.userId)
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType: RowType = rowItems[indexPath.row]
        
        if rowType == .spacer {
            return 10
        }
        return UITableView.automaticDimension
    }
    
    enum RowType {
        case nickName
        case joinTime
        case joinSource
        case profile
        case spacer
        
        var title: String {
            switch self {
            case .nickName:
                return "群昵称".innerLocalized()
            case .joinTime:
                return "入群时间".innerLocalized()
            case .joinSource:
                return "入群方式".innerLocalized()
            case .profile:
                return "个人资料".innerLocalized()
            case .spacer:
                return ""
            }
        }
    }
}
