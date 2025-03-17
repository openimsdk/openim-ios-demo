
import OUICore
import RxSwift

public class GroupFriendsListViewController: UIViewController {
    
    public var selectFriendCallBack: ((UserInfo) -> Void)?
    public var selectGroupCallBack: ((GroupInfo) -> Void)?
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        bindData()
        _viewModel.getMyGroups()
        _viewModel.getFriends()
    }
    
    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: StandardUI.margin_22)
        v.separatorColor = .sepratorColor
        v.rowHeight = UITableView.automaticDimension
        v.delegate = self
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()
    
    private let iGroupBtn: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("myGroup".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.titleLabel?.font = .f14
        v.isSelected = true
        v.underLineWidth = 30
        return v
    }()
    
    private let iFriendsBtn: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("myFriend".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.titleLabel?.font = .f14
        v.underLineWidth = 30
        return v
    }()
    
    private func initView() {
        
        let btnStackView: UIStackView = {
            let v = UIStackView(arrangedSubviews: [iGroupBtn, iFriendsBtn])
            v.frame = CGRect(origin: .zero, size: CGSize(width: kScreenWidth, height: 44))
            v.axis = .horizontal
            v.distribution = .fillEqually
            return v
        }()
        
        tableView.tableHeaderView = btnStackView
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private let _viewModel = GroupFriendsListViewModel()
    private let _disposeBag = DisposeBag()
    private func bindData() {
        
        iGroupBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?._viewModel.isMyGroupTableSelected.accept(true)
        }).disposed(by: _disposeBag)
        
        iFriendsBtn.rx.tap.subscribe(onNext: { [weak self] in
            self?._viewModel.isMyGroupTableSelected.accept(false)
        }).disposed(by: _disposeBag)
        
        _viewModel.isMyGroupTableSelected
            .bind(to: iGroupBtn.rx.isSelected)
            .disposed(by: _disposeBag)
        
        _viewModel.isMyGroupTableSelected
            .map { !$0 }
            .bind(to: iFriendsBtn.rx.isSelected)
            .disposed(by: _disposeBag)
        
        _viewModel.items.bind(to: tableView.rx.items(cellIdentifier: FriendListUserTableViewCell.className, cellType: FriendListUserTableViewCell.self)) { _, model, cell in
            
            if model is GroupInfo, let m = model as? GroupInfo {
                cell.titleLabel.text = m.groupName
                cell.subtitleLabel.text = "\(m.memberCount)人"
                cell.avatarImageView.setAvatar(url: m.faceURL, text: m.groupName, onTap: nil)
            } else if model is UserInfo, let m = model as? UserInfo {
                cell.titleLabel.text = m.nickname
                cell.avatarImageView.setAvatar(url: m.faceURL, text: m.nickname, onTap: nil)
            }
        }.disposed(by: _disposeBag)
        
        _viewModel.myGroupsRelay
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] groups in
            }).disposed(by: _disposeBag)
        
        _viewModel.myFriendsRelay
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] friends in
            }).disposed(by: _disposeBag)
    }
}

extension GroupFriendsListViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = _viewModel.items.value[indexPath.row]
        
        if model is GroupInfo {
            selectGroupCallBack?(model as! GroupInfo)
        } else if model is UserInfo {
            selectFriendCallBack?(model as! UserInfo)
        }
    }
}
