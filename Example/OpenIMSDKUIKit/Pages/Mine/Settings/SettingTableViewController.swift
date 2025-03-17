
import OUICore
import RxSwift
import ProgressHUD
import Localize_Swift

class SettingTableViewController: UITableViewController {
    let _disposeBag = DisposeBag()
    
    private let _viewModel = SettingViewModel()
    private let rowItems: [[RowType]] = [
        [.blocked, .language],
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
        navigationItem.title = "accountSetup".innerLocalized()
        
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
        case .blocked:
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
        case .blocked:
            let vc = BlockedListViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    enum RowType: CaseIterable {
        case language
        case blocked
        
        var title: String {
            switch self {
            case .language:
                return "language".innerLocalized()
            case .blocked:
                return "blacklist".innerLocalized()
            }
        
        }
    }
}
