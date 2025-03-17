

import OUICore
import OUICoreView
import ProgressHUD

open class AddTableViewController: UITableViewController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        navigationItem.title = "添加".innerLocalized()
    }
    
    private func configureTableView() {
        tableView.rowHeight = 74
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorColor = .viewBackgroundColor
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 71, bottom: 0, right: 22)
        tableView.register(AddEntranceTableViewCell.self, forCellReuseIdentifier: AddEntranceTableViewCell.className)
    }
    
    func newGroup(groupType: GroupType = .normal) {
        
#if ENABLE_ORGANIZATION
        let vc = MyContactsViewController(types: [.friends, .staff], multipleSelected: true)
#else
        let vc = MyContactsViewController(types: [.friends], multipleSelected: true, enableChangeSelectedModel: true)
#endif
        vc.selectedContact(blocked: [IMController.shared.uid]) { [weak self] (r: [ContactInfo]) in
            guard let self else { return }
            
            let users = r.map {UserInfo(userID: $0.ID!, nickname: $0.name, faceURL: $0.faceURL)}
            
            if users.count > 1 {
                let vc = NewGroupViewController(users: users, groupType: .working)
                navigationController?.pushViewController(vc, animated: true)
            } else {
                guard let userID = users.first?.userID else { return }
                ProgressHUD.animate()
                createSingleChat(userID: userID) { [self] c in
                    ProgressHUD.dismiss()
                    let vc = ChatViewControllerBuilder().build(c, hiddenInputBar: c.conversationType == .notification)
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func createSingleChat(userID: String, onComplete: @escaping (ConversationInfo) -> Void) {
        
        IMController.shared.getConversation(sessionType: .c2c, sourceId: userID) { [weak self] (conversation: ConversationInfo?) in
            guard let conversation else { return }
            
            onComplete(conversation)
        }
    }
    
    private let rowTypes: [EntranceType] = [
        .searchUser,
        .createGroup,
        .joinGroup
    ]
    
    override open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        rowTypes.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddEntranceTableViewCell.className) as! AddEntranceTableViewCell
        let item = rowTypes[indexPath.row]
        cell.avatarImageView.image = item.iconImage
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.subtitle
        return cell
    }
    
    override open func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = rowTypes[indexPath.row]
        switch item {
        case .createGroup:
            newGroup(groupType: .working)
        case .joinGroup:
            let vc = SearchGroupViewController()
            navigationController?.pushViewController(vc, animated: true)
            vc.didSelectedItem = { [weak self] id in
                let vc = GroupDetailViewController(groupId: id)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        case .searchUser:
            let vc = SearchFriendViewController()
            navigationController?.pushViewController(vc, animated: true)
            vc.didSelectedItem = { [weak self] id in
                let vc = UserDetailTableViewController(userId: id, groupId: nil)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    struct SectionModel {
        let name: String
        let items: [EntranceType]
    }
    
    enum EntranceType {
        case createGroup
        case joinGroup
        case searchUser
        
        var iconImage: UIImage? {
            switch self {
            case .createGroup:
                return UIImage(nameInBundle: "add_create_group_icon")
            case .joinGroup:
                return UIImage(nameInBundle: "add_join_group_icon")
            case .searchUser:
                return UIImage(nameInBundle: "add_search_friend_icon")
            }
        }
        
        var title: String {
            switch self {
            case .createGroup:
                return "创建群聊".innerLocalized()
            case .joinGroup:
                return "addGroup".innerLocalized()
            case .searchUser:
                return "addFriend".innerLocalized()
            }
        }
        
        var subtitle: String {
            switch self {
            case .createGroup:
                return "createGroupHint".innerLocalized()
            case .joinGroup:
                return "addGroupHint".innerLocalized()
            case .searchUser:
                return "addFriendHint".innerLocalized()
            }
        }
    }
}
