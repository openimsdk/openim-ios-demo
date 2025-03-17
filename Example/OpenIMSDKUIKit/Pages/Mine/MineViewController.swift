
import RxSwift
import OUIIM
import OUICore
import ProgressHUD

public class MineViewController: UIViewController {

    private lazy var _tableView: UITableView = {
        let v = UITableView(frame: .zero, style: .insetGrouped)
        v.register(MineOptionTableViewCell.self, forCellReuseIdentifier: MineOptionTableViewCell.className)
        v.register(BasicInfoCell.self, forCellReuseIdentifier: BasicInfoCell.className)
        v.dataSource = self
        v.delegate = self
        v.separatorStyle = .none
        v.backgroundColor = .clear
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    private let items: [[RowType]] = [[.header],
                                      [.myInfo, .setting, .aboutUs, .logout]]

    private let _viewModel = MineViewModel()
    private let _disposeBag = DisposeBag()

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _tableView.reloadData()
        _viewModel.queryUserInfo()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor
        
        initView()
        bindData()
    }

    private func initView() {
        
        let bgImageView = UIImageView(image: UIImage(named: "mine_background_image"))
        bgImageView.backgroundColor = .systemBlue
        bgImageView.contentMode = .scaleAspectFit
        
        view.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(138.h + UIApplication.statusBarHeight)
        }
        
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(70.h)
            make.leading.bottom.trailing.equalToSuperview()
        }
    }

    private func bindData() {
        _viewModel.currentUserRelay.subscribe(onNext: { [weak self] (user: QueryUserInfo?) in
            guard let self, user != nil else { return }
            
            _tableView.performBatchUpdates { [self] in
                self._tableView.reloadSections(IndexSet(integer: 0), with: .none)
            }
        }).disposed(by: _disposeBag)
    }

    enum RowType: CaseIterable {
        case header
        case myInfo
        case setting
        case invitationCode
        case aboutUs
        case logout

        var title: String {
            switch self {
            case .header:
                return ""
            case .myInfo:
                return "myInfo".innerLocalized()
            case .setting:
                return "accountSetup".innerLocalized()
            case .aboutUs:
                return "aboutUs".innerLocalized()
            case .logout:
                return "logout".innerLocalized()
            case .invitationCode:
                return "invitationCode".localized()
            }
        }

        var icon: UIImage? {
            switch self {
            case .header:
                return UIImage(named: "mine_background_image")
            case .myInfo:
                return UIImage(named: "mine_info_icon")
            case .invitationCode:
                return UIImage(named: "mine_invitation_code")
            case .setting:
                return UIImage(named: "mine_setting_icon")
            case .aboutUs:
                return UIImage(named: "mine_about_icon")
            case .logout:
                return UIImage(named: "mine_logout_icon")
            }
        }
    }
}

extension MineViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        
        if item == .header {
            let cell = tableView.dequeueReusableCell(withIdentifier: BasicInfoCell.className, for: indexPath) as! BasicInfoCell

            let user = _viewModel.currentUserRelay.value
            cell.avatarView.setAvatar(url: user?.faceURL, text: user?.nickname)
            cell.nameLabel.text = user?.nickname
            cell.IDTextFiled.text = user?.userID
            cell.QRCodeTapHandler = { [weak self] in
                guard let user: QueryUserInfo = self?._viewModel.currentUserRelay.value else { return }
                let vc = QRCodeViewController(idString: IMController.addFriendPrefix.append(string: user.userID!))
                vc.avatarView.setAvatar(url: user.faceURL, text: user.nickname)
                vc.nameLabel.text = user.nickname
                vc.tipLabel.text = "qrcodeHint".innerLocalized()
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: MineOptionTableViewCell.className, for: indexPath) as! MineOptionTableViewCell

        cell.titleLabel.text = item.title
        cell.avatarImageView.image = item.icon
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.section][indexPath.row]
        
        if item == .header {
            return 100.h
        }
        
        return 56.h
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        16
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        
        let row: RowType = items[indexPath.section][indexPath.row]
        switch row {
        case .myInfo:
            let vc = ProfileTableViewController(userID: IMController.shared.uid)
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .setting:
            let vc = SettingTableViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        case .logout:
            presentAlert(title: "logoutHint".localized()) { [weak self] in
                self?._viewModel.logout()
            }
        case .invitationCode:





            print("disable invitation code")
        case .aboutUs:
            let vc = AboutUsViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}

extension MineViewController {

    class BasicInfoCell: UITableViewCell, UITextFieldDelegate {

        var QRCodeTapHandler: (() -> Void)?
        
        let avatarView = AvatarView()
        
        lazy var IDTextFiled: UITextField = {
            let v = UITextField()
            v.font = UIFont.f14
            v.textColor = UIColor.c8E9AB0
            v.rightViewMode = .always
            v.rightView = UIImageView(image: UIImage(named: "mine_copy_icon"))
            v.delegate = self

            return v
        }()
        
        let nameLabel: UILabel = {
            let v = UILabel()
            v.font = UIFont.f17
            v.textColor = UIColor.c0C1C33
            
            return v
        }()

        private var _disposeBag = DisposeBag()
        
        private lazy var QRCodeButton: UIButton = {
            let v = UIButton(type: .system)
            v.setImage(UIImage(systemName: "qrcode"), for: .normal)
            v.tintColor = .secondaryLabel
            v.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(QRCodeAction))
            v.addGestureRecognizer(tap)
            
            return v
        }()
        
        @objc
        private func QRCodeAction() {
            self.QRCodeTapHandler?()
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            
            let infoStack = UIStackView(arrangedSubviews: [nameLabel, IDTextFiled])
            infoStack.axis = .vertical
            infoStack.spacing = 4
            
            let hStack = UIStackView(arrangedSubviews: [avatarView, infoStack, UIView(), QRCodeButton])
            hStack.spacing = 8
            hStack.alignment = .center
            hStack.translatesAutoresizingMaskIntoConstraints = false
            
            contentView.addSubview(hStack)
            NSLayoutConstraint.activate([
                hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .margin16),
                hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .margin16),
                hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.margin16),
                hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.margin16),
            ])
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            _disposeBag = DisposeBag()
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            UIPasteboard.general.string = textField.text
            ProgressHUD.success("copySuccessfully".innerLocalized())
            return false
        }
    }
}
