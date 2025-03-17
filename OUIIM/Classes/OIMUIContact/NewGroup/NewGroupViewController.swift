
import OUICore
import OUICoreView
import RxSwift
import RxCocoa
import RxRelay
import ProgressHUD
import Photos

class NewGroupViewController: UITableViewController {
    private let _viewModel: NewGroupViewModel
    private let _disposeBag = DisposeBag()
    
    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickAvatar()
        v.didPhotoSelected = { [weak self] (images: [UIImage], _: [PHAsset]) in
            guard var first = images.first else { return }
            ProgressHUD.animate()
            first = first.compress(expectSize: 20 * 1024)
            let result = FileHelper.shared.saveImage(image: first)
            
            if result.isSuccess {
                self?._viewModel.uploadFile(fullPath: result.fullPath, onComplete: { [weak self] url in
                    self?._viewModel.groupAvatar = url
                    self?.tableView.reloadData()
                    ProgressHUD.dismiss()
                })
            } else {
                ProgressHUD.dismiss()
            }
        }
        
        v.didCameraFinished = { [weak self] (photo: UIImage?, _: URL?) in
            guard let sself = self else { return }
            if var photo {
                ProgressHUD.animate()
                photo = photo.compress(expectSize: 20 * 1024)
                let result = FileHelper.shared.saveImage(image: photo)
                if result.isSuccess {
                    self?._viewModel.uploadFile(fullPath: result.fullPath, onComplete: { [weak self] url in
                        self?._viewModel.groupAvatar = url
                        self?.tableView.reloadData()
                        ProgressHUD.dismiss()
                    })
                }
            }
        }
        return v
    }()
    
    let contentView = UIView()
    
    private lazy var createButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("completeCreation".innerLocalized(), for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.isEnabled = false
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 6
        v.setBackgroundColor(.c0089FF, for: .normal)
        v.setBackgroundColor(.c0089FF.withAlphaComponent(0.5), for: .disabled)
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            
            self?.createGroup()
        }).disposed(by: _disposeBag)
        
        return v
    }()
    
    init(users: [UserInfo], groupType: GroupType = .normal, style: UITableView.Style = .insetGrouped) {
        _viewModel = NewGroupViewModel(users: users, groupType: groupType)
        super.init(style: style)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private var sectionItems: [[RowType]] = [
        [.header],
        [.members],
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "创建群聊".innerLocalized()
        navigationController?.navigationBar.isOpaque = false
        configureTableView()
        _viewModel.getMembers()
        
        let tap = UITapGestureRecognizer()
        tap.cancelsTouchesInView = false
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: _disposeBag)
        
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupCreateButton()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        contentView.removeFromSuperview()
    }
    
    private func configureTableView() {
       
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .secondarySystemBackground
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = .zero
        tableView.register(GroupChatNameTableViewCell.self, forCellReuseIdentifier: GroupChatNameTableViewCell.className)
        tableView.register(NewGroupMemberCell.self, forCellReuseIdentifier: NewGroupMemberCell.className)
        tableView.register(QuitTableViewCell.self, forCellReuseIdentifier: QuitTableViewCell.className)
        tableView.tableFooterView = UIView()
    }
    
    private func setupCreateButton() {
        guard let view = navigationController?.view, !view.subviews.contains(contentView) else { return }
        
        contentView.backgroundColor = .cellBackgroundColor
        
        navigationController?.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(UIApplication.safeAreaInsets.bottom + 80.h)
        }
        
        contentView.addSubview(createButton)
        createButton.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44.h)
        }
    }
    
    private func createGroup() {
        ProgressHUD.animate(interaction: false)
        _viewModel.createGroup { [weak self] conversation in
            ProgressHUD.dismiss()
            if let conversation {
                self?.toChat(conversation: conversation)
            } else {
                self?.presentAlert(title: "创建失败".innerLocalized())
            }
        }
    }
    
    private func toChat(conversation: ConversationInfo) {
        
        let chatVC = ChatViewControllerBuilder().build(conversation)
        chatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatVC, animated: true)
        if let root = navigationController?.viewControllers.first {
            navigationController?.viewControllers.removeAll(where: { controller in
                controller != root && controller != chatVC
            })
        }
    }
    
    override func numberOfSections(in _: UITableView) -> Int {
        return sectionItems.count
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .header:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatNameTableViewCell.className) as! GroupChatNameTableViewCell
            cell.avatarImageView.setAvatar(url: _viewModel.groupAvatar, placeHolder: "common_camera_button_icon", onTap: { [weak self] in
                self?.presentSelectedPictureActionSheet(albumHandler: { [self] in
                    guard let self else { return }
                    
                    self._photoHelper.presentPhotoLibrary(byController: self)
                }, cameraHandler: { [self] in
                    
                    guard let self else { return }
                    self._photoHelper.presentCamera(byController: self)
                })
            })

            cell.enableInput = true
            
            cell.nameTextFiled.rx
                .controlEvent([.editingChanged, .editingDidEnd])
                .asObservable().subscribe(onNext: {[weak self, weak cell] t in
                    let text = cell?.nameTextFiled.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                    self?._viewModel.groupName = text
                    
                    self?.createButton.isEnabled = text != nil && !text!.isEmpty
                })
                .disposed(by: _disposeBag)
            return cell
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewGroupMemberCell.className) as! NewGroupMemberCell

            _viewModel.membersRelay.asDriver().drive(cell.memberCollectionView.rx.items(cellIdentifier: NewGroupMemberCell.ImageCollectionViewCell.className, cellType: NewGroupMemberCell.ImageCollectionViewCell.self)) { row, item, cell in
                
                if item.isAddButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_add_btn_icon")
                } else if item.isRemoveButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_remove_btn_icon")
                } else {
                    cell.avatarView.setAvatar(url: item.faceURL, text: item.nickname)
                }
                
                cell.nameLabel.text = item.nickname
                
            }.disposed(by: cell.disposeBag)
            
            cell.reloadData()
            
            _viewModel.membersRelay.map { "\("nPerson".innerLocalizedFormat(arguments: $0.count))" }.bind(to: cell.countLabel.rx.text).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title

            cell.memberCollectionView.rx.modelSelected(UserInfo.self).subscribe(onNext: { [weak self] (userInfo: UserInfo) in
                guard let sself = self else { return }
                if userInfo.isAddButton || userInfo.isRemoveButton {
#if ENABLE_ORGANIZATION
                        let vc = MyContactsViewController(types: [.friends, .staff], multipleSelected: true)
#else
                        let vc = MyContactsViewController(types: [.friends], multipleSelected: true)
#endif
                    var temp = sself._viewModel.membersRelay.value.filter({ !$0.isAddButton && !$0.isRemoveButton})
                    
                    var members = temp.compactMap({ ContactInfo(ID: $0.userID, name: $0.nickname, faceURL: $0.faceURL) })
                    
                        vc.selectedContact(hasSelected: members) { [weak self, weak cell, weak vc] (r: [ContactInfo]) in
                            guard let self else { return }
                            
                            let users = r.map{UserInfo(userID: $0.ID!, nickname: $0.name, faceURL: $0.faceURL)}
                            sself._viewModel.updateMembers(users)

                            vc?.navigationController?.popViewController(animated: true)
                        }
                        
                        self?.navigationController?.pushViewController(vc, animated: true)










                }
            }).disposed(by: cell.disposeBag)
            return cell
        case .create:
            let cell = tableView.dequeueReusableCell(withIdentifier: QuitTableViewCell.className) as! QuitTableViewCell
            cell.titleLabel.text = rowType.title

            return cell
        }
    }
    
    override func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return 12
    }
    
    override func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .members:
            break
        case .create:
            
            guard let groupName = _viewModel.groupName, !groupName.isEmpty else {
                presentAlert(title: "请输入群名".innerLocalized())
                return
            }
            
            ProgressHUD.animate()
            _viewModel.createGroup { [weak self] conversation in
                ProgressHUD.dismiss()
                if let conversation = conversation {
                    self?.toChat(conversation: conversation)
                } else {
                    self?.presentAlert(title: "创建失败".innerLocalized())
                }
            }
            break
        default:
            break
        }
    }
    
    enum RowType {
        case header
        case members
        case create
        
        var title: String {
            switch self {
            case .header:
                return ""
            case .members:
                return "群成员".innerLocalized()
            case .create:
                return "完成创建".innerLocalized()
            }
        }
    }
    
    deinit {
#if DEBUG
        print("\(#function) - \(type(of: self))")
#endif
    }
}
