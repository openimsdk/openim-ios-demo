
import OUICore
import OUICoreView
import RxSwift
import ProgressHUD

class NewFriendListViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "newFriend".innerLocalized()
        view.backgroundColor = .systemGroupedBackground
        
        initView()
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _viewModel.getNewFriendApplications()
    }

    private lazy var tableView: UITableView = {
        let v = UITableView()
        v.register(NewFriendTableViewCell.self, forCellReuseIdentifier: NewFriendTableViewCell.className)
        v.rowHeight = 68.h
        v.tableFooterView = UIView()
        v.backgroundColor = .clear
        v.separatorColor = .cE8EAEF

        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()

    private func initView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.bottom.trailing.equalToSuperview()
        }
    }

    private func bindData() {
        _viewModel.loading.asDriver().drive(onNext: { isLoading in
            if isLoading {
                ProgressHUD.animate()
            } else {
                ProgressHUD.dismiss()
            }
        }).disposed(by: _disposeBag)
        
        _viewModel.applications.asDriver(onErrorJustReturn: []).drive(tableView.rx.items) { [weak self] tableView, _, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: NewFriendTableViewCell.className) as! NewFriendTableViewCell
            
            guard let self else { return cell }
            
            cell.titleLabel.text = item.fromNickname
            cell.subtitleLabel.text = item.reqMsg ?? ""
            if let state = NewFriendTableViewCell.ApplyState(rawValue: item.handleResult.rawValue) {
                cell.setApplyState(state, isSendOut: _viewModel.isSendOut(userID: item.fromUserID))
            }

            cell.avatarView.setAvatar(url: item.fromFaceURL, text: item.fromNickname)

            cell.agreeBtn.rx.tap.subscribe { [weak self] _ in

                let vc = ApplicationViewController(friendApplication: item)
                self?.navigationController?.pushViewController(vc, animated: true)
            }.disposed(by: cell.disposeBag)

            return cell
        }.disposed(by: _disposeBag)

        tableView.rx.modelSelected(FriendApplication.self).subscribe(onNext: { [weak self] (application: FriendApplication) in




        }).disposed(by: _disposeBag)
    }

    private let _viewModel = NewFriendListViewModel()
    private let _disposeBag = DisposeBag()
}
