
import OUICore
import RxSwift
import SnapKit
import ProgressHUD
#if ENABLE_ORGANIZATION
import OUIOrganization
#endif

public typealias SelectedContactsHandler = ((_ pop: Bool, [ContactInfo]) -> Void)

open class SelectContactsViewController: UIViewController {
    
    public var maxCount: Int = 999 {
        didSet {
            bottomBar.maxCount = maxCount
        }
    }
    
    public var allowsSelecteAll: Bool = true {
        didSet {
            selecteAllView.isHidden = !allowsSelecteAll
        }
    }
    
    public var completionHandler: (() -> Void)?

    private var selectedHandler: SelectedContactsHandler?
    private var contacTypes: [ContactType] = []
    private var sourceID: String? 
    private var hasSelectedItems: [ContactInfo] = [] 
    private var blockedIDs: [String] = [] 
    private var allowsMultipleSelection = true
    private var enableChangeSelectedModel = false
    
    public init(types: [ContactType] = [.friends], sourceID: String? = nil, allowsMultipleSelection: Bool = true, enableChangeSelectedModel: Bool = false) {
        super.init(nibName: nil, bundle: nil)
        self.contacTypes = types
        self.sourceID = sourceID
        self.allowsMultipleSelection = allowsMultipleSelection
        self.enableChangeSelectedModel = enableChangeSelectedModel
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
#if ENABLE_ORGANIZATION
        departmentViewController = nil
#endif
        print("SelectContactsViewController deinit")
    }

    public func selectedContact<T>(hasSelected: [T]? = nil, blocked: [String]? = nil, selectedHandler: SelectedContactsHandler?) {
        
        if let temp = hasSelected as? [ContactInfo] {
            self.hasSelectedItems = temp
        } else if let temp = hasSelected as? [String] {
            self.hasSelectedItems = temp.map{ContactInfo(ID: $0)}
        }
        self.blockedIDs = blocked ?? []
        self.selectedHandler = selectedHandler
    }
    
    open lazy var tableView: UITableView = {
        let v = UITableView()
        let config = SCIndexViewConfiguration(indexViewStyle: SCIndexViewStyle.default)!
        config.indexItemRightMargin = 8
        config.indexItemTextColor = UIColor(hexString: "#555555")
        config.indexItemSelectedBackgroundColor = UIColor(hexString: "#57be6a")
        config.indexItemsSpace = 4
        v.sc_indexViewConfiguration = config
        v.sc_translucentForTableViewInNavigationBar = true
        v.register(SelectUserTableViewCell.self, forCellReuseIdentifier: SelectUserTableViewCell.className)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = UITableView.automaticDimension
        v.allowsMultipleSelection = true
        v.backgroundColor = .clear
        
        if #available(iOS 15.0, *) {
            v.sectionHeaderTopPadding = 0
        }
        return v
    }()
    
    private lazy var selecteAllButton: UIButton = {
        let v = UIButton(type: .custom)
        v.setImage(UIImage(nameInBundle: "common_checkbox_unselected"), for: .normal)
        v.setImage(UIImage(nameInBundle: "common_checkbox_selected"), for: .selected)
        v.setTitle(" " + "selectAll".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.contentHorizontalAlignment = .left
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.selecteAll()
        }).disposed(by: _disposeBag)
        
        return v
    }()
    
    private lazy var selecteAllView: UIView = {
        let v = UIView()
        v.backgroundColor = .cellBackgroundColor
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            self?.selecteAll()
        }).disposed(by: _disposeBag)
        v.addGestureRecognizer(tap)
        
        v.addSubview(selecteAllButton)
        selecteAllButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(16)
            make.width.equalTo(100)
        }
        
        return v
    }()

    private let friendsButton: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("myFriend".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.titleLabel?.font = .f14
        v.isSelected = true
        v.underLineWidth = 30
        return v
    }()
    
    private let groupsButton: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("myGroup".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.titleLabel?.font = .f14
        v.underLineWidth = 30
        return v
    }()
    
    private let staffButton: UnderlineButton = {
        let v = UnderlineButton(frame: .zero)
        v.setTitle("organizationStructure".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.titleLabel?.font = .f14
        v.underLineWidth = 30
        return v
    }()
    
    private let _viewModel = SelectContactsViewModel()
    private let _disposeBag: DisposeBag = DisposeBag()
    private var isSingleList: Bool {
        contacTypes.first == .groups
    }
    
    public lazy var bottomBar: SelectBottomBar = {
        let v = SelectBottomBar()
        v.maxCount = maxCount
        
        v.onTap = { [weak self] type in
            switch type {
            case .selected:
                self?.showSelectedItem()
            case .complete:
                self?.completionAction()
            }
        }
        return v
    }()
    
    public lazy var contentStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [selecteAllView, tableView])
        v.axis = .vertical
        v.spacing = 10
        
        return v
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor

        initView()
        bindData()
        loadData()
    }
    
    private func initView() {
        let backButton = UIBarButtonItem(image: UIImage(nameInBundle: "common_back_icon"), style: .done, target: nil, action: nil)
        navigationItem.leftBarButtonItem = backButton
        
        backButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            selectedAction(pop: true)
        }).disposed(by: _disposeBag)
        
        if allowsMultipleSelection {
            view.addSubview(bottomBar)
            bottomBar.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
            }
        }

        if contacTypes.count > 1 {
            let row = UIStackView()
            row.alignment = .center
            row.distribution = .fillEqually
            
            if contacTypes.contains(.friends) {
                row.addArrangedSubview(friendsButton)
            }
            if contacTypes.contains(.groups) {
                row.addArrangedSubview(groupsButton)
            }
            if contacTypes.contains(.staff) {
                row.addArrangedSubview(staffButton)
            }
            
            view.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }
            
            view.addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.top.equalTo(row.snp.bottom).offset(16)
                make.leading.trailing.equalToSuperview()
                !allowsMultipleSelection ? make.bottom.equalToSuperview() : make.bottom.equalTo(bottomBar.snp.top)
            }
        } else {

            if contacTypes.first == .staff {
                showOrg(true)
            } else {
                view.addSubview(contentStack)
                contentStack.snp.makeConstraints { make in
                    make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
                    make.leading.trailing.equalToSuperview()
                    !allowsMultipleSelection ? make.bottom.equalToSuperview() : make.bottom.equalTo(bottomBar.snp.top)
                }
            }
        }
    }
    
    private func bindData() {
        _viewModel.loadingSubject.subscribe(onNext: { loading in
            loading ? ProgressHUD.animate() : ProgressHUD.dismiss()
        }).disposed(by: _disposeBag)
        _viewModel.lettersRelay.distinctUntilChanged().subscribe(onNext: { [weak self] (values: [String]) in
            guard let self, !values.isEmpty else { return }
            if !isSingleList {
                self.tableView.sc_indexViewDataSource = values
                self.tableView.sc_startSection = 0
            }
            self.tableView.reloadData()

            if !hasSelectedItems.isEmpty {
                self.defaultSelectedItems()
                
                let isAll = _viewModel.contacts.allSatisfy { contact in
                    self.hasSelectedItems.contains(where: { $0.ID == contact.ID })
                }
                
                selecteAllButton.isSelected = isAll
            }


        }).disposed(by: _disposeBag)

        friendsButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.showOrg(false)
            self?._viewModel.tabSelected.accept(.friends)
        }).disposed(by: _disposeBag)
        
        groupsButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.showOrg(false)
            self?._viewModel.tabSelected.accept(.groups)
        }).disposed(by: _disposeBag)
        
        staffButton.rx.tap.subscribe(onNext: { [weak self] in

            guard let `self` = self else { return }
            self.showOrg(false)
        }).disposed(by: _disposeBag)

        if contacTypes.count == 1 {
            return _viewModel.tabSelected.accept(.undefine)
        }
        
        _viewModel.tabSelected
            .map({ type in
                return type == .friends || type == .members
            })
            .bind(to: friendsButton.rx.isSelected)
            .disposed(by: _disposeBag)
        _viewModel.tabSelected
            .map({ type in
                return type == .groups
            })
            .bind(to: groupsButton.rx.isSelected)
            .disposed(by: _disposeBag)
        _viewModel.tabSelected
            .map({ type in
                return type == .staff
            })
            .bind(to: staffButton.rx.isSelected)
            .disposed(by: _disposeBag)
    }
    
    private func showOrg(_ show: Bool = false) {
#if ENABLE_ORGANIZATION
        if show {
            departmentViewController!.selectContact(hasSelected: self.hasSelectedItems, blocked: self.blockedIDs) { [weak self] (contacs: [ContactInfo]) in
                guard let `self` = self else { return }
                for (i, item) in contacs.enumerated() {
                    if !self.hasSelectedItems.contains(where: {$0.ID == item.ID}) {
                        if !allowsMultipleSelection {
                            self.hasSelectedItems.removeAll()
                        }
                        self.hasSelectedItems.append(item)
                    }
                }
                self.updateSelectedResult()
            } removeCallback: { [weak self] contacs in
                guard let self else { return }
                hasSelectedItems = hasSelectedItems.filter { c in
                    contacs.contains(where: { $0.ID != c.ID })
                }
                self.updateSelectedResult()
            }
        } else {
            self.departmentViewController?.view.removeFromSuperview()
            departmentViewController?.removeFromParent()
        }
        if allowsMultipleSelection {
            let count = hasSelectedItems.count
            bottomBar.selectedCount = count
            bottomBar.names = hasSelectedItems.compactMap({ $0.name }).joined(separator: "、")
            
            let type: ContactItemType = contacTypes.first == .groups ? .group : .user

            selecteAllButton.isSelected = hasSelectedItems.filter({ $0.type == type }).count == _viewModel.contacts.count
        }
        
        self.view.addSubview(self.departmentViewController!.view)
        self.addChild(departmentViewController!)
        self.departmentViewController!.view.snp.makeConstraints { make in
            if contacTypes.count == 1, contacTypes.first == .staff {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(allowsMultipleSelection ? bottomBar.snp.top : view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.edges.equalTo(self.tableView)
                make.top.equalTo(self.staffButton.snp.bottom)
            }
        }
#endif
    }
    
    private func loadData() {
        
        if contacTypes.contains(.friends) {
            _viewModel.getMyFriendList()
        }
        if contacTypes.contains(.groups) {
            _viewModel.getGroups()
        }
        if contacTypes.contains(.members) {
            _viewModel.getGroupMemberList(groupID: sourceID!)
        }
    }
    
    private func selecteAll() {
        if hasSelectedItems.count + _viewModel.contacts.count > maxCount {
            presentAlert(title: "selectedMaxCount".innerLocalizedFormat(arguments: maxCount))
            
            return
        }
        selecteAllButton.isSelected = !selecteAllButton.isSelected
        
        let type: ContactItemType = contacTypes.first == .groups ? .group : .user
            
        hasSelectedItems.removeAll { contact in
            _viewModel.contacts.contains(where: { $0.ID == contact.ID })
        }

        if selecteAllButton.isSelected {
            hasSelectedItems += _viewModel.contacts
            hasSelectedItems = hasSelectedItems.filter { info in
                !blockedIDs.contains(where: { $0 == info.ID })
            }
        } else {
            tableView.reloadData()
        }
        
        defaultSelectedItems()
    }

    private func defaultSelectedItems() {
        for(i, item) in hasSelectedItems.enumerated() {
            if isSingleList {
                if let row = _viewModel.contacts.firstIndex(where: { $0.ID == item.ID }) {
                    let indexPath = IndexPath(row: row, section: 0)
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            } else {
#if ENABLE_ORGANIZATION
                if let indexPath = _viewModel.getContactIndexPath(by: item.ID!) {
                    
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    hasSelectedItems[i] = _viewModel.getContactAt(indexPaths: [indexPath]).first!
                }
#else
                if let indexPath = _viewModel.getContactIndexPath(by: item.ID!) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    hasSelectedItems[i] = _viewModel.getContactAt(indexPaths: [indexPath]).first!
                }
#endif
            }
        }
        
        updateSelectedResult()
    }

    private func appendSelectedItems(_ contact: ContactInfo) {
        if !allowsMultipleSelection {
            hasSelectedItems.removeAll()
        }
        hasSelectedItems.append(contact)
        updateSelectedResult()
    }

    private func removeSelectedItems(_ contact: ContactInfo) {
        hasSelectedItems.removeAll(where: {$0.ID == contact.ID})
        updateSelectedResult()
    }
    
    private func updateSelectedResult() {
        if allowsMultipleSelection {
            let count = self.hasSelectedItems.count
            bottomBar.selectedCount = count
            bottomBar.names = hasSelectedItems.compactMap({ $0.name }).joined(separator: "、")
            
            let type: ContactItemType = contacTypes.first == .groups ? .group : .user
            let items = hasSelectedItems.filter({ $0.type == type })
            
            var selectedIDs = items.map { $0.ID }
            
            if type == .user {
                blockedIDs.forEach { id in
                    if !selectedIDs.contains(id) {
                        selectedIDs.append(id)
                    }
                }
                
                var isSelectedAll = true
                for (i, item) in _viewModel.contacts.enumerated() {
                    if !selectedIDs.contains(where: { $0 == item.ID }) {
                        isSelectedAll = false
                        break
                    }
                }
                
                selecteAllButton.isSelected = isSelectedAll
            } else {
                selecteAllButton.isSelected = selectedIDs.count == _viewModel.contacts.count
            }
        } else {
            selectedAction()
        }
    }
    
    private func completionAction() {
        selectedAction()
        completionHandler?()
    }
    
    private func selectedAction(pop: Bool = false) {

        selectedHandler?(pop, hasSelectedItems)
    }
    
    @objc private func showSelectedItem() {
        let vc = ShowSelectedUserViewController(users: hasSelectedItems) { [weak self] items in
            guard let `self` = self else { return }

            items.forEach { user in
                if let indexPath = self._viewModel.getContactIndexPath(by: user.ID!) {
                    self.tableView.deselectRow(at: indexPath, animated: false)
                    self.removeSelectedItems(user)
                } else {

#if ENABLE_ORGANIZATION
                    self.removeSelectedItems(user)
                    self.departmentViewController?.deSelectContact(user)
#endif
                }
            }
        }
        
        present(vc, animated: true)
    }
}

extension SelectContactsViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in _: UITableView) -> Int {
        isSingleList ? 1 : _viewModel.lettersRelay.value.count
    }
    
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        isSingleList ? _viewModel.contacts.count : _viewModel.contactsSections[section].count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectUserTableViewCell.className) as! SelectUserTableViewCell
        let contact = getContacts(by: indexPath)
        
        cell.titleLabel.text = contact.name
        cell.trainingLabel.text = contact.sub
        cell.trainingLabel.textColor = .c8E9AB0
        cell.trainingLabel.font = .f17
        cell.avatarImageView.setAvatar(url: contact.faceURL, text: contact.name)
        cell.showSelectedIcon = allowsMultipleSelection
        
        if blockedIDs.contains(contact.ID!) {
            cell.canBeSelected = false
        }
        
        return cell
    }
    
    public func tableView(_: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        var userID = getContacts(by: indexPath).ID!
        
        if blockedIDs.contains(userID) {
            return nil
        }
        
        if hasSelectedItems.count + 1 > maxCount {
            presentAlert(title: "selectedMaxCount".innerLocalizedFormat(arguments: maxCount))
            
            return nil
        }
        
        return indexPath
    }
    
    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = getContacts(by: indexPath)
        appendSelectedItems(contact)
    }
    
    public func tableView(_: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let contact = getContacts(by: indexPath)
        removeSelectedItems(contact)
    }
    
    public func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !isSingleList else { return nil }
        
        let name = _viewModel.lettersRelay.value[section]
        let header = ViewUtil.createSectionHeaderWith(text: name)
        
        return header
    }
    
    public func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        isSingleList ? CGFloat.leastNormalMagnitude : 33
    }
    
    public func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }
    
    private func getContacts(by indexPath: IndexPath) -> ContactInfo {
        isSingleList ? _viewModel.contacts[indexPath.row] : _viewModel.contactsSections[indexPath.section][indexPath.row]
    }
}
