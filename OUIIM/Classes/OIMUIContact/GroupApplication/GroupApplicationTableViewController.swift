
import RxSwift
import OUICore
import ProgressHUD

class GroupApplicationTableViewController: UITableViewController {
    private let _viewModel = GroupApplicationViewModel()
    private let _disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "newGroup".innerLocalized()
        tableView.register(GroupApplicationTableViewCell.self, forCellReuseIdentifier: GroupApplicationTableViewCell.className)
        tableView.dataSource = nil
        tableView.backgroundColor = .viewBackgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorColor = .cE8EAEF
        
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _viewModel.getGroupApplications()
    }

    private func bindData() {
        _viewModel.loading.asDriver().drive(onNext: { isLoading in
            if isLoading {
                ProgressHUD.animate()
            } else {
                ProgressHUD.dismiss()
            }
        }).disposed(by: _disposeBag)
        
        _viewModel.applicationItems
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items) { [weak self] (tableView, _, item: GroupApplicationInfo) in
                let cell = tableView.dequeueReusableCell(withIdentifier: GroupApplicationTableViewCell.className) as! GroupApplicationTableViewCell
                
                guard let self else { return cell }
                
                cell.nameLabel.text = item.nickname
                if let reason = item.reqMsg {
                    cell.setApply(reason: reason)
                }
                if let groupName = item.groupName {
                    cell.setCompanyName(groupName)
                }

                if let state = GroupApplicationTableViewCell.ApplyState(rawValue: item.handleResult.rawValue) {
                    cell.setApplyState(state, isSendOut: _viewModel.isSendOut(userID: item.userID!))
                }
                cell.avatarView.setAvatar(url: item.userFaceURL, text: item.nickname)
                cell.agreeBtn.rx.tap.subscribe { [weak self] _ in
                    if let uid = item.userID {
                        let vc = ApplicationViewController(groupApplication: item, friendApplication: nil)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                }.disposed(by: cell.disposeBag)
                return cell
            }.disposed(by: _disposeBag)
    }
}
