
import RxSwift
import ProgressHUD
import OUICore
import OUICoreView
import Photos

class GroupChatSettingTableViewController: UITableViewController {
    
    init(conversation: ConversationInfo, groupInfo: GroupInfo? = nil, groupMembers: [GroupMemberInfo]? = nil, style: UITableView.Style) {
        _viewModel = GroupChatSettingViewModel(conversation: conversation, groupInfo: groupInfo, groupMembers: groupMembers)
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let _viewModel: GroupChatSettingViewModel
    private let _disposeBag = DisposeBag()
    private let selectMaxCount = 200
    private var sectionItems: [[RowType]]!
    
    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickAvatar()
        v.didPhotoSelected = { [weak self] (images: [UIImage], _: [PHAsset]) in
            guard var first = images.first else { return }
            ProgressHUD.animate()
            first = first.compress(expectSize: 20 * 1024)
            let result = FileHelper.shared.saveImage(image: first)
            
            if result.isSuccess {
                self?._viewModel.uploadFile(fullPath: result.fullPath, onProgress: { progress in
                    ProgressHUD.progress(progress)
                }, onComplete: {
                    ProgressHUD.success()
                })
            } else {
                ProgressHUD.dismiss()
            }
        }
        
        v.didCameraFinished = { [weak self] (photo: UIImage?, _: URL?) in
            guard let sself = self else { return }
            if var photo {
                photo = photo.compress(expectSize: 20 * 1024)
                let result = FileHelper.shared.saveImage(image: photo)
                if result.isSuccess {
                    self?._viewModel.uploadFile(fullPath: result.fullPath, onProgress: { progress in
                        ProgressHUD.progress(progress)
                    }, onComplete: {
                        ProgressHUD.success()
                    })
                }
            }
        }
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "groupChatSetup".innerLocalized()
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        configureTableView()
        initView()
        bindData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _viewModel.getConversationInfo()
    }
    
    private var defaultSectionItems: [[RowType]] {
        [
            [.header],
            [.members],
            [.quitGroup],
        ]
    }
    
    private var notInGroupSectionItems: [[RowType]] {
        [
            [.quitGroup],
        ]
    }
    
    private func configureTableView() {
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = .zero
        tableView.register(GroupBasicInfoCell.self, forCellReuseIdentifier: GroupBasicInfoCell.className)
        tableView.register(GroupChatMemberTableViewCell.self, forCellReuseIdentifier: GroupChatMemberTableViewCell.className)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: SwitchTableViewCell.className)
        tableView.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        tableView.register(OptionImageTableViewCell.self, forCellReuseIdentifier: OptionImageTableViewCell.className)
        tableView.register(QuitTableViewCell.self, forCellReuseIdentifier: QuitTableViewCell.className)
    }
    
    private func initView() {}
    
    private func bindData() {
        sectionItems = defaultSectionItems
        
        _viewModel.isInGroupRelay.subscribe(onNext: { [weak self] isIn in
            guard let self else { return }
            
            sectionItems = isIn ? sectionItems : notInGroupSectionItems
            
            tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.groupInfoRelay.subscribe(onNext: { [weak self] (groupInfo: GroupInfo?) in
            guard let self else { return }
            tableView.reloadData()
        }).disposed(by: _disposeBag)
        
        _viewModel.myInfoInGroup.subscribe(onNext: { [weak self] (memberInfo: GroupMemberInfo?) in
            guard let self else { return }
                        
            if let info = memberInfo {
                if info.roleLevel == .owner {
                    sectionItems[1] = [.manage]
                }
                
                tableView.reloadData()
            }
        }).disposed(by: _disposeBag)
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        
        if rowType == .members || rowType == .header {
            return UITableView.automaticDimension
        }
        
        return 60
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
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupBasicInfoCell.className, for: indexPath) as! GroupBasicInfoCell
            let groupInfo = _viewModel.groupInfoRelay.value
            let isAdmin = _viewModel.myInfoInGroup.value?.isOwnerOrAdmin == true
            
            cell.avatarView.setAvatar(url: groupInfo?.faceURL, text: groupInfo?.groupName, showEdit: isAdmin, onTap: { [weak self] in
                guard let self, isAdmin else { return }
                
                presentSelectedPictureActionSheet { [weak self] in
                    guard let self else { return }
                    
                    _photoHelper.presentPhotoLibrary(byController: self)
                } cameraHandler: { [weak self] in
                    guard let self else { return }
                    
                    _photoHelper.presentCamera(byController: self)
                }
            })
            
            let count = groupInfo?.memberCount ?? 0
            cell.titleLabel.text = groupInfo?.groupName?.append(string: "(\(count))")
            cell.subLabel.text = groupInfo?.groupID
            cell.enableInput = isAdmin

            cell.inputHandler = { [weak self] in
                
                let vc = ModifyNicknameViewController()
                vc.titleLabel.text = "edit_group_name".innerLocalized()
                vc.subtitleLabel.text = "edit_group_tips".innerLocalized()
                vc.avatarView.setAvatar(url: self?._viewModel.groupInfoRelay.value?.faceURL, text: self?._viewModel.groupInfoRelay.value?.groupName)
                vc.nameTextField.text = self?._viewModel.groupInfoRelay.value?.groupName
                vc.completeBtn.rx.tap.subscribe(onNext: { [weak self, weak vc] in
                    guard let text = vc?.nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
                    ProgressHUD.animate()
                    self?._viewModel.updateGroupName(text, onSuccess: { _ in
                        ProgressHUD.success()
                        vc?.navigationController?.popViewController(animated: true)
                    })
                }).disposed(by: vc.disposeBag)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
            
            return cell
        case .members:
            let cell = tableView.dequeueReusableCell(withIdentifier: GroupChatMemberTableViewCell.className) as! GroupChatMemberTableViewCell
            cell.memberCollectionView.dataSource = nil
            _viewModel.membersRelay.asDriver(onErrorJustReturn: []).drive(cell.memberCollectionView.rx.items) { (collectionView: UICollectionView, row, item: GroupMemberInfo) in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupChatMemberTableViewCell.ImageCollectionViewCell.className, for: IndexPath(row: row, section: 0)) as! GroupChatMemberTableViewCell.ImageCollectionViewCell
                if item.isAddButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_add_btn_icon")
                } else if item.isRemoveButton {
                    cell.avatarView.setAvatar(url: nil, text: nil, placeHolder: "setting_remove_btn_icon")
                } else {
                    cell.avatarView.setAvatar(url: item.faceURL, text: item.nickname)
                    cell.levelLabel.text = item.roleLevelString
                }
                
                cell.nameLabel.text = item.nickname
                
                return cell
            }.disposed(by: cell.disposeBag)
            
            cell.reloadData()
            
            _viewModel.membersCountRelay.map { "（\($0)）" }.bind(to: cell.countLabel.rx.text).disposed(by: cell.disposeBag)
            cell.titleLabel.text = rowType.title
            
            cell.memberCollectionView.rx.modelSelected(GroupMemberInfo.self).subscribe(onNext: { [weak self, weak cell] (userInfo: GroupMemberInfo) in
                guard let self else { return }
                
                if userInfo.isAddButton || userInfo.isRemoveButton {
                    if userInfo.isAddButton {
#if ENABLE_ORGANIZATION
                        let vc = MyContactsViewController(types: [.friends, .staff], multipleSelected: true, selectMaxCount: selectMaxCount)
#else
                        let vc = MyContactsViewController(types: [.friends], multipleSelected: true, selectMaxCount: selectMaxCount)
#endif
                        let blocked = _viewModel.allMembers + [IMController.shared.uid]

                        vc.selectedContact(blocked: blocked) { [self] (r: [ContactInfo]) in
                            
                            ProgressHUD.animate()
                            self._viewModel.inviteUsersToGroup(uids: r.compactMap({ $0.ID })) { [weak cell, weak vc, self] in
                                ProgressHUD.success("invitationSuccessful".innerLocalized())
                                cell?.reloadData()
                                
                                self.navigationController?.popToViewController(self, animated: true)
                            } onFailure: { errCode, errMsg in
                                ProgressHUD.error(errMsg)
                            }
                        }
                        
                        navigationController?.pushViewController(vc, animated: true)

                        return
                    }

                    let vc = SelectContactsViewController(types: [.members], sourceID: _viewModel.groupInfoRelay.value?.groupID)

                    vc.title = "removeGroupMember".innerLocalized()
                    
                    let blocked = _viewModel.myInfoInGroup.value?.roleLevel == .owner ? nil : _viewModel.superAndAdmins
                    
                    vc.selectedContact(hasSelected: [],
                                       blocked: blocked?.compactMap({ $0.userID })) { [weak vc, self] (tapBack, r: [ContactInfo]) in
                        if r.isEmpty || tapBack {
                            self.navigationController?.popToViewController(self, animated: true)
                            return
                        }
                        guard let groupID = self._viewModel.groupInfoRelay.value?.groupID else { return }
                        
                        ProgressHUD.animate()
                        let uids = r.compactMap { $0.ID }
               
                        self._viewModel.kickGroupMember(uids: uids) { [weak cell, self] in
                            ProgressHUD.dismiss()
                            cell?.reloadData()
                            self.navigationController?.popToViewController(self, animated: true)
                        }
                        
                    }
                    navigationController?.pushViewController(vc, animated: true)
                } else {
                    if _viewModel.groupInfoRelay.value?.lookMemberInfo == 0 {
                        let vc = UserDetailTableViewController(userId: userInfo.userID!, groupId: _viewModel.conversation.groupID, groupInfo: _viewModel.groupInfoRelay.value!, groupMemberInfo: userInfo, userInfo: userInfo.toSimplePublicUserInfo())
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            }).disposed(by: cell.disposeBag)
            
            return cell
        case .manage:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            cell.titleLabel.text = rowType.title
            return cell
        case .quitGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            cell.titleLabel.textColor = .cFF381F
            _viewModel.isInGroupRelay.map({ [weak self] isIn -> String in
                if isIn {
                    return self?._viewModel.myInfoInGroup.value?.roleLevel == .owner ? "dismissGroup".innerLocalized() : "exitGroup".innerLocalized()
                } else {
                    return "delete".innerLocalized()
                }
            }).bind(to: cell.titleLabel.rx.text).disposed(by: cell.disposeBag)
                
            return cell
        }
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = sectionItems[indexPath.section][indexPath.row]
        switch rowType {
        case .members:
            let vc = MemberListViewController(viewModel: MemberListViewModel(groupInfo: _viewModel.groupInfoRelay.value!))
            navigationController?.pushViewController(vc, animated: true)
        case .manage:
            let vc = GroupSettingManageTableViewController(groupInfo: _viewModel.groupInfoRelay.value!)
            navigationController?.pushViewController(vc, animated: true)
        case .quitGroup:
            if !_viewModel.isInGroupRelay.value {
                ProgressHUD.animate()
                
                _viewModel.removeConversation { [weak self] r in
                    if r {
                        ProgressHUD.animate()
                        self?.navigationController?.popToRootViewController(animated: true)
                    } else {
                        ProgressHUD.error("networkError".innerLocalized())
                    }
                }
                return
            }
            if let role = _viewModel.myInfoInGroup.value?.roleLevel, role == .owner {
                presentAlert(title: "dismissGroupHint".innerLocalized()) { [weak self] in
                    guard let self else { return }
                    
                    _viewModel.dismissGroup(onSuccess: { [self] in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            } else {
                presentAlert(title: "quitGroupHint".innerLocalized()) { [weak self] in
                    guard let self else { return }
                    
                    _viewModel.quitGroup(onSuccess: { [self] in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            }
        default:
            break
        }
    }
    
    enum RowType {
        case header
        case members
        case manage
        case quitGroup
        
        var title: String {
            switch self {
            case .header:
                return ""
            case .members:
                return "viewAllGroupMembers".innerLocalized()
            case .manage:
                return "groupManage".innerLocalized()
            case .quitGroup:
                return "exitGroup".innerLocalized()
            }
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}
