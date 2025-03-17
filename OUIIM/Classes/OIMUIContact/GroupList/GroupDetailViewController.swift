
import OUICore
import OUICoreView
import RxSwift
import RxCocoa
import ProgressHUD

class GroupDetailViewController: UIViewController {
    private let _viewModel: GroupDetailViewModel
    private let _disposeBag = DisposeBag()
    init(groupId: String) {
        _viewModel = GroupDetailViewModel(groupId: groupId)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let v = UITableView(frame: .zero, style: .grouped)
        v.tableFooterView = UIView()
        v.dataSource = self
        v.delegate = self
        v.separatorStyle = .none
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        v.backgroundColor = .clear
        v.rowHeight = UITableView.automaticDimension
        v.register(GroupBasicInfoCell.self, forCellReuseIdentifier: GroupBasicInfoCell.className)
        v.register(NewGroupMemberCell.self, forCellReuseIdentifier: NewGroupMemberCell.className)
        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)

        return v
    }()
    
    lazy var enterButton: UIButton = {
        let v = UIButton(type: .system)
        v.tintColor = .white
        v.backgroundColor = .c0089FF
        v.layer.cornerRadius = 5
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            if (try? self?._viewModel.isInGroupSubject.value()) == true {
                self?.enterChat()
            } else {
                self?.applyJoinGroup()
            }
        }).disposed(by: _disposeBag)
        
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor
        
        initView()
        bindData()
        _viewModel.getGroupInfo()
    }

    private var sectionItems: [[RowType]] = [
        [.header],
        [.identifier],
    ]

    private func initView() {
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let bottomView = UIView()
        bottomView.backgroundColor = .systemBackground
        
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(UIApplication.safeAreaInsets.bottom + 80.h)
        }
        
        bottomView.addSubview(enterButton)
        enterButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.top.equalToSuperview().inset(16)
            make.height.equalTo(44.h)
        }
    }

    private func bindData() {
        _viewModel.isInGroupSubject.subscribe(onNext: { [weak self] (isInGroup: Bool) in
            guard let self else { return }
            if !isInGroup {
                self.sectionItems = [
                    [.header],
                    [.identifier],

                ]
                self.enterButton.setTitle("applyJoin".innerLocalized(), for: .normal)
            } else {
                self.sectionItems = [
                    [.header],
                    [.members],
                    [.identifier],

                ]
                self.enterButton.setTitle("enterGroup".innerLocalized(), for: .normal)
            }
            self.tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.membersCountRelay.subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: _disposeBag)
    }
    
    private func applyJoinGroup() {
        if _viewModel.groupInfoRelay.value?.needVerification == .directly {
            _viewModel.joinCurrentGroup { [weak self] r in
                self?.enterChat()
            }
        } else {
            let vc = ApplyViewController(groupID: _viewModel.groupInfoRelay.value!.groupID)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func enterChat() {
        IMController.shared.getConversation(sessionType: .superGroup,
                                            sourceId: _viewModel.groupId) { [weak self] (conversation: ConversationInfo?) in
            guard let self, let conversation else { return }
            
            let vc = ChatViewControllerBuilder().build(conversation)
            navigationController?.pushViewController(vc, animated: true)
            if let root = navigationController?.viewControllers.first {
                navigationController?.viewControllers.removeAll(where: { controller in
                    controller != root && controller != vc
                })
            }
        }
    }

    enum RowType {
        case header
        case members
        case identifier

        var title: String {
            switch self {
            case .header:
                return ""
            case .members:
                return "groupMember".innerLocalized()
            case .identifier:
                return "".innerLocalized()
            }
        }
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }
}

extension GroupDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        16
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        UIView()
    }

    func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        nil
    }

    func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }

    func numberOfSections(in _: UITableView) -> Int {
        return sectionItems.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .header:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupBasicInfoCell.className) as! GroupBasicInfoCell
            let groupInfo = _viewModel.groupInfoRelay.value
            cell.avatarView.setAvatar(url: groupInfo?.faceURL, text: groupInfo?.groupName)
            
            if let count = groupInfo?.memberCount, count > 0 {
                cell.titleLabel.text = groupInfo?.groupName?.append(string: "(\(count))")
            } else {
                cell.titleLabel.text = groupInfo?.groupName
            }
            
            let attach = NSTextAttachment(image: UIImage(systemName: "clock.fill")!)
            attach.bounds = CGRect(x: 4, y: -3, width: 16, height: 16)
            let attachment = NSMutableAttributedString(attachment: attach)
            
            let date = Date.formatDate("yyyy年MM月dd日", of: (groupInfo?.createTime ?? 0) / 1000)
            attachment.append(NSAttributedString(string: " \(date)"))
            
            cell.subLabel.attributedText = attachment
            
            return cell
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewGroupMemberCell.className) as! NewGroupMemberCell
            cell.memberCollectionView.dataSource = nil
            _viewModel.membersRelay.asDriver(onErrorJustReturn: []).drive(cell.memberCollectionView.rx.items) { (collectionView: UICollectionView, row, item: GroupMemberInfo) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewGroupMemberCell.ImageCollectionViewCell.className, for: IndexPath(row: row, section: 0)) as! NewGroupMemberCell.ImageCollectionViewCell

                cell.avatarView.setAvatar(url: item.faceURL, text: item.nickname, fullText: true)
                
                return cell
            }.disposed(by: cell.disposeBag)
            
            cell.reloadData()
            
            _viewModel.membersCountRelay.map { "\("nPerson".innerLocalizedFormat(arguments: $0))" }.bind(to: cell.countLabel.rx.text).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            
            return cell

        case .identifier:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
            cell.subtitleLabel.text = _viewModel.groupId
            cell.subtitleLabel.textColor = .c8E9AB0
            cell.titleLabel.text = rowType.title
            cell.accessoryType = .none
            
            return cell
        }
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        
        switch rowType {
        case .members:
            let vc = MemberListViewController(viewModel: MemberListViewModel(groupInfo: _viewModel.groupInfoRelay.value!))
            navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.groupId
            ProgressHUD.success("copySuccessfully".innerLocalized())
            
        default:
            break
        }
    }
}
