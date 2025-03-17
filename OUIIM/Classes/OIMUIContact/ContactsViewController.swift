
import RxSwift
import ProgressHUD
import OUICore
import Localize_Swift
#if ENABLE_ORGANIZATION
import OUIOrganization
#endif

#if ENABLE_MOMENTS
import OUIMoments
#endif

public class ContactsViewController: UITableViewController {
    public lazy var viewModel = ContactsViewModel()
    private let _disposeBag = DisposeBag()

    private lazy var newFriendCell: ContactsEntranceTableViewCell = {
        let v = getEntranceCell()
        let value = EntranceCellType.newFriend
        v.avatarImageView.image = value.iconImage
        v.titleLabel.text = value.title
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            ApplicationStorage.lastFriendApplicationReadTime = ApplicationStorage.lastFriendApplicationTime
            
            let vc = NewFriendListViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)
        v.addGestureRecognizer(tap)
        return v
    }()

    private lazy var groupNotiCell: ContactsEntranceTableViewCell = {
        let v = getEntranceCell()
        let value = EntranceCellType.groupNotification
        v.avatarImageView.image = value.iconImage
        v.titleLabel.text = value.title
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            ApplicationStorage.lastGroupApplicationReadTime = ApplicationStorage.lastGroupApplicationTime

            let vc = GroupApplicationTableViewController()
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: _disposeBag)
        v.addGestureRecognizer(tap)
        return v
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        initView()
        bindData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(setText), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
    }
    
    @objc
    private func setText() {
        initView()
        newFriendCell.titleLabel.text = EntranceCellType.newFriend.title
        groupNotiCell.titleLabel.text = EntranceCellType.groupNotification.title
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.getFriendApplications()
        viewModel.getGroupApplications()
        viewModel.queryMyDepartmentInfo()
        viewModel.getFrequentUsers()
    }

    private func initView() {
        let titleLabel: UILabel = {
            let v = UILabel()
            v.font = .f20
            v.textColor = .c0C1C33
            v.text = "contacts".innerLocalized()
            return v
        }()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)

        let addItem: UIBarButtonItem = {
            let v = UIBarButtonItem()
            v.image = UIImage(nameInBundle: "contact_add_icon")
            v.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
            v.rx.tap.subscribe(onNext: { [weak self] in
                let vc = AddTableViewController()
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: _disposeBag)
            return v
        }()
        
        navigationItem.rightBarButtonItems = [addItem]

        let vStack: UIStackView = {
            let rowHeight = 60.h
            let myFriendCell: ContactsEntranceTableViewCell = {
                let v = getEntranceCell()
                let value = EntranceCellType.myFriend
                v.avatarImageView.image = value.iconImage
                v.titleLabel.text = value.title
                v.badgeLabel.isHidden = true
                let tap = UITapGestureRecognizer()
                tap.rx.event.subscribe(onNext: { [weak self] _ in
                    let vc = FriendListViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }).disposed(by: _disposeBag)
                v.addGestureRecognizer(tap)
                return v
            }()
            let myGroupCell: ContactsEntranceTableViewCell = {
                let v = getEntranceCell()
                let value = EntranceCellType.myGroup
                v.avatarImageView.image = value.iconImage
                v.titleLabel.text = value.title
                v.badgeLabel.isHidden = true
                let tap = UITapGestureRecognizer()
                tap.rx.event.subscribe(onNext: { [weak self] _ in
                    let vc = GroupListViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }).disposed(by: _disposeBag)
                v.addGestureRecognizer(tap)
                return v
            }()
            
            let spacer = UIView()
            spacer.backgroundColor = .clear
            
            newFriendCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            groupNotiCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            myFriendCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            myGroupCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            spacer.snp.makeConstraints { make in
                make.height.equalTo(16)
            }
            
            var arrangedViews = [newFriendCell, groupNotiCell, spacer, myFriendCell, myGroupCell]
            var v = UIStackView(arrangedSubviews: arrangedViews)
            v.axis = .vertical
            v.bounds = CGRect(x: 0, y: 0, width: kScreenWidth, height: rowHeight * 4.0 + 16)
            
#if ENABLE_MOMENTS
            let momentsCell: ContactsEntranceTableViewCell = {
                let v = getEntranceCell()
                let value = EntranceCellType.moments
                v.avatarImageView.image = value.iconImage
                v.titleLabel.text = value.title
                v.badgeLabel.isHidden = true
                let tap = UITapGestureRecognizer()
                tap.rx.event.subscribe(onNext: { [weak self] _ in
                    let vc = MomentsViewController()
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }).disposed(by: _disposeBag)
                v.addGestureRecognizer(tap)
                return v
            }()
            
            let spacer2 = UIView()
            spacer2.backgroundColor = .clear
            
            arrangedViews = [newFriendCell, groupNotiCell, spacer, myFriendCell, myGroupCell, spacer2, momentsCell]
            v = UIStackView(arrangedSubviews: arrangedViews)
            v.axis = .vertical
            v.bounds = CGRect(x: 0, y: 0, width: kScreenWidth, height: rowHeight * 5.0 + 2 * 16)
            
            momentsCell.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            spacer2.snp.makeConstraints { make in
                make.height.equalTo(16)
            }
#endif
            
            return v
        }()

        tableView.tableHeaderView = vStack
    }

    private func bindData() {
        viewModel.newFriendCountRelay.map { $0 == 0 }.bind(to: newFriendCell.badgeLabel.rx.isHidden).disposed(by: _disposeBag)
        viewModel.newGroupCountRelay.map { $0 == 0 }.bind(to: groupNotiCell.badgeLabel.rx.isHidden).disposed(by: _disposeBag)
        viewModel.newFriendCountRelay.map { "\($0)" }.bind(to: newFriendCell.badgeLabel.rx.text).disposed(by: _disposeBag)
        viewModel.newGroupCountRelay.map { "\($0)" }.bind(to: groupNotiCell.badgeLabel.rx.text).disposed(by: _disposeBag)
        viewModel.frequentContacts.asDriver().drive { [weak self] _ in
            self?.tableView.reloadData()
        }.disposed(by: _disposeBag)
        viewModel.companyDepartments.asDriver().drive { [weak self] _ in
            self?.tableView.reloadData()
        }.disposed(by: _disposeBag)
        viewModel.getFriendApplications()
        viewModel.getGroupApplications()
    }

    override public func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {





        return nil
    }

    override public func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == SectionName.company.rawValue {
            return 16
        }



        return CGFloat.leastNormalMagnitude
    }

    override public func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override open func numberOfSections(in _: UITableView) -> Int {
        return SectionName.allCases.count
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SectionName.company.rawValue {
            return viewModel.companyDepartments.value.count
        }



        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SectionName.company.rawValue {
            let item = viewModel.companyDepartments.value[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactsEntranceTableViewCell.className) as! ContactsEntranceTableViewCell
            cell.badgeLabel.isHidden = true
            cell.avatarImageView.image = item.isHost ? UIImage(nameInBundle: "contact_my_group_icon") : UIImage(nameInBundle: "contacts_group_icon")
            cell.arrowImageView.isHidden = item.isHost
            cell.titleLabel.text = item.name
            return cell
        }







        return UITableViewCell()
    }

    override open func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SectionName.company.rawValue {
            #if ENABLE_ORGANIZATION
            let item = viewModel.companyDepartments.value[indexPath.row]
            let vc = DepartmentViewController(allowsMultipleSelection: false, department: item.id, name: item.name!)
            vc.onTap = { [weak self] user in
                let vc = UserDetailTableViewController(userId: user.ID!)
                vc.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            vc.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(vc, animated: true)
            #endif









        }
    }

    private func configureTableView() {
        tableView.backgroundColor = .systemGroupedBackground
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        tableView.register(ContactsEntranceTableViewCell.self, forCellReuseIdentifier: ContactsEntranceTableViewCell.className)
        tableView.register(FrequentUserTableViewCell.self, forCellReuseIdentifier: FrequentUserTableViewCell.className)
    }

    private func getEntranceCell() -> ContactsEntranceTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactsEntranceTableViewCell.className) as! ContactsEntranceTableViewCell
        return cell
    }

    enum SectionName: Int, CaseIterable {
        case company = 0

    }

    enum EntranceCellType: CaseIterable {
        case newFriend
        case groupNotification
        case myFriend
        case myGroup
        
        var iconImage: UIImage? {
            switch self {
            case .newFriend:
                return UIImage(nameInBundle: "contact_new_friend_icon")
            case .groupNotification:
                return UIImage(nameInBundle: "contact_new_group_icon")
            case .myFriend:
                return UIImage(nameInBundle: "contact_my_friend_icon")
            case .myGroup:
                return UIImage(nameInBundle: "contact_my_group_icon")
            }
        }

        var title: String {
            switch self {
            case .newFriend:
                return "newFriend".innerLocalized()
            case .groupNotification:
                return "newGroupRequest".innerLocalized()
            case .myFriend:
                return "myFriend".innerLocalized()
            case .myGroup:
                return "myGroup".innerLocalized()
            }
        }
    }
}
