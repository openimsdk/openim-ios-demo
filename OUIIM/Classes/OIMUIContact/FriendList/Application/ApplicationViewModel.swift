
import OUICore

class ApplicationViewModel {
    var groupApplication: GroupApplicationInfo!
    var friendApplication: FriendApplication!
    
    init(groupApplication: GroupApplicationInfo?, friendApplication: FriendApplication?) {

        self.groupApplication = groupApplication
        self.friendApplication = friendApplication
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var companyString: NSMutableAttributedString {
        get {
            let a = NSMutableAttributedString(string: "申请加入".innerLocalized(), attributes: [ NSAttributedString.Key.foregroundColor: UIColor.c8E9AB0])
            let c = NSAttributedString(string: groupApplication.groupName ?? "",
                                       attributes: [ NSAttributedString.Key.foregroundColor: UIColor.c0089FF])
            a.append(c)
            
            return a
        }
    }
    
    var joinSourceString: String {
        get {
            var v = ""
            switch groupApplication.joinSource {
            case .search:
                v = "search".innerLocalized()
            case .QRCode:
                v = "qrcode".innerLocalized()
            case .invited:
                v = "invite".innerLocalized()
            }
            
            return v.isEmpty ? "" : "sourceFrom".innerLocalizedFormat(arguments: v)
        }
    }
    
    var requestDescString: String {
        get {
            return ((groupApplication != nil ? groupApplication.reqMsg : friendApplication.reqMsg) ?? "") ?? ""
        }
    }
    
    func accept(completion: @escaping CallBack.StringOptionalReturnVoid) {
        if let friendApplication = friendApplication {
            IMController.shared.acceptFriendApplication(uid: friendApplication.fromUserID) { [weak self] r in
                completion(r)


            }
            
        } else if let groupApplication = groupApplication {
            IMController.shared.acceptGroupApplication(groupID: groupApplication.groupID, fromUserId: groupApplication.userID!) { [weak self] r in
                completion(r)


            }
        }
    }
    
    func refuse(completion: @escaping CallBack.StringOptionalReturnVoid) {
        if let friendApplication = friendApplication {
            IMController.shared.refuseFriendApplication(uid: friendApplication.fromUserID ) { [weak self] r in
                completion(r)


            }
            
        } else if let groupApplication = groupApplication {
            IMController.shared.refuseGroupApplication(groupID: groupApplication.groupID, fromUserId: groupApplication.userID!) { [weak self] r in
                completion(r)


            }
        }
    }
}
