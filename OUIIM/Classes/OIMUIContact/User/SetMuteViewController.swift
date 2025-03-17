import OUICore
import RxSwift
import ProgressHUD

class SetMuteViewController: UITableViewController {
    
    init(userID: String, groupID: String) {
        super.init(nibName: nil, bundle: nil)
        viewModel = UserDetailViewModel(userId: userID, groupId: groupID, userDetailFor: .groupMemberInfo)
    }
    
    var onSave: ((Int) -> Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let disposeBag = DisposeBag()
    private var viewModel: UserDetailViewModel!
    
    private var items: [ItemType: [ItemModel]] = [.normal:
                                                [ItemModel(text: "tenMinutes".innerLocalized(), seconds: 10 * 60),
                                                 ItemModel(text: "oneHour".innerLocalized(), seconds: 1 * 3600),
                                                 ItemModel(text: "twelveHours".innerLocalized(), seconds: 12 * 3600),
                                                 ItemModel(text: "oneDay".innerLocalized(), seconds: 24 * 3600),
                                                 ItemModel(text: "unmute".innerLocalized(), seconds: 0)
                                                ], .input: [ItemModel(text: "custom".innerLocalized(), seconds: 0)]]
    
    private var preSelectedIndexPath: IndexPath?
    private var seconds: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "setMute".innerLocalized()
        
        let saveButton = UIBarButtonItem(title: "save".innerLocalized(), style: .done, target: nil, action: nil)
        navigationItem.rightBarButtonItem = saveButton
        
        saveButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            ProgressHUD.animate()
            viewModel.setMutedSeconds(seconds: seconds, acceptValue: false) { [self] r in
                if let r {
                    ProgressHUD.dismiss()
                    self.onSave?(self.seconds)
                    self.navigationController?.popViewController(animated: true)
                } else {
                    ProgressHUD.error()
                }
            }
        }).disposed(by: disposeBag)
        
        tableView = UITableView(frame: tableView.bounds, style: .insetGrouped)
        tableView.rowHeight = 46
        tableView.register(SetMuteCell.self, forCellReuseIdentifier: SetMuteCell.className)
    }
    
    enum ItemType: Int, CaseIterable {
        case normal = 0
        case input = 1
    }
    
    struct ItemModel {
        let text: String
        let seconds: Int
    }
    
    deinit {
        print("\(#function) - \(type(of: self))")
    }
}

extension SetMuteViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = ItemType(rawValue: section)!
        
        return items[key]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SetMuteCell.className, for: indexPath) as! SetMuteCell
        let key = ItemType(rawValue: indexPath.section)!

        let item = items[key]![indexPath.row]
        
        cell.titleLabel.text = item.text
        
        if key == .input {
            cell.inputTextField.isHidden = false
            cell.unitLabel.isHidden = false
            cell.onTextChanged = { [weak self] text in
                self?.seconds = text * 24 * 3600
            }
        } else {
            cell.inputTextField.isHidden = true
            cell.unitLabel.isHidden = true
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let key = ItemType(rawValue: indexPath.section)!
        
        if key == .input {
            return
        }
        
        if let preSelectedIndexPath {
            let preCell = tableView.cellForRow(at: preSelectedIndexPath)
            preCell?.accessoryType = .none
        }
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        
        preSelectedIndexPath = indexPath
        
        seconds = items[key]![indexPath.row].seconds
    }
}

fileprivate class SetMuteCell: UITableViewCell {
    
    var onTextChanged: ((Int) -> Void)?
    
    private let disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let v = UILabel()
        v.textColor = .c0C1C33
        v.font = .f17
        
        return v
    }()
    
    lazy var inputTextField: UITextField = {
        let v = UITextField()
        v.font = .f17
        v.textColor = .c0C1C33
        v.borderStyle = .none
        v.backgroundColor = .clear
        v.keyboardType = .numberPad
        v.isHidden = true
        v.textAlignment = .right
        
        v.rx.text.orEmpty.changed.subscribe(onNext: { [weak self] _ in
            if let text = v.text, let value = Int(text) {
                self?.onTextChanged?(value)
            }
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    let unitLabel: UILabel = {
        let v = UILabel()
        v.text = "天".innerLocalized()
        v.textColor = .c0C1C33
        v.font = .f17
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        return v
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        let hStack = UIStackView(arrangedSubviews: [titleLabel, inputTextField, unitLabel])
        hStack.spacing = 4
        
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
        
        inputTextField.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
    }
}
