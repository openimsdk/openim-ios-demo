import UIKit
import OUICore
import OUICoreView
import RxSwift

public enum ContactType: Codable {
    case undefine
    case friends
    case members
    case groups
    case staff
    case recent
    
    public var title: String {
        switch self {
        case .friends:
            return "myFriend".innerLocalized()
        case .groups:
            return "myGroup".innerLocalized()
        case .staff:
            return "organizationStructure".innerLocalized()
        case .recent:
            return "recentConversations".innerLocalized()
        default:
            return ""
        }
    }
}

public typealias SelectedResultHandler = (([ContactInfo]) -> Void)

public class MyContactsViewController: UIViewController {
    
    public var selectedHandler: SelectedResultHandler?
    
    public func selectedContact(hasSelected: [ContactInfo]? = nil, blocked: [String]? = nil, handler: SelectedResultHandler? = nil) {
        if let hasSelected {
            self.hasSelectedItems = hasSelected
            hasSelected.forEach { c in
                switch c.type {
                case .user:
                    selectedUsers.append(c)
                case .group:
                    selectedGroups.append(c)
                default:
                    break
                }
            }
        }
        self.blockedIDs = blocked ?? []
        self.selectedHandler = handler
    }
    
    public var allowsSelecteAll = true
    
    private var multipleSelected = false
    private var maxCount = 999
    private var enableChangeSelectedModel = false
    
    public init(types: [ContactType] = [.friends, .groups], multipleSelected: Bool = false, selectMaxCount: Int = 999, enableChangeSelectedModel: Bool = false, selectedHandler: SelectedResultHandler? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.maxCount = selectMaxCount
        self.selectedHandler = selectedHandler
        self.multipleSelected = multipleSelected
        self.enableChangeSelectedModel = enableChangeSelectedModel
        self.rows = types.contains(.recent) ? [.normal: types.filter({ $0 != .recent }), .frequent: []] : [.normal: types]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("\(type(of: self)) - \(#function)")
    }
    
    private var hasSelectedItems: [ContactInfo] = []
    private var blockedIDs: [String] = []
    private var selectedUsers: [ContactInfo] = []
    private var selectedGroups: [ContactInfo] = []
    private var selectedRecents: [ContactInfo] = []
    private var frequent: [ContactInfo] = []
    
    private let _disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let v = UITableView(frame: .zero, style: .grouped)
        v.dataSource = self
        v.delegate = self
        v.rowHeight = UITableView.automaticDimension
        v.estimatedRowHeight = 60
        v.translatesAutoresizingMaskIntoConstraints = false
        v.allowsMultipleSelection = true

        v.register(OptionTableViewCell.self, forCellReuseIdentifier: OptionTableViewCell.className)
        v.register(SelectUserTableViewCell.self, forCellReuseIdentifier: SelectUserTableViewCell.className)
        
        return v
    }()
    
    private lazy var rows: [Section: [ContactType]] = [
        .normal: [.friends, .groups, .staff],
        .frequent: []
    ]
    
    private lazy var bottomBar: SelectBottomBar = {
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
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "contacts".innerLocalized()
        view.backgroundColor = .viewBackgroundColor
        
        view.addSubview(tableView)
        
        if multipleSelected {
            view.addSubview(bottomBar)
            bottomBar.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
            }
            
            tableView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
                make.bottom.equalTo(bottomBar.snp.top)
            }
        } else {
            tableView.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            }
        }
        
        if !hasSelectedItems.isEmpty {
            updateSelectedResult()
        }
        
        Task.detached {
            let conversations = await IMController.shared.getAllConversations()

            let filteredCons = await withTaskGroup(of: ConversationInfo?.self) { group in
                for con in conversations {
                    group.addTask {
                        switch con.conversationType {
                        case .superGroup:
                            let isJoined = await IMController.shared.isJoinedGroup(con.groupID!)
                            return isJoined ? con : nil
                        case .notification:
                            return nil
                        default:
                            return con
                        }
                    }
                }
                return await group.reduce(into: [ConversationInfo]()) { result, conversation in
                    if let con = conversation {
                        result.append(con)
                    }
                }
            }

            await MainActor.run {
                self.frequent = filteredCons.compactMap { conversation in

                    let id = conversation.userID?.isEmpty == false ? conversation.userID : conversation.groupID
                    guard let validID = id, !validID.isEmpty else { return nil }
                    
                    return ContactInfo(ID: validID, name: conversation.showName, faceURL: conversation.faceURL, type: conversation.conversationType == .superGroup ? .group : .user)
                }
                
                self.tableView.reloadData()
            }
        }

    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        defaultSelectedItems()
    }

    private func defaultSelectedItems() {
        if !frequent.isEmpty, !hasSelectedItems.isEmpty {
            for(_, item) in hasSelectedItems.enumerated() {
                if let index = frequent.firstIndex(where: { $0.ID == item.ID }) {
                    let indexPath = IndexPath(row: index, section: Section.frequent.rawValue)
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
    }
    
    @objc private func showSelectedItem() {
        let vc = ShowSelectedUserViewController(users: hasSelectedItems) { [weak self] items in
            guard let self else { return }

            items.forEach { user in
                self.deselectedContacts(user)
                self.tableView.reloadData()
            }
        }
        
        present(vc, animated: true)
    }

    private func appendSelectedItems(_ contact: ContactInfo) {
        if !multipleSelected {
            hasSelectedItems.removeAll()
        }
        hasSelectedItems.append(contact)
        updateSelectedResult()
    }

    private func removeSelectedItems(_ contact: ContactInfo) {
        hasSelectedItems.removeAll(where: {$0.ID == contact.ID})
        updateSelectedResult()
    }
    
    private func deselectedContacts(_ contact: ContactInfo) {
        if contact.type == .user {
            selectedUsers.removeAll(where: { $0.ID == contact.ID })
        } else if contact.type == .group {
            selectedGroups.removeAll(where: { $0.ID == contact.ID })
        }
        
        selectedRecents.removeAll(where: { $0.ID == contact.ID })
        removeSelectedItems(contact)
    }
    
    private func updateSelectedResult() {
        if multipleSelected {
            let count = self.hasSelectedItems.count
            bottomBar.selectedCount = count
            bottomBar.names = hasSelectedItems.compactMap({ $0.name }).joined(separator: "、")
        } else {
            self.selectedHandler?(self.hasSelectedItems)
        }
    }
    
    @objc private func completionAction() {
        let r = selectedUsers + selectedGroups
        selectedHandler?(r)
    }
    
    fileprivate enum Section: Int, CaseIterable {
        case normal = 0
        case frequent = 1
        
        var title: String {
            switch self {
            case .normal:
                return ""
            case .frequent:
                return "最近会话".innerLocalized()
            }
        }
    }
}

extension MyContactsViewController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        rows.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = Section(rawValue: section)!

        return key == .frequent ? frequent.count : (rows[key]!.count)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = Section(rawValue: indexPath.section)!
        
        if key == .normal {
            let cell = tableView.dequeueReusableCell(withIdentifier: OptionTableViewCell.className, for: indexPath) as! OptionTableViewCell
            
            let row = rows[key]![indexPath.row]
            cell.titleLabel.text = row.title
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SelectUserTableViewCell.className, for: indexPath) as! SelectUserTableViewCell
            
            let item = frequent[indexPath.row]
            cell.avatarImageView.setAvatar(url: item.faceURL, text: item.name)
            cell.titleLabel.text = item.name
            cell.showSelectedIcon = multipleSelected
            
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let key = Section(rawValue: indexPath.section)!

        if key == .frequent {
            cell.setSelected(selectedRecents.contains(where: { $0.ID == frequent[indexPath.row].ID }), animated: false)
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Section(rawValue: section) == .frequent ? 30 : 0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = Section(rawValue: section)
        
        if section == .frequent {
            let label = UILabel()
            label.text = "  " + section!.title
            label.textColor = .c8E9AB0
            label.font = .f12
            
            return label
        }
        
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }
    
    public func tableView(_: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let key = Section(rawValue: indexPath.section)!
        
        guard key == .frequent, !frequent.isEmpty else { return }
        
        let c = frequent[indexPath.row]
        deselectedContacts(c)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = Section(rawValue: indexPath.section)!
        
        if key == .normal {
            let row = rows[key]![indexPath.row]
            
            switch row {
            case .friends:
                pushToSelecteContacts(type: .friends)
            case .groups:
                pushToSelecteContacts(type: .groups)
            case .staff:
                pushToSelecteContacts(type: .staff)
            default:
                break
            }
        } else {
            let c = frequent[indexPath.row]
            if !selectedRecents.contains(where: { $0.ID == c.ID }) {
                selectedRecents.append(c)
                
                selectedResult(infos: [c], pop: false) { [weak self] in
                    switch c.type {
                    case .user:
                        self?.selectedUsers.append(c)
                    case .group:
                        self?.selectedGroups.append(c)
                    default:
                        break
                    }
                }
            }
        }
    }
    
    private func pushToSelecteContacts(type: ContactType) {
        let vc = SelectContactsViewController(types: [type], allowsMultipleSelection: multipleSelected, enableChangeSelectedModel: enableChangeSelectedModel)
        vc.allowsSelecteAll = allowsSelecteAll
        vc.maxCount = maxCount
        
        if !multipleSelected {
            hasSelectedItems.removeAll()
            selectedUsers.removeAll()
            selectedGroups.removeAll()
        }
        
        vc.selectedContact(hasSelected: hasSelectedItems, blocked: blockedIDs) { [weak self] shouldPop, infos in
            self?.selectedResult(infos: infos, pop: shouldPop) { [weak self] in
                switch type {
                case .friends, .staff, .members:
                    self?.selectedUsers = infos.filter({ $0.type == .user })
                case .groups:
                    self?.selectedGroups = infos.filter({ $0.type == .group })
                default:
                    break
                }
            }
        }
        
        vc.completionHandler = { [weak self] in

            self?.completionAction()
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func selectedResult(infos: [ContactInfo], pop: Bool = true, todo: () -> Void) {
        if !multipleSelected {
            if !pop {
                selectedHandler?(infos)
            }
        } else {
            todo()
            let r = selectedUsers + selectedGroups
            hasSelectedItems = r.reduce([]) { (partialResult: [ContactInfo], info) in
                partialResult.contains(where: { $0.ID == info.ID }) ? partialResult : partialResult + [info]
            }
            
            let r2 = selectedRecents + hasSelectedItems
            selectedRecents = r2.reduce([]) { (partialResult: [ContactInfo], info) in
                partialResult.contains(where: { $0.ID == info.ID }) ? partialResult : partialResult + [info]
            }
            
            updateSelectedResult()
        }
        
        if pop {
            navigationController?.popViewController(animated: false)
        }
    }
}
