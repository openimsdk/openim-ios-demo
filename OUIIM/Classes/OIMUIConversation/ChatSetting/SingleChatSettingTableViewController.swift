
import RxSwift
import ProgressHUD
import OUICore
import OUICoreView

class SingleChatSettingTableViewController: UITableViewController {
    private let _viewModel: SingleChatSettingViewModel
    
    init(viewModel: SingleChatSettingViewModel, style: UITableView.Style) {
        _viewModel = viewModel
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        configureTableView()
        bindData()
        initView()
        _viewModel.getConversationInfo()
    }
    
    private var sectionItems: [[RowType]] = [
        [.members]
    ]
    
    private let _disposeBag = DisposeBag()
    
    
    private func configureTableView() {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.register(SingleChatMemberTableViewCell.self, forCellReuseIdentifier: SingleChatMemberTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
    }
    
    
    private func bindData() {
    }
    
    private func initView() {}
    
    deinit {
        print("deinit")
    }
    
    func newGroup() {
        let vc = SelectContactsViewController()
        vc.selectedContact(hasSelected: _viewModel.membesRelay.value.compactMap({ $0.userID })) { [weak self] _, r in
            guard let self else { return }
            let users = r.map {UserInfo(userID: $0.ID!, nickname: $0.name, faceURL: $0.faceURL)}
            let vc = NewGroupViewController(users: users, groupType: .working)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    enum RowType: CaseIterable {
        case members
        
        var title: String {
            switch self {
            case .members:
                return ""
            }
        }
        
        var subTitle: String {
            switch self {
            default:
                return ""
            }
        }
    }
    
    override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 12
    }
    
    override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        
        if rowType == .members {
            return UITableView.automaticDimension
        }
        
        return 60
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    override func numberOfSections(in _: UITableView) -> Int {
        return sectionItems.count
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: SingleChatMemberTableViewCell.className) as! SingleChatMemberTableViewCell
            _viewModel.membesRelay.asDriver(onErrorJustReturn: []).drive(cell.memberCollectionView.rx.items) { (collectionView, row, item: UserInfo) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SingleChatMemberTableViewCell.MemberCell.className, for: IndexPath(row: row, section: 0)) as! SingleChatMemberTableViewCell.MemberCell
                if item.isAddButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_add_btn_icon")
                } else {
                    cell.avatarView.setAvatar(url: item.faceURL, text: item.nickname, placeHolder: "contact_my_friend_icon")
                }
                cell.nameLabel.text = item.nickname
                
                return cell
            }.disposed(by: cell.disposeBag)
            
            cell.memberCollectionView.rx.modelSelected(UserInfo.self).subscribe(onNext: { [weak self] (userInfo: UserInfo) in
                guard let sself = self else { return }
                if userInfo.isAddButton {
                    sself.newGroup()
                } else {
                    let info = PublicUserInfo(userID: userInfo.userID, nickname: userInfo.nickname, faceURL: userInfo.faceURL)
                    let vc = UserDetailTableViewController(userId: userInfo.userID, groupId: sself._viewModel.conversation.groupID, userInfo: info)
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }).disposed(by: cell.disposeBag)
            return cell
        }
    }
}
