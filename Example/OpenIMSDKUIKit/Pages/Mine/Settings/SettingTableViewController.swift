
import OUICore
import RxSwift
import ProgressHUD
import Localize_Swift

class SettingTableViewController: UITableViewController {
    let _disposeBag = DisposeBag()
    
    private let _viewModel = SettingViewModel()
    private let rowItems: [[RowType]] = [
        [.notDisturb, .ring, .vibration],
        [.forbiddenAddFriend, .blocked, .language],
        [.unlock, .modifyPsw, .clearHistory]
    ]
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        bindData()
        initView()
        setText()
        _viewModel.getSettingInfo()
        NotificationCenter.default.addObserver(self, selector: #selector(setText), name: NSNotification.Name( LCLLanguageChangeNotification), object: nil)
    }
    
    @objc func setText(){
        navigationItem.title = "账号设置".localized()
        
        tableView.reloadData()
    }

    private func configureTableView() {
        tableView.separatorStyle = .none
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.className)
        tableView.tableFooterView = UIView()
    }

    private func initView() {
        view.backgroundColor = DemoUI.color_F7F7F7
    }
    
    private func bindData() {
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return rowItems.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowItems[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType: RowType = rowItems[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className) as! OptionTableViewCell
        
        switch rowType {
        case .language:
            cell.titleLabel.text = rowType.title
        case .notDisturb:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.notDisturbRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
                self?._viewModel.toggleNotDisturbStatus()
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title

            return cell
        case .blocked:
            cell.titleLabel.text = rowType.title
        case .ring:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.setRingRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
                self?._viewModel.toggleRing()
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .vibration:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.setVibrationRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
                self?._viewModel.toggleVibrationRelay()
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .forbiddenAddFriend:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.className) as! SwitchTableViewCell
            _viewModel.setForbbidenAddFriendRelay.bind(to: cell.switcher.rx.isOn).disposed(by: cell.disposeBag)
            cell.switcher.rx.controlEvent(.valueChanged).subscribe(onNext: { [weak self] in
                self?._viewModel.toggleForbbidenAddFriendRelay()
            }).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            return cell
        case .unlock:
            cell.titleLabel.text = rowType.title
        case .clearHistory:
            cell.titleLabel.text = rowType.title
            cell.titleLabel.textColor = .cFF381F
        case .modifyPsw:
            cell.titleLabel.text = rowType.title
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60.h
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        16
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType: RowType = rowItems[indexPath.section][indexPath.row]
        switch rowType {
        case .language:
            let vc = LanguageTableViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .notDisturb:
            break
        case .blocked:
            let vc = BlockedListViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .unlock:
            let vc = ScreenLockSettingViewController()
            navigationController?.pushViewController(vc, animated: true)
            break
        case .clearHistory:
            presentAlert(title: "您确定要清空聊天记录吗？".innerLocalized()) {
                ProgressHUD.animate()
                self._viewModel.clearHistory { res in
                    if res != nil {
                        ProgressHUD.success("success".localized())
                    } else {
                        ProgressHUD.error("failure".localized())
                    }
                }
            }
        case .modifyPsw:
            let vc = ModifyPswViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }

    enum RowType: CaseIterable {
    
        case ring
        case vibration
        case notDisturb
        case forbiddenAddFriend
        case unlock
        case language
        case blocked
        case clearHistory
        case modifyPsw
        
        var title: String {
            switch self {
            case .language:
                return "语言".localized()
            case .notDisturb:
                return "勿扰模式".localized()
            case .blocked:
                return "通讯录黑名单".localized()
            case .ring:
                return "消息提示音".localized()
            case .vibration:
                return "震动".localized()
            case .forbiddenAddFriend:
                return "禁止加我为好友".localized()
            case .unlock:
                return "解锁设置".localized()
            case .clearHistory:
                return "清空聊天记录".localized()
            case .modifyPsw:
                return "修改密码".localized()
            }
        
        }
    }
}
