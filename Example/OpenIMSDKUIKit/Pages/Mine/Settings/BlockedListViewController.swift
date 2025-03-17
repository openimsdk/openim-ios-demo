
import RxSwift
import OUICore
import OUICoreView

open class BlockedListViewController: UIViewController {

    private lazy var _tableView: UITableView = {
        let v = UITableView()
        v.register(FriendListUserTableViewCell.self, forCellReuseIdentifier: FriendListUserTableViewCell.className)
        v.delegate = self
        v.rowHeight = UITableView.automaticDimension
        v.backgroundColor = .viewBackgroundColor
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()
    
    private let emptyImageView = UIImageView(image: UIImage(named: "mine_blocked_list_empty"))
    
    private let emptyLabel: UILabel = {
        let v = UILabel()
        v.text = "暂无黑名单".localized()
        v.font = .f17
        v.textColor = .c8E9AB0
        v.textAlignment = .center
        
        return v
    }()
    private let _viewModel = SettingViewModel()
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
        navigationItem.title = "blacklist".innerLocalized()
        view.backgroundColor = .viewBackgroundColor
        
        initView()
        bindData()
        _viewModel.getBlockedList()
    }

    private func initView() {

        let vStack = UIStackView(arrangedSubviews: [emptyImageView, emptyLabel])
        vStack.axis = .vertical
        vStack.spacing = 8
        
        view.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        view.addSubview(_tableView)
        _tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func bindData() {
        _viewModel.blockedList.subscribe(onNext: { [weak self] infos in
            self?._tableView.isHidden = infos.isEmpty
        }).disposed(by: _disposeBag)
        
        _viewModel.blockedList.asDriver(onErrorJustReturn: []).drive(_tableView.rx.items) { tableView, _, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendListUserTableViewCell.className) as! FriendListUserTableViewCell
            cell.titleLabel.text = item.nickname
            cell.avatarImageView.setAvatar(url: item.faceURL, text: item.nickname, onTap: nil)
            return cell
        }.disposed(by: _disposeBag)









    }
    
    deinit {
        print("dealloc \(type(of: self))")
    }
}

extension BlockedListViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return .init(actions: [.init(style: .destructive, title: "移除黑名单".localized(), handler: {[weak self] (action, view, complete) in
            let user: BlackInfo = (self?._viewModel.blockedList.value[indexPath.row])!
            self?._viewModel.removeFromBlockedList(uid: user.userID!) { r in
                complete(true)
            }
        })])
    }

    public func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
