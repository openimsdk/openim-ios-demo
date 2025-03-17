
import RxSwift
import OUICore
import OUICoreView
import ProgressHUD

open class FriendListViewController: UIViewController {
    var selectCallBack: ((UserInfo) -> Void)?
    private lazy var _tableView: UITableView = {
        let v = UITableView()
        let config = SCIndexViewConfiguration(indexViewStyle: SCIndexViewStyle.default)!
        config.indexItemRightMargin = 8
        config.indexItemTextColor = UIColor(hexString: "#555555")
        config.indexItemSelectedBackgroundColor = UIColor(hexString: "#57be6a")
        config.indexItemsSpace = 4
        v.sc_indexViewConfiguration = config
        v.sc_translucentForTableViewInNavigationBar = true
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = 60
        v.backgroundColor = .clear
        v.separatorColor = .clear

        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    private let _viewModel = FriendListViewModel()
    private let _disposeBag = DisposeBag()

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "myFriend".innerLocalized()
        view.backgroundColor = .viewBackgroundColor
        
        initView()
        bindData()
        _viewModel.getMyFriendList()
    }

    private func initView() {
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindData() {
        _viewModel.loadingSubject.subscribe(onNext: { loading in
            if loading {
                ProgressHUD.animate()
            } else {
                ProgressHUD.dismiss()
            }
        }).disposed(by: _disposeBag)
        
        _viewModel.lettersRelay.distinctUntilChanged().subscribe(onNext: { [weak self] (values: [String]) in
            guard let sself = self else { return }
            self?._tableView.sc_indexViewDataSource = values
            self?._tableView.sc_startSection = 0
            self?._tableView.reloadData()
        }).disposed(by: _disposeBag)
    }

    deinit {
        print("dealloc \(type(of: self))")
    }
}

extension FriendListViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in _: UITableView) -> Int {
        return _viewModel.lettersRelay.value.count
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _viewModel.contactSections[section].count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FriendListUserTableViewCell.className) as! FriendListUserTableViewCell
        let user: UserInfo = _viewModel.contactSections[indexPath.section][indexPath.row]
        cell.titleLabel.text = user.remark?.isEmpty == false ? user.remark : user.nickname
        cell.avatarImageView.setAvatar(url: user.faceURL, text: user.nickname, onTap: nil)
        return cell
    }

    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user: UserInfo = _viewModel.contactSections[indexPath.section][indexPath.row]
        if let callBack = selectCallBack {
            callBack(user)
            return
        }
        let vc = UserDetailTableViewController(userId: user.userID, groupId: nil, userDetailFor: .card)
        navigationController?.pushViewController(vc, animated: true)
    }

    public func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let name = _viewModel.lettersRelay.value[section]
        let header = ViewUtil.createSectionHeaderWith(text: name)
        return header
    }

    public func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 33
    }

    public func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
