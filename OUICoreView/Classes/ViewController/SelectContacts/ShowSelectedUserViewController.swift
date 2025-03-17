import OUICore
import SnapKit
import RxSwift

public class ShowSelectedUserViewController: UIViewController {
    private let _disposeBag = DisposeBag()
    public var removeUsersCallback: (([ContactInfo]) -> Void)!
    
    var users: [ContactInfo]!
    var removeUsers: [ContactInfo] = []
    
    public init(users: [ContactInfo], removeCallback: @escaping ([ContactInfo]) -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.users = users
        self.removeUsersCallback = removeCallback
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(ShowSelectedTableViewCell.self, forCellReuseIdentifier: ShowSelectedTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = UITableView.automaticDimension
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.allowsMultipleSelection = true
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        
        return v
    }()
    
    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.text = "已选择：".innerLocalized()
        
        return v
    }()
    
    private lazy var sureButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("确认".innerLocalized(), for: .normal)
        v.setTitleColor(.systemBlue, for: .normal)
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.toSure()
        }).disposed(by: _disposeBag)
        
        return v
    }()
    
    var selectedCount = 0 {
        didSet {
            titleLabel.text = "已选择：".innerLocalized() + String(selectedCount)
        }
    }
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        selectedCount = users.count
        
        let horSV = UIStackView(arrangedSubviews: [SizeBox(width: 16), titleLabel, sureButton, SizeBox(width: 16)])
        
        let line = UIView()
        line.backgroundColor = .cE8EAEF
        
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        
        let verSV = UIStackView(arrangedSubviews: [SizeBox(height: 8), horSV, line, _tableView])
        verSV.axis = .vertical
        verSV.spacing = 8
        view.addSubview(verSV)
        
        verSV.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func toSure() {
        removeUsersCallback(removeUsers)
        dismiss(animated: true)
    }
}

extension ShowSelectedUserViewController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ShowSelectedTableViewCell.className, for: indexPath) as! ShowSelectedTableViewCell
        
        let user = users[indexPath.row]

        cell.titleLabel.text = user.name
        cell.avatarView.setAvatar(url: user.faceURL, text: user.name)
        cell.onTap = { [weak self] in
            self?.removeUsers.append(user)
            self?.users.removeAll(where: {$0.ID == user.ID})
            self?._tableView.reloadData()
            self?.selectedCount = self?.users.count ?? 0
        }
        
        return cell
    }
}

