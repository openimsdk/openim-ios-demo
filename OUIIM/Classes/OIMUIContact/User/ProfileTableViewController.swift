
import Photos
import RxSwift
import ProgressHUD
import OUICore

open class ProfileTableViewController: UITableViewController {
    
    public init(userID: String) {
        super.init(style: .insetGrouped)
        self.userID = userID
        _viewModel = UserProfileViewModel(userId: userID, groupId: nil)
    }
    
    public func getUserOrMemberInfo() {
        _viewModel.getUserOrMemberInfo()
    }
    
    public var user: UserInfo?
    
    public func reloadData() {
        tableView.reloadData()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var _viewModel: UserProfileViewModel!
    private var userID: String?
    public var canEdit = true
    
    open var rowItems: [[RowType]] {
#if ENABLE_ORGANIZATION
        [
            [.avatar, .nickname, .gender, .birthday],
            [.landline, .phone, .email]
        ]
        #else
        [
            [.avatar, .nickname, .gender, .birthday],
            [.phone, .email]
        ]
#endif
    }

    private let _disposeBag = DisposeBag()

    open override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "personalInfo".innerLocalized()
        
        configureTableView()
        bindData()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getUserOrMemberInfo()
    }

    private func configureTableView() {
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(OptionImageTableViewCell.self, forCellReuseIdentifier: OptionImageTableViewCell.className)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .viewBackgroundColor
    }

    private func bindData() {
        _viewModel.userInfoRelay.subscribe(onNext: {[weak self] info in
            self?.user = info
            self?.tableView.reloadData()
        }).disposed(by: _disposeBag)
    }
    
    private func callPhoneTel(phone : String){
        let  phoneUrlStr = "tel://" + phone
        if let url = URL(string: phoneUrlStr), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        rowItems.count
    }
    public override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        rowItems[section].count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = rowItems[indexPath.section][indexPath.row]

        let user: UserInfo? = _viewModel.userInfoRelay.value
        
        if rowType == .avatar || rowType == .qrcode {
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionImageTableViewCell.className, for: indexPath) as! OptionImageTableViewCell
            cell.titleLabel.text = rowType.title
            if rowType == .avatar {
                cell.avatarView.setAvatar(url: user?.faceURL, text: user?.nickname)
            } else {
                cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "common_qrcode_icon")
                cell.avatarView.backgroundColor = .clear
            }
            cell.accessoryType = _viewModel.isMine && canEdit ? .disclosureIndicator : .none
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
        cell.titleLabel.text = rowType.title
        cell.titleLabel.textColor = cell.subtitleLabel.textColor
        cell.accessoryType = _viewModel.isMine && canEdit ? .disclosureIndicator : .none
        
        switch rowType {
        
        case .nickname:
            cell.subtitleLabel.text = user?.nickname
            
        case .gender:
            cell.subtitleLabel.text = user?.gender?.description

        case .birthday:
            let birth = user?.birth != nil ? (user!.birth! / 1000) : 0
            cell.subtitleLabel.text = FormatUtil.getFormatDate(of: birth)

        case .phone:
            cell.subtitleLabel.text = user?.phoneNumber
            cell.accessoryType = .none

        case .identifier:
            cell.subtitleLabel.text = user?.userID
            
        case .landline:
            cell.subtitleLabel.text = user?.landline
            cell.accessoryType = .none
            
        case .email:
            cell.subtitleLabel.text = user?.email
            
        default:
            break
        }
        
        return cell
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       60
    }
    
    public override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        16
    }
    
    public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }
    
    public override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    open override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = rowItems[indexPath.section][indexPath.row]
        let user: UserInfo? = _viewModel.userInfoRelay.value
        
        switch rowType {
        case .phone:
            callPhoneTel(phone: user?.phoneNumber ?? "")
            break
        case .qrcode:
            guard let user = _viewModel.userInfoRelay.value else { return }
            let vc = QRCodeViewController(idString: IMController.addFriendPrefix.append(string: user.userID))
            vc.nameLabel.text = user.nickname
            vc.avatarView.setAvatar(url: user.faceURL, text: user.nickname)
            vc.tipLabel.text = "qrcodeHint".innerLocalized()
            navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.userInfoRelay.value?.userID
            ProgressHUD.success("copySuccessfully")
        default:
            break
        }
    }

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }

    public enum RowType: CaseIterable {
        case avatar
        case nickname
        case gender
        case birthday
        case phone
        case qrcode
        case identifier
        case spacer
        case landline
        case email

        var title: String {
            switch self {
            case .avatar:
                return "avatar".innerLocalized()
            case .nickname:
                return "nickname".innerLocalized()
            case .gender:
                return "gender".innerLocalized()
            case .phone:
                return "mobile".innerLocalized()
            case .qrcode:
                return "qrcode".innerLocalized()
            case .identifier:
                return "ID".innerLocalized()
            case .birthday:
                return "birthDay".innerLocalized()
            case .spacer:
                return ""
            case .landline:
                return "tel".innerLocalized()
            case .email:
                return "email".innerLocalized()
            }
        }
    }
}
