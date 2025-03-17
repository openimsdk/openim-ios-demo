
import Foundation
import OpenIMSDK
import RxCocoa
import RxSwift
import UIKit
import AudioToolbox
import KTVHTTPCache

public enum ConnectionStatus: Int {
    case connectFailure = 0
    case connecting = 1
    case connected = 2
    case syncStart = 3
    case syncComplete = 4
    case syncFailure = 5
    case kickedOffline = 6
    case syncProgress = 7
    
    public var title: String {
        switch self {
        case .connectFailure:
            return "connectionFailed".innerLocalized()
        case .connecting:
            return "connecting".innerLocalized()
        case .connected:
            return "synchronizing".innerLocalized()
        case .syncStart, .syncProgress:
            return "synchronizing".innerLocalized()
        case .syncComplete:
            return "synchronizing".innerLocalized()
        case .syncFailure:
            return "syncFailed".innerLocalized()
        case .kickedOffline:
            return "accountException".innerLocalized()
        }
    }
}

public enum SDKError: Int {
    case blockedByFriend = 1302 
    case deletedByFriend = 1303 
    case refuseToAddFriends = 10007 
}

public enum CustomMessageType: Int {
    case call = 901
    case customEmoji = 902
    case tagMessage = 903
    case moments = 904
    case meeting = 905
    case blockedByFriend = 910
    case deletedByFriend = 911
    
    case callingInvite = 200
    case callingAccept = 201
    case callingReject = 202
    case callingCancel = 203
    case callingHungup = 204
}


public protocol ContactsDataSource: AnyObject {
    func setFrequentUsers(_ users: [ContactInfo])
    func getFrequentUsers() -> [ContactInfo]
}

extension IMController: ContactsDataSource {
    public func getFrequentUsers() -> [ContactInfo] {
        let uid = IMController.shared.uid
        guard let usersJson = UserDefaults.standard.object(forKey: uid) as? String else { return [] }
        
        guard let users = JsonTool.fromJson(usersJson, toClass: [ContactInfo].self) else {
            return []
        }
        let current = Int(Date().timeIntervalSince1970)
        let oUsers: [ContactInfo] = users.compactMap { (user: ContactInfo) in
            if current - user.createTime <= 7 * 24 * 3600 {
                return user
            }
            return nil
        }
        return Array(oUsers)
    }
    
    public func setFrequentUsers(_ users: [ContactInfo]) {
        let uid = IMController.shared.uid
        let createTime = Int(Date().timeIntervalSince1970)
        let before = getFrequentUsers()
        var mUsers: [ContactInfo] = before
        
        let u = users.map({ ContactInfo(ID: $0.ID, name: $0.name, faceURL: $0.faceURL, createTime: createTime )})
        
        mUsers.append(contentsOf: u)
        
        if let ret = try? mUsers.reduce<ContactInfo>([]) { partialResult, info in
            partialResult.contains(where: { $0.ID == info.ID }) ? partialResult : partialResult + [info]
        } {
            let json = JsonTool.toJson(fromObject: ret)
            UserDefaults.standard.setValue(json, forKey: uid)
            UserDefaults.standard.synchronize()
        }
    }
    
    public func removeFrequentUser(_ userID: String) {
        let uid = IMController.shared.uid
        guard let usersJson = UserDefaults.standard.object(forKey: uid) as? String else { return }
        
        var users = JsonTool.fromJson(usersJson, toClass: [ContactInfo].self)
        
        users?.removeAll(where: { $0.ID == userID })
        
        if let users {
            let json = JsonTool.toJson(fromObject: users)
            UserDefaults.standard.setValue(json, forKey: uid)
            UserDefaults.standard.synchronize()
        }
    }
    
    public func updateFrequentUser(_ user: ContactInfo) {
        let uid = IMController.shared.uid
        guard let usersJson = UserDefaults.standard.object(forKey: uid) as? String else { return }
        
        var users = JsonTool.fromJson(usersJson, toClass: [ContactInfo].self)
        
        if let index = users?.firstIndex(where: { $0.ID == user.ID }) {
            users?[index] = user
        }
        
        if let users {
            let json = JsonTool.toJson(fromObject: users)
            UserDefaults.standard.setValue(json, forKey: uid)
            UserDefaults.standard.synchronize()
        }
    }
}

public class IMController: NSObject {
    public static let addFriendPrefix = "io.openim.app/addFriend/"
    public static let joinGroupPrefix = "io.openim.app/joinGroup/"
    public static let shared: IMController = .init()
    public var imManager: OpenIMSDK.OIMManager!

    public let friendApplicationChangedSubject: PublishSubject<FriendApplication> = .init()

    public let groupApplicationChangedSubject: PublishSubject<GroupApplicationInfo> = .init()
    public let groupInfoChangedSubject: PublishSubject<GroupInfo> = .init()
    public let contactUnreadSubject: PublishSubject<Int> = .init()
    
    public let conversationChangedSubject: BehaviorSubject<[ConversationInfo]> = .init(value: [])
    public let friendInfoChangedSubject: BehaviorSubject<FriendInfo?> = .init(value: nil)
    public let addFriendSubject: PublishSubject<FriendInfo> = .init()
    public let deleteFriendSubject: PublishSubject<FriendInfo> = .init()
    
    public let onBlackAddedSubject: BehaviorSubject<BlackInfo?> = .init(value: nil)
    public let onBlackDeletedSubject: BehaviorSubject<BlackInfo?> = .init(value: nil)
    
    public let newConversationSubject: BehaviorSubject<[ConversationInfo]> = .init(value: [])
    public let totalUnreadSubject: BehaviorSubject<Int> = .init(value: 0)
    public let newMsgReceivedSubject: PublishSubject<MessageInfo> = .init()
    public let c2cReadReceiptReceived: BehaviorSubject<[ReceiptInfo]> = .init(value: [])
    public let groupReadReceiptReceived: PublishSubject<GroupMessageReceipt> = .init()
    public let groupMemberInfoChange: PublishSubject<GroupMemberInfo?> = .init()
    public let joinedGroupAdded: PublishSubject<GroupInfo?> = .init()
    public let joinedGroupDeleted: PublishSubject<GroupInfo?> = .init()
    public let groupMemberAdded: PublishSubject<GroupMemberInfo?> = .init()
    public let groupMemberDeleted: PublishSubject<GroupMemberInfo?> = .init()
    public let msgRevokeReceived: PublishSubject<MessageRevoked> = .init()
    public let recvOnlineMesssage: PublishSubject<MessageInfo> = .init()
    public let currentUserRelay: BehaviorRelay<UserInfo?> = .init(value: nil)
    public let customBusinessSubject: PublishSubject<[String: Any]?> = .init()
    public let organizationUpdated: PublishSubject<String?> = .init()

    public let connectionRelay: BehaviorRelay<(status: ConnectionStatus, reInstall: Bool? , progress: Int?)> = .init(value:( status: .connecting, reInstall: nil, progress: nil))

    public let userStatusSubject: BehaviorSubject<UserStatusInfo?> = .init(value: nil)

    public let inputStatusChangedSubject: BehaviorSubject<InputStatusChangedData?> = .init(value: nil)
    
    public var uid: String = ""
    public var token: String = ""

    public var sdkAPIAdrr = ""

    public var businessServer = ""
    public var businessToken: String?

    private var remindTimeStamp: Double = NSDate().timeIntervalSince1970

    public var enableRing = true

    public var enableVibration = true
    
    fileprivate var appName: String!

    public func setup(businessServer: String, businessToken: String?) {
        Self.shared.businessServer = businessServer
        Self.shared.businessToken = businessToken
    }
    
    public func setup(sdkAPIAdrr: String, sdkWSAddr: String, logLevel: Int = 3, onKickedOffline: (() -> Void)? = nil, onUserTokenInvalid: (() -> Void)? = nil) {
        
        let infoDictionary = Bundle.main.infoDictionary
        let displayName = infoDictionary!["CFBundleDisplayName"] as? String
        appName = displayName ?? ""
        
        self.sdkAPIAdrr = sdkAPIAdrr
        let manager = OIMManager.manager
        
        var config = OIMInitConfig()
        config.apiAddr = sdkAPIAdrr
        config.wsAddr = sdkWSAddr
        config.logLevel = logLevel
        
        manager.initSDK(with: config) { [weak self] in
            self?.connectionRelay.accept((status: .connecting, reInstall: nil, progress: nil))
        } onConnectFailure: { [weak self] code, msg in
            print("onConnectFailed code:\(code), msg:\(String(describing: msg))")
            self?.connectionRelay.accept((status: .connectFailure, reInstall: nil, progress: nil))
        } onConnectSuccess: {[weak self] in
            print("onConnectSuccess")
            self?.connectionRelay.accept((status: .connected, reInstall: nil, progress: nil))
        } onKickedOffline: {[weak self] in
            print("onKickedOffline")
            onKickedOffline?()
            self?.connectionRelay.accept((status: .kickedOffline, reInstall: nil, progress: nil))
        } onUserTokenExpired: {
            onKickedOffline?()
            print("onUserTokenExpired")
        } onUserTokenInvalid: { _ in
            print("onUserTokenInvalid")
            onUserTokenInvalid?()
        }
        
        Self.shared.imManager = manager

        OpenIMSDK.OIMManager.callbacker.addUserListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addFriendListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addGroupListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addConversationListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addAdvancedMsgListener(listener: self)
        OpenIMSDK.OIMManager.callbacker.addCustomBusinessListener(listener: self)
        
        do {
            try KTVHTTPCache.proxyStart()
        } catch (let e) {
            print("KTVHTTPCache proxyStart throw error: \(e)")
        }
    }
    
    public func login(uid: String, token: String, onSuccess: @escaping (String?) -> Void, onFail: @escaping (Int, String?) -> Void) {
        Self.shared.imManager.login(uid, token: token) { [weak self] (resp: String?) in
            self?.uid = uid
            self?.token = token
            
            onSuccess(resp)
        } onFailure: { (code: Int, msg: String?) in
            onFail(code, msg)
        }
    }
    
    struct NetError: Error {
        let code: Int
        let message: String?
    }
    
    public typealias MessagesCallBack = ([MessageInfo]) -> Void
    public typealias SeqMessagesCallBack = (Bool, [MessageInfo]) -> Void

    public var chatingConversationID: String = ""

    func ringAndVibrate() {
        if NSDate().timeIntervalSince1970 - remindTimeStamp >= 1 { 


            if enableRing {
                var theSoundID : SystemSoundID = 0
                let url = URL(fileURLWithPath: "/System/Library/Audio/UISounds/nano/sms-received1.caf")
                let urlRef = url as CFURL
                let err = AudioServicesCreateSystemSoundID(urlRef, &theSoundID)
                
                if err == kAudioServicesNoError {
                    AudioServicesPlaySystemSoundWithCompletion(theSoundID, {
                        AudioServicesDisposeSystemSoundID(theSoundID)
                    })
                }
            }

            if enableVibration {
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            }
            remindTimeStamp = NSDate().timeIntervalSince1970
        }
    }
    
    public func updateFCMToken(_ token: String) {
        Self.shared.imManager.updateFcmToken(token, expireTime: Int(NSDate().addingTimeInterval(3600 * 24 * 7).timeIntervalSince1970 * 1000)) { r in
            
        }
    }
}


extension IMController {



    public func getGroupListBy(id: String) -> Observable<String?> {
        return Observable<String?>.create { observer in
            Self.shared.imManager.getSpecifiedGroupsInfo([id], onSuccess: { (groups: [OIMGroupInfo]?) in
                observer.onNext(groups?.first?.groupID)
                observer.onCompleted()
            }, onFailure: { (code: Int, msg: String?) in
                observer.onError(NetError(code: code, message: msg))
            })
            
            return Disposables.create()
        }
    }
    
    public func getJoinedGroupList(offset: Int = 0, count: Int = 40, completion: @escaping ([GroupInfo]) -> Void) {
        Self.shared.imManager.getJoinedGroupListPage(withOffset: offset, count: count) { (groups: [OIMGroupInfo]?) in
            guard let groups = groups else {
                completion([])
                return
            }
            
            let joined: [GroupInfo] = groups.compactMap { $0.toGroupInfo() }
            completion(joined)
        } onFailure: { code, msg in
            print("code:\(code), msg: \(msg)")
        }
    }



    public func getFriendsBy(id: String) -> Observable<FriendInfo?> {
        return Observable<FriendInfo?>.create { observer in
            Self.shared.imManager.getSpecifiedFriendsInfo([id], filterBlack: false) { users in
                observer.onNext(users?.first?.toFriendInfo())
                observer.onCompleted()
            } onFailure: { (code: Int, msg: String?) in
                observer.onError(NetError(code: code, message: msg))
            }
            return Disposables.create()
        }
    }
    
    public func getFriendsInfo(userIDs: [String], completion: @escaping CallBack.FriendsInfosReturnVoid) {
        Self.shared.imManager.getSpecifiedFriendsInfo(userIDs, filterBlack: false) { users in
            let r = users?.compactMap({ $0.toFriendInfo() })
            completion(r ?? [])
        }
    }
    
    public func getFriendApplicationListAsRecipient(completion: @escaping ([FriendApplication]) -> Void) {
        Self.shared.imManager.getFriendApplicationListAsRecipientWith { applications in
            let arr = applications ?? []
            let ret = arr.compactMap { $0.toFriendApplication() }
            completion(ret)
        } onFailure: { code, msg in
            completion([])
            print("\(#function) code:\(code), msg: \(msg)")
        }
    }
    
    public func getFriendApplicationListAsApplicant(completion: @escaping ([FriendApplication]) -> Void) {
        Self.shared.imManager.getFriendApplicationListAsApplicantWith { applications in
            let arr = applications ?? []
            let ret = arr.compactMap { $0.toFriendApplication() }
            completion(ret)
        } onFailure: { code, msg in
            completion([])
            print("\(#function) code:\(code), msg: \(msg)")
        }
    }
    
    public func acceptFriendApplication(uid: String, handleMsg: String? = nil, completion: @escaping (String?) -> Void) {
        Self.shared.imManager.acceptFriendApplication(uid, handleMsg: handleMsg ?? "") { r in
            completion(nil)
        } onFailure: { code, msg in
            print("code:\(code), msg: \(msg)")
            completion(msg)
        }
    }
    
    public func refuseFriendApplication(uid: String, handleMsg: String? = nil, completion: @escaping (String?) -> Void) {
        
        Self.shared.imManager.refuseFriendApplication(uid, handleMsg: handleMsg ?? "") { r in
            completion(nil)
        } onFailure: { code, msg in
            print("code:\(code), msg: \(msg)")
            completion(msg)
        }
    }
    
    public func getGroupApplicationListAsRecipient(completion: @escaping ([GroupApplicationInfo]) -> Void) {
        Self.shared.imManager.getGroupApplicationListAsRecipientWith { applications in
            let arr = applications ?? []
            let ret = arr.compactMap { $0.toGroupApplicationInfo() }
            completion(ret)
        } onFailure: { code, msg in
            completion([])
            print("\(#function) code:\(code), msg: \(msg)")
        }
    }
    
    public func getGroupApplicationListAsApplicant(completion: @escaping ([GroupApplicationInfo]) -> Void) {
        Self.shared.imManager.getGroupApplicationListAsApplicantWith { applications in
            let arr = applications ?? []
            let ret = arr.compactMap { $0.toGroupApplicationInfo() }
            completion(ret)
        } onFailure: { code, msg in
            completion([])
            print("\(#function) code:\(code), msg: \(msg)")
        }
        
    }
    
    public func getFriendList(offset: Int = 0, count: Int = 40, filterBlack: Bool = false, completion: @escaping ([FriendInfo]) -> Void) {
        Self.shared.imManager.getFriendListPage(withOffset: offset, count: count, filterBlack: filterBlack) { friends in
            let arr = friends ?? []
            let ret = arr.compactMap { $0.toFriendInfo() }
            completion(ret)
        } onFailure: { code, msg in
            print("\(#function) throw error: code: \(code), msg: \(msg)")
            completion([])
        }
    }
    
    public func getAllFriends() async -> [PublicUserInfo] {
        
        var friends: [PublicUserInfo] = []
        var count = 1000
        
        while (true) {
            let r = await getFriendsSplit(offset: friends.count, count: count)
            friends.append(contentsOf: r)
            
            if r.count < count {
                break
            }
        }
        
        return friends
    }
    
    public func getFriendsSplit(offset: Int = 0, count: Int = 1000, filterBlack: Bool = false) async -> [FriendInfo] {
        return await withCheckedContinuation { continuation in
            getFriendList(offset: offset, count: count, filterBlack: filterBlack) { r in
                
                continuation.resume(returning: r)
            }
        }
    }
    
    public func acceptGroupApplication(groupID: String, fromUserId: String, handleMsg: String? = nil, completion: @escaping (String?) -> Void) {
        
        Self.shared.imManager.acceptGroupApplication(groupID, fromUserId: fromUserId, handleMsg: handleMsg ?? "") { r in
            completion(nil)
        } onFailure: { code, msg in
            print("code:\(code), msg: \(msg)")
            completion(msg)
        }
    }
    
    public func refuseGroupApplication(groupID: String, fromUserId: String, handleMsg: String? = nil, completion: @escaping (String?) -> Void) {
        Self.shared.imManager.refuseGroupApplication(groupID, fromUserId: fromUserId, handleMsg: handleMsg ?? "") { r in
            completion(nil)
        } onFailure: { code, msg in
            print("code:\(code), msg: \(msg)")
            completion(msg)
        }
    }
    
    public func getGroupMemberList(groupId: String, filter: GroupMemberFilter = .member, offset: Int, count: Int, onSuccess: @escaping CallBack.GroupMembersReturnVoid) {
        Self.shared.imManager.getGroupMemberList(groupId,
                                                 filter: OIMGroupMemberFilter(rawValue: filter.rawValue)!,
                                                 offset: offset,
                                                 count: count) { (memberInfos: [OIMGroupMemberInfo]?) in
            let members: [GroupMemberInfo] = memberInfos?.compactMap { $0.toGroupMemberInfo() } ?? []
            onSuccess(members)
        }
    }
    
    public func getAllGroupMembers(groupID: String) async -> [GroupMemberInfo] {
        
        var members: [GroupMemberInfo] = []
        var count = 1000
        
        while (true) {
            let r = await getGroupMembersSplit(groupID: groupID, offset: members.count, count: count)
            members.append(contentsOf: r)
            
            if r.count < count {
                break
            }
        }
        
        return members
    }
    
    
    public func getGroupMembersSplit(groupID: String, offset: Int = 0, count: Int = 1000) async -> [GroupMemberInfo] {
        return await withCheckedContinuation { continuation in
            getGroupMemberList(groupId: groupID, filter: .all, offset: offset, count: count) { ms in
                continuation.resume(returning: ms)
            }
        }
    }
    
    public func isJoinedGroup(groupID: String, onSuccess: @escaping CallBack.BoolReturnVoid) {
        Self.shared.imManager.isJoinedGroup(groupID) { r in
            onSuccess(r)
        } onFailure: { code, msg in
            print("\(code),\(msg)")
        }
    }
    
    public func isJoinedGroup(_ groupID: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            Self.shared.imManager.isJoinedGroup(groupID) { r in
                continuation.resume(returning: r)
            } onFailure: { code, msg in
                print("is Joined Group throw an error:\(code),\(msg)")
                continuation.resume(returning: false)
            }
        }
    }
    
    public func getGroupMembersInfo(groupId: String, uids: [String], onSuccess: @escaping CallBack.GroupMembersReturnVoid) {
        
        Self.shared.imManager.getSpecifiedGroupMembersInfo(groupId, usersID: uids) { (groupMembers: [OIMGroupMemberInfo]?) in
            let members: [GroupMemberInfo] = groupMembers?.compactMap { $0.toGroupMemberInfo() } ?? []
            onSuccess(members)
        } onFailure: { code, msg in
            print("\(code),\(msg)")
        }
    }
    
    public func getGroupInfo(groupIds: [String], onSuccess: @escaping CallBack.GroupInfosReturnVoid) {
        Self.shared.imManager.getSpecifiedGroupsInfo(groupIds) { (groupInfos: [OIMGroupInfo]?) in
            let groups: [GroupInfo] = groupInfos?.compactMap { $0.toGroupInfo() } ?? []
            onSuccess(groups)
        } onFailure: { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func setGroupInfo(group: GroupInfo, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupInfo(group.toOIMGroupInfo(exceptDisplayIsRead: true), onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func setGroupVerification(groupId: String, type: GroupVerificationType, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupVerification(groupId, needVerification: OIMGroupVerificationType(rawValue: type.rawValue) ?? .allNeedVerification, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func setGroupMemberRoleLevel(groupId: String, userID: String, roleLevel: GroupMemberRole, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupMemberRoleLevel(groupId, userID: userID, roleLevel: OIMGroupMemberRole(rawValue: roleLevel.rawValue) ?? .member, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func setGroupMemberNicknameOf(userid: String, inGroupId: String, with name: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setGroupMemberNickname(inGroupId, userID: userid, groupNickname: name, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func transferOwner(groupId: String, to userId: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.transferGroupOwner(groupId, newOwner: userId, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func dismissGroup(id: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.dismissGroup(id, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func quitGroup(id: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.quitGroup(id, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func joinGroup(id: String, reqMsg: String?, joinSource: JoinSource = .search, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.joinGroup(id, reqMsg: reqMsg, joinSource: OIMJoinType(rawValue: Int32(joinSource.rawValue))!, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func inviteUsersToGroup(groupId: String, uids: [String], onSuccess: @escaping CallBack.VoidReturnVoid, onFailure: CallBack.ErrorOptionalReturnVoid? = nil) {
        Self.shared.imManager.inviteUser(toGroup: groupId, reason: "", usersID: uids) { r in
            onSuccess()
        } onFailure: { code, msg in
            print("\(#function)：\(code), \(msg)")
            onFailure?(code, msg)
        }
    }
    
    public func kickGroupMember(groupId: String, uids: [String], onSuccess: @escaping CallBack.BoolReturnVoid) {
        Self.shared.imManager.kickGroupMember(groupId, reason: "", usersID: uids) { r in
            onSuccess(r != nil)
        } onFailure: { code, msg in
            onSuccess(false)
            print("\(#function) throw error \(code), \(msg)")
        }
    }
    
    public func addFriend(uid: String, reqMsg: String?, onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: CallBack.ErrorOptionalReturnVoid? = nil) {
        Self.shared.imManager.addFriend(uid, reqMessage: reqMsg, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    public func deleteFriend(uid: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.deleteFriend(uid) { [weak self] r in
            onSuccess(r)
            self?.removeFrequentUser(uid)
        }
    }
    
    public func blockUser(uid: String, blocked: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        if blocked {
            Self.shared.imManager.add(toBlackList: uid, onSuccess: onSuccess)
        } else {
            Self.shared.imManager.remove(fromBlackList: uid, onSuccess: onSuccess)
        }
    }
    
    public func getBlackList(onSuccess: @escaping CallBack.BlackListOptionalReturnVoid) {
        Self.shared.imManager.getBlackListWith { (blackUsers: [OIMBlackInfo]?) in
            let result = (blackUsers ?? []).compactMap { $0.toBlackInfo() }
            onSuccess(result)
        } onFailure: { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func getBlackList() async -> [BlackInfo] {
        return await withCheckedContinuation { continuation in
            Self.shared.imManager.getBlackListWith { (blackUsers: [OIMBlackInfo]?) in
                let result = (blackUsers ?? []).compactMap { $0.toBlackInfo() }
                
                continuation.resume(returning: result)
            } onFailure: { code, msg in
                continuation.resume(returning: [])
                print("\(code), \(msg)")
            }
        }
    }
    
    public func removeFromBlackList(uid: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.remove(fromBlackList: uid, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func setFriend(uid: String, remark: String?, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setFriendRemark(uid, remark: remark, onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
            onSuccess(nil)
        }
    }
    
    public func checkFriend(userID: String, onSuccess: @escaping CallBack.BoolReturnVoid) {
        Self.shared.imManager.checkFriend([userID]) { info in
            print("\(info)")
            if let r = info?.first {
                onSuccess(r.result == 1)
            } else {
                onSuccess(false)
            }
        } onFailure: { code, msg in
            print("check\(code), \(msg)")
        }
    }
}


extension IMController {
    
    public func atAllTag() -> String {
        OIMMessageInfo.getAtAllTag()
    }
    
    public func getAllConversationList(completion: @escaping ([ConversationInfo]) -> Void, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        Self.shared.imManager.getAllConversationListWith { (conversations: [OIMConversationInfo]?) in
            let arr = conversations ?? []
            let ret = arr.compactMap { $0.toConversationInfo() }
            completion(ret)
        } onFailure: { code, msg in
            onFailure(code, msg)
            print("\(#function) throw error \(code) - \(msg)")
        }
    }
    
    public func getConversationsSplit(offset: Int = 0, count: Int = 1000) async -> [ConversationInfo] {
        return await withCheckedContinuation { continuation in
            Self.shared.imManager.getConversationListSplit(withOffset: offset, count: count) { cs in
                continuation.resume(returning: cs?.compactMap({ $0.toConversationInfo() }) ?? [])
            } onFailure: { code, msg in
                continuation.resume(returning: [])
            }
        }
    }
    
    public func getAllConversations() async -> [ConversationInfo] {
        let pageSize = 1000
        
        var temp: [ConversationInfo] = []
        
        while (true) {
            let result = await IMController.shared.getConversationsSplit(offset: temp.count, count: pageSize)
            
            temp.append(contentsOf: result)
            
            if result.count < pageSize {
                break
            }
        }
        
        return temp
    }

    public func deleteConversation(conversationID: String, completion: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.deleteConversationAndDeleteAllMsg(conversationID, onSuccess: completion) { code, msg in
            print("\(#function) throw error \(code) - \(msg)")
            completion(nil)
        }
    }
    
    public func getTotalUnreadMsgCount(completion: ((Int) -> Void)?) {
        Self.shared.imManager.getTotalUnreadMsgCountWith(onSuccess: completion, onFailure: nil)
    }
    
    public func setConversationRecvMessageOpt(conversationID: String, status: ReceiveMessageOpt, completion: ((String?) -> Void)?) {
        let opt: OIMReceiveMessageOpt
        switch status {
        case .receive:
            opt = .receive
        case .notReceive:
            opt = .notReceive
        case .notNotify:
            opt = .notNotify
        }
        
        Self.shared.imManager.setConversationRecvMessageOpt(conversationID, status: opt, onSuccess: completion) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func setGroupLookMemberInfo(id: String, rule: Int, completion: ((String?) -> Void)?) {
        Self.shared.imManager.setGroupLookMemberInfo(id, rule: Int32(rule), onSuccess: completion) { code, msg in
            print("pin conversation failed: \(code), \(msg)")
        }
    }
    
    public func setGroupApplyMemberFriend(id: String, rule: Int, completion: ((String?) -> Void)?) {
        Self.shared.imManager.setGroupApplyMemberFriend(id, rule: Int32(rule), onSuccess: completion) { code, msg in
            print("pin conversation failed: \(code), \(msg)")
        }
    }
    
    public func pinConversation(id: String, isPinned: Bool, completion: ((String?) -> Void)?) {
        Self.shared.imManager.pinConversation(id, isPinned: isPinned, onSuccess: completion) { code, msg in
            print("pin conversation failed: \(code), \(msg)")
            completion?(nil)
        }
    }
    
    public func changeGroupMute(groupID: String, isMute: Bool, completion: ((String?) -> Void)?) {
        Self.shared.imManager.changeGroupMute(groupID, isMute: isMute, onSuccess: completion) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func changeGroupMemberMute(groupID: String, userID: String, seconds: Int, completion: ((String?) -> Void)?) {
        Self.shared.imManager.changeGroupMemberMute(groupID, userID: userID, mutedSeconds: seconds, onSuccess: completion) { code, msg in
            print("\(code), \(msg)")
            completion?(nil)
        }
    }
    
    public func getHistoryMessageList(conversationID: String,
                                      conversationType: ConversationType = .c2c,
                                      startCliendMsgId: String?,
                                      count: Int = 50,
                                      completion: @escaping SeqMessagesCallBack) {
        
        let opts = OIMGetAdvancedHistoryMessageListParam()
        opts.conversationID = conversationID
        opts.viewType = .history
        opts.startClientMsgID = startCliendMsgId
        opts.count = count
        
        Self.shared.imManager.getAdvancedHistoryMessageList(opts) { msgListInfo in
            let arr = msgListInfo?.messageList.compactMap({ $0.toMessageInfo() }) ?? []
            completion(msgListInfo?.isEnd ?? true, arr)
        }
    }
    
    public func getHistoryMessageListReverse(conversationID: String,
                                             conversationType: ConversationType = .c2c,
                                             startCliendMsgId: String?,
                                             count: Int = 50,
                                             completion: @escaping SeqMessagesCallBack) {
        let opts = OIMGetAdvancedHistoryMessageListParam()
        opts.conversationID = conversationID
        opts.viewType = .history
        opts.startClientMsgID = startCliendMsgId
        opts.count = count
        
        Self.shared.imManager.getAdvancedHistoryMessageListReverse(opts) { msgListInfo in
            let arr = msgListInfo?.messageList.compactMap({ $0.toMessageInfo() }) ?? []
            completion(msgListInfo?.isEnd ?? true, arr)
        } onFailure: { code, msg in
            print("getHistoryMessageListReverse error: \(code), \(msg)")
        }
    }
    
    public func sendMessage(message: MessageInfo, to recvID: String, conversationType: ConversationType = .c2c, onComplete: @escaping CallBack.MessageReturnVoid) {
        let offlinePushInfo = message.offlinePushInfo
        offlinePushInfo.title = offlinePushInfo.title ?? appName
        offlinePushInfo.desc = offlinePushInfo.desc ?? "offlineMessage".innerLocalized()
        message.offlinePushInfo = offlinePushInfo
        
        sendHelper(message: message.toOIMMessageInfo(), to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    private func sendHelper(message: OIMMessageInfo,
                            to recvID: String,
                            conversationType: ConversationType,
                            onComplete: @escaping CallBack.MessageReturnVoid) {
        var model = message.toMessageInfo()
        model.isRead = false
        if conversationType == .c2c {
            Self.shared.imManager.sendMessage(message, recvID: recvID, groupID: nil, offlinePushInfo: message.offlinePush) { (newMessage: OIMMessageInfo?) in
                if let respMessage = newMessage {
                    onComplete(respMessage.toMessageInfo())
                } else {
                    model.status = .sendSuccess
                    onComplete(model)
                }
            } onProgress: { (progress: Int) in
                print("sending message progress: \(progress)")
            } onFailure: { [weak self] (errCode: Int, msg: String?) in
                print("send message error:", msg)
                var customMessage: MessageInfo?
                
                if conversationType == .c2c {
                    if errCode == SDKError.blockedByFriend.rawValue {
                        customMessage = self?.createCustomMessage(customType: .blockedByFriend, data: [:])
                    } else if errCode == SDKError.deletedByFriend.rawValue {
                        customMessage = self?.createCustomMessage(customType: .deletedByFriend, data: [:])
                    }
                }
                model.status = .sendFailure
                onComplete(model)
                
                if customMessage != nil {
                    Self.shared.imManager.insertSingleMessage(toLocalStorage: customMessage!.toOIMMessageInfo(), recvID: recvID, sendID: model.sendID, onSuccess: nil, onFailure: nil)
                    customMessage?.recvID = recvID
                    print("type:\(customMessage?.customElem?.type)")
                    onComplete(customMessage!)
                }
            }
        }
        
        if conversationType == .superGroup {
            Self.shared.imManager.sendMessage(message, recvID: nil, groupID: recvID, offlinePushInfo: message.offlinePush) { (newMessage: OIMMessageInfo?) in
                if let respMessage = newMessage {
                    onComplete(respMessage.toMessageInfo())
                } else {
                    model.status = .sendSuccess
                    onComplete(model)
                }
            } onProgress: { (progress: Int) in
                print("sending message progress: \(progress)")
            } onFailure: { (_: Int, msg: String?) in
                print("send message error:", msg)
                model.status = .sendFailure
                onComplete(model)
            }
        }
    }
    
    private func sendOIMMessage(message: OIMMessageInfo,
                                to recvID: String,
                                conversationType: ConversationType,
                                onComplete: @escaping CallBack.MessageReturnVoid) {
        
        let model = message.toMessageInfo()
        
        if let desc = model.offlinePushInfo.desc, desc.isEmpty {
            let push = OfflinePushInfo()
            push.title = "You received a message"
            push.desc = "You received a message"
            message.offlinePush = push.toOIMOfflinePushInfo()
        }
        
        model.isRead = false
        sendHelper(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func sendTextMessage(text: String,
                                quoteMessage: MessageInfo? = nil,
                                to recvID: String,
                                conversationType: ConversationType,
                                sending: CallBack.MessageReturnVoid,
                                onComplete: @escaping CallBack.MessageReturnVoid) {
        let message: OIMMessageInfo
        if let quoteMessage = quoteMessage {
            let quote = quoteMessage.toOIMMessageInfo()
            message = OIMMessageInfo.createQuoteMessage(text, message: quote)
        } else {
            message = OIMMessageInfo.createTextMessage(text)
        }
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func createAtAllFlag(displayText: String) -> AtInfo {
        let all = OIMMessageInfo.create(atAllFlag: displayText)
        
        return all.toAtInfo()
    }
    
    public func sendImageMessage(path: String,
                                 to recvID: String,
                                 conversationType: ConversationType,
                                 sending: CallBack.MessageReturnVoid,
                                 onComplete: @escaping CallBack.MessageReturnVoid) {
        
        let message = OIMMessageInfo.createImageMessage(path)
        message.status = .sending
        sending(message.toMessageInfo())
        sendOIMMessage(message: message, to: recvID, conversationType: conversationType, onComplete: onComplete)
    }
    
    public func createCustomMessage(customType: CustomMessageType, data: [String: Any]) -> MessageInfo {
        let dataStr = String.init(data: try! JSONSerialization.data(withJSONObject: ["customType": customType.rawValue,
                                                                                     "data": data]),
                                  encoding: .utf8)!
        return OIMMessageInfo.createCustomMessage(dataStr, extension: nil, description: nil).toMessageInfo()
    }
    
    public func markMessageAsReaded(byConID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: CallBack.ErrorOptionalReturnVoid? = nil) {
        iLogger.print("\(type(of: self)): \(#function) [\(#line)]")
        Self.shared.imManager.markConversationMessage(asRead: byConID, onSuccess: { r in
            onSuccess(r)
        }) { code, msg in
            print("\(#function) throw error:\(code), \(msg)")
            onFailure?(code, msg)
        }
    }
    
    public func createGroupConversation(users: [UserInfo], groupType: GroupType = .normal, groupName: String, avatar: String? = nil, onSuccess: @escaping CallBack.GroupInfoOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        
        let nickname = currentUserRelay.value?.nickname
        
        let groupInfo = OIMGroupBaseInfo()
        groupInfo.groupName = groupName
        groupInfo.groupType = OIMGroupType(rawValue: groupType.rawValue) ?? .working
        groupInfo.faceURL = avatar
        
        let createInfo = OIMGroupCreateInfo()
        createInfo.memberUserIDs = users.compactMap({ $0.userID.isEmpty ? nil : $0.userID })
        createInfo.groupInfo = groupInfo
        
        Self.shared.imManager.createGroup(createInfo) { (groupInfo: OIMGroupInfo?) in
            onSuccess(groupInfo?.toGroupInfo())
        } onFailure: { code, msg in
            print("\(#function) throw error:\(code), \(msg)")
            onFailure(code, msg)
        }
    }
    
    public func clearC2CHistoryMessages(conversationID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.clearConversationAndDeleteAllMsg(conversationID) { r in
            onSuccess(r)
        } onFailure: { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func clearGroupHistoryMessages(conversationID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.clearConversationAndDeleteAllMsg(conversationID) { r in
            onSuccess(r)
        } onFailure: { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func deleteAllMsgFromLocalAndSvr(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.deleteAllMsgFromLocalAndSvrWith(onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
            onSuccess(nil)
        }
    }
    
    public func uploadFile(fullPath: String, onProgress: @escaping CallBack.ProgressReturnVoid, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        
        Self.shared.imManager.uploadFile(fullPath,
                                         name: nil,
                                         cause: nil) { save, current, total in
            let p = CGFloat(current) / CGFloat(save)
            onProgress(p)
        } onCompletion: { c, u, t  in
            
        } onSuccess: { r in
            let dic = try! JSONSerialization.jsonObject(with: r!.data(using: .utf8)!, options: .allowFragments) as! [String: Any]
            
            onSuccess(dic["url"] as! String)
        } onFailure: { code, msg in
            onSuccess(nil)
            print("\(code), \(msg)")
        }
    }
    
    public func searchRecord(param: SearchParam, onSuccess: @escaping CallBack.SearchResultInfoOptionalReturnVoid) {
        Self.shared.imManager.searchLocalMessages(param.toOIMSearchParam()) { (result: OIMSearchResultInfo?) in
            onSuccess(result?.toSearchResultInfo())
        }
    }
    
    public func searchGroups(param: SearchGroupParam, onSuccess: @escaping CallBack.GroupInfosReturnVoid) {
        Self.shared.imManager.searchGroups(param.toOIMSearchGroupParam()) { result in
            
            let arr = result?.compactMap { $0.toGroupInfo() } ?? []
            onSuccess(arr)
        }
    }
    
    public func searchFriends(param: SearchUserParam, onSuccess: @escaping CallBack.SearchUsersInfoOptionalReturnVoid) {
        Self.shared.imManager.searchFriends(param.toOIMSearchUserParam()) { result in
            
            let arr = result?.compactMap { $0.toSearchFriendsInfo() } ?? []
            onSuccess(arr)
        }
    }
    
    public func searchGroupMembers(param: SearchGroupMemberParam) async throws -> [GroupMemberInfo] {
        return try await withCheckedThrowingContinuation { continuation in
            Self.shared.imManager.searchGroupMembers(param.toOIMSearchGroupMemberParam()) { infos in
                let r = infos?.compactMap({ $0.toGroupMemberInfo() }) ?? []
                
                continuation.resume(returning: r)
            } onFailure: { code, msg in
                continuation.resume(throwing: NSError(domain: msg ?? "", code: code))
            }
        }
    }
    
    public func insertCustomMessage(conversationType: ConversationType,
                                    msg: MessageInfo,
                                    recvID: String,
                                    onSuccess: @escaping CallBack.MessageReturnVoid) {
        
        if conversationType == .c2c {
            Self.shared.imManager.insertSingleMessage(toLocalStorage: msg.toOIMMessageInfo(),
                                                      recvID: recvID,
                                                      sendID: getLoginUserID(),
                                                      onSuccess: { message in
                onSuccess(message!.toMessageInfo())
            }) { code, msg in
                
                print("\(code), \(msg)")
            }
        } else {
            Self.shared.imManager.insertGroupMessage(toLocalStorage: msg.toOIMMessageInfo(),
                                                     groupID: recvID,
                                                     sendID: getLoginUserID(),
                                                     onSuccess: { message in
                onSuccess(message!.toMessageInfo())
            }) { code, msg in
                print("\(code), \(msg)")
            }
        }
    }
    
    public func getGroupMessageReaderList(conversationID: String, clientMsgID: String, filter: Int = 0, offset: Int = 0, count: Int = 20, onSuccess: @escaping CallBack.GroupMembersReturnVoid) {
    }
    
    public func sendGroupMessageReadReceipt(conversationID: String, clientMsgIDs: [String], onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
    }
    
    public func searchLocalMessages(conversationID: String, messageTypes:[MessageContentType], onSuccess: @escaping CallBack.MessagesReturnVoid) {
        let param = OIMSearchParam()
        param.conversationID = conversationID
        param.messageTypeList = messageTypes.flatMap({ OIMMessageContentType(rawValue: $0.rawValue)?.rawValue })
        param.count = 1000
        param.pageIndex = 1
        
        Self.shared.imManager.searchLocalMessages(param) { r in
            let result = r?.searchResultItems.flatMap({ $0.messageList.flatMap({ $0.toMessageInfo() }) }) ?? []
            
            onSuccess(result)
        }
    }
    
    public func setMessageLocalEx(conversationID: String, clientMsgID: String, ex: String) {
        Self.shared.imManager.setMessageLocalEx(conversationID, clientMsgID: clientMsgID, localEx: ex) { r in
            print("\(#function) success:\(r)")
        } onFailure: { code, msg in
            print("\(#function) throw error:\(code), \(msg)")
        }
    }
}


extension IMController {
    
    public func getConversation(sessionType: ConversationType = .undefine, sourceId: String = "", conversationID: String = "", onSuccess: @escaping CallBack.ConversationInfoOptionalReturnVoid) {
        
        if !conversationID.isEmpty {
            
            Self.shared.imManager.getMultipleConversation([conversationID]) { conversations in
                onSuccess(conversations?.first?.toConversationInfo())
            } onFailure: { code, msg in
                print("\(code), .msg:\(msg)")
            }
            
        } else {
            
            let conversationType = OIMConversationType(rawValue: sessionType.rawValue) ?? OIMConversationType.undefine
            
            Self.shared.imManager.getOneConversation(withSessionType: conversationType, sourceID: sourceId) { (conversation: OIMConversationInfo?) in
                onSuccess(conversation?.toConversationInfo())
            } onFailure: { code, msg in
                print("\(code), .msg:\(msg)")
            }
        }
    }
    
    
    public func setGlobalRecvMessageOpt(op: ReceiveMessageOpt, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        let opt = OIMReceiveMessageOpt(rawValue: op.rawValue) ?? OIMReceiveMessageOpt.receive
        Self.shared.imManager.setGlobalRecvMessageOpt(opt.rawValue, onSuccess: onSuccess) { code, msg in
            print("\(code), .msg:\(msg)")
        }
    }
    
    public func setOneConversationPrivateChat(conversationID: String, isPrivate: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        
        Self.shared.imManager.setConversationPrivateChat(conversationID, isPrivate: isPrivate, onSuccess: onSuccess) { code, msg in
            print("\(code), .msg:\(msg)")
            onSuccess(nil)
        }
    }
    
    public func setBurnDuration(conversationID: String, burnDuration: Int, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setConversationBurnDuration(conversationID, duration: burnDuration, onSuccess: onSuccess) { code, msg in
            print("\(#function) throw error: \(code) \(msg)")
            onSuccess(nil)
        }
    }
    
    public func saveDraft(conversationID: String, text: String?) {
        Self.shared.imManager.setConversationDraft(conversationID, draftText: text ?? "") { r in
            
        } onFailure: { code, msg in
            print("\(code), .msg:\(msg)")
        }
    }
    
    public func resetConversationGroupAtType(conversationID: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.resetConversationGroup(atType: conversationID, onSuccess: onSuccess) { code, msg in
            print("\(#function) throw error:\(code), .msg:\(msg)")
        }
    }
    
    public func setRegularlyDelete(conversationID: String, isMsgDestruct: Bool, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
#if ENABLE_MOMENTS || ENABLE_CALL
        Self.shared.imManager.setConversationIsMsgDestruct(conversationID, isMsgDestruct: isMsgDestruct, onSuccess: onSuccess) { code, msg in
            print("\(code), .msg:\(msg)")
            onSuccess(nil)
        }
#endif
    }
    
    public func setRegularlyDuration(conversationID: String, duration: Int, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
#if ENABLE_MOMENTS || ENABLE_CALL
        Self.shared.imManager.setConversationMsgDestructTime(conversationID, msgDestructTime: duration, onSuccess: onSuccess) { code, msg in
            print("\(code), .msg:\(msg)")
            onSuccess(nil)
        }
#endif
    }
    
    public func searchConversations(keywords: String) async -> [ConversationInfo] {
        return await withCheckedContinuation { continuation in
            Self.shared.imManager.searchConversation(keywords) { infos in
                let res = infos?.compactMap({ $0.toConversationInfo() }) ?? []
                
                continuation.resume(returning: res)
            } onFailure: { code, errStr in
                continuation.resume(returning: [])
            }
        }
    }
}


extension IMController {

    public func getSelfInfo(onSuccess: @escaping CallBack.UserInfoOptionalReturnVoid) {
        guard Self.shared.imManager.getLoginStatus() == .logged else { return }
        
        Self.shared.imManager.getSelfInfoWith { [weak self] (userInfo: OIMUserInfo?) in
            let user = userInfo?.toUserInfo()
            self?.currentUserRelay.accept(user)
            onSuccess(user)
        } onFailure: { code, msg in
            print("\(code), msg:\(msg)")
        }
    }
    
    public func getUserInfo(uids: [String], groupID: String? = nil, onSuccess: @escaping CallBack.PublicUserInfosReturnVoid) {
        Self.shared.imManager.getUsersInfo(withCache: uids, groupID: groupID) { userInfos in
            let users = userInfos?.compactMap { $0.toPublicUserInfo() } ?? []
            onSuccess(users)
        } onFailure: { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func setSelfInfo(userInfo: UserInfo, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.setSelfInfo(userInfo.toOIMUserInfo(), onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func logout(onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.logoutWith(onSuccess: onSuccess) { code, msg in
            print("\(code), \(msg)")
        }
    }
    
    public func loginStatus() -> Int {
        imManager.getLoginStatus().rawValue
    }
    
    public func getLoginUserID() -> String {
        return imManager.getLoginUserID()
    }
    
    public func subscribeUsersStatus(userIDs: [String], onSuccess: @escaping CallBack.UserStatusInfoReturnVoid) {
        Self.shared.imManager.subscribeUsersStatus(userIDs) { r in
            let status = (r?.compactMap({ $0.toUserStatusInfo() })) ?? []
            onSuccess(status)
        } onFailure: { code, msg in
            print("\(#function):\(code), \(msg)")
        }
    }
    
    public func unsubscribeUsersStatus(userIDs: [String], onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        Self.shared.imManager.unsubscribeUsersStatus(userIDs) { r in
            onSuccess(r)
        } onFailure: { code, msg in
            print("\(#function):\(code), \(msg)")
        }
    }
    
    public func uploadLogs(line: Int = 0, onProgress: @escaping CallBack.ProgressReturnVoid, onSuccess: @escaping CallBack.StringOptionalReturnVoid, onFailure: @escaping CallBack.ErrorOptionalReturnVoid) {
        Self.shared.imManager.uploadLogs(progress: { _, current, total in
            onProgress(CGFloat(current) / CGFloat(total))
        }, line: line, ex: "", onSuccess: onSuccess, onFailure: onFailure)
    }
    
    public func logs(fileName: String? = nil, line: Int = 0, msgs: String? = nil, err: String? = nil, keyAndValues: [Any] = []) async {
        await withCheckedContinuation { continuation in
            Self.shared.imManager.logs(fileName, line: line, msgs: msgs, err: err, keyAndValues: keyAndValues, logLevel: 5)
            continuation.resume(returning: Void())
        }
    }
}


extension IMController: OIMFriendshipListener {
    @objc public func onFriendApplicationAdded(_ application: OIMFriendApplication) {
        friendApplicationChangedSubject.onNext(application.toFriendApplication())
    }
    
    public func onFriendApplicationRejected(_ application: OIMFriendApplication) {
        friendApplicationChangedSubject.onNext(application.toFriendApplication())
    }
    
    public func onFriendApplicationAccepted(_ application: OIMFriendApplication) {
        friendApplicationChangedSubject.onNext(application.toFriendApplication())
    }
    
    @objc public func onFriendInfoChanged(_ info: OIMFriendInfo) {
        updateFrequentUser(ContactInfo(ID: info.userID, name: info.nickname, faceURL: info.faceURL))
        friendInfoChangedSubject.onNext(info.toFriendInfo())
    }
    
    public func onBlackAdded(_ info: OIMBlackInfo) {
        onBlackAddedSubject.onNext(info.toBlackInfo())
    }
    
    public func onBlackDeleted(_ info: OIMBlackInfo) {
        onBlackDeletedSubject.onNext(info.toBlackInfo())
    }
    
    public func onFriendAdded(_ info: OIMFriendInfo) {
        addFriendSubject.onNext(info.toFriendInfo())
    }
    
    public func onFriendDeleted(_ info: OIMFriendInfo) {
        deleteFriendSubject.onNext(info.toFriendInfo())
    }
}


extension IMController: OIMGroupListener {
    public func onGroupApplicationAdded(_ groupApplication: OIMGroupApplicationInfo) {
        groupApplicationChangedSubject.onNext(groupApplication.toGroupApplicationInfo())
    }
    
    public func onGroupApplicationRejected(_ groupApplication: OIMGroupApplicationInfo) {
        groupApplicationChangedSubject.onNext(groupApplication.toGroupApplicationInfo())
    }
    
    public func onGroupApplicationAccepted(_ groupApplication: OIMGroupApplicationInfo) {
        groupApplicationChangedSubject.onNext(groupApplication.toGroupApplicationInfo())
    }
    
    public func onGroupInfoChanged(_ changeInfo: OIMGroupInfo) {
        groupInfoChangedSubject.onNext(changeInfo.toGroupInfo())
    }
    
    public func onGroupMemberInfoChanged(_ changeInfo: OIMGroupMemberInfo) {
        groupMemberInfoChange.onNext(changeInfo.toGroupMemberInfo())
    }
    
    public func onJoinedGroupAdded(_ groupInfo: OIMGroupInfo) {
        joinedGroupAdded.onNext(groupInfo.toGroupInfo())
        
    }
    
    public func onJoinedGroupDeleted(_ groupInfo: OIMGroupInfo) {
        joinedGroupDeleted.onNext(groupInfo.toGroupInfo())
    }
    
    public func onGroupMemberAdded(_ memberInfo: OIMGroupMemberInfo) {
        groupMemberAdded.onNext(memberInfo.toGroupMemberInfo())
    }
    
    public func onGroupMemberDeleted(_ memberInfo: OIMGroupMemberInfo) {
        groupMemberDeleted.onNext(memberInfo.toGroupMemberInfo())
    }
}


extension IMController: OIMConversationListener {
    public func onConversationChanged(_ conversations: [OIMConversationInfo]) {
        let conversations: [ConversationInfo] = conversations.compactMap {
            $0.toConversationInfo()
        }
        conversationChangedSubject.onNext(conversations)
        let totalUnreadCount = conversations.reduce(0) { $0 + $1.unreadCount }
        UIApplication.shared.applicationIconBadgeNumber = totalUnreadCount
    }
    
    public func onSyncServerStart(_ reInstall: Bool) {
        connectionRelay.accept((status: .syncStart, reInstall: reInstall, progress: nil))
    }
    
    public func onSyncServerFinish(_ reInstall: Bool) {
        connectionRelay.accept((status: .syncComplete, reInstall: reInstall, progress: nil))
    }
    
    public func onSyncServerFailed(_ reInstall: Bool) {
        connectionRelay.accept((status: .syncFailure, reInstall: reInstall, progress: nil))
    }
    
    public func onSyncServerProgress(_ progress: Int) {
        connectionRelay.accept((status: .syncProgress, reInstall: nil, progress: progress))
    }
    
    public func onNewConversation(_ conversations: [OIMConversationInfo]) {
        
        let arr = conversations.compactMap { $0.toConversationInfo() }
        newConversationSubject.onNext(arr)
    }
    
    public func onTotalUnreadMessageCountChanged(_ totalUnreadCount: Int) {
        totalUnreadSubject.onNext(totalUnreadCount)
    }
    
    public func onConversationUserInputStatusChanged(_ inputStatusChangedData: OIMInputStatusChangedData) {
        inputStatusChangedSubject.onNext(inputStatusChangedData.toInputStatusChangedData())
    }
}


extension IMController: OIMAdvancedMsgListener {
    public func onRecvNewMessage(_ msg: OIMMessageInfo) {
        iLogger.print("\(#function): \(msg.senderNickname): \(msg.clientMsgID)")
        
        if msg.contentType.rawValue < 1000,
           msg.contentType != .typing,
           msg.contentType != .revoke,
           msg.contentType != .hasReadReceipt,
           msg.contentType != .groupHasReadReceipt {
            Self.shared.imManager.getOneConversation(withSessionType: msg.sessionType,
                                                     sourceID: msg.sessionType == .superGroup ? msg.groupID! : msg.sendID!,
                                                     onSuccess: { conversation in
                
                if conversation!.conversationID != self.chatingConversationID,
                   conversation!.unreadCount > 0,
                   conversation!.recvMsgOpt == .receive {
                    
                    self.ringAndVibrate()
                }
            })
        }
        newMsgReceivedSubject.onNext(msg.toMessageInfo())
    }
    
    public func onRecvC2CReadReceipt(_ receiptList: [OIMReceiptInfo]) {
        c2cReadReceiptReceived.onNext(receiptList.compactMap { $0.toReceiptInfo() })
    }
    
    public func onRecvMessageRevoked(_ messageRevoked: OIMMessageRevokedInfo) {
        msgRevokeReceived.onNext(messageRevoked.toMessageRevoked())
    }
    
    public func onRecvOnlineOnlyMessage(_ message: OIMMessageInfo) {
        recvOnlineMesssage.onNext(message.toMessageInfo())
    }
}

extension IMController: OIMCustomBusinessListener {
    public func onRecvCustomBusinessMessage(_ businessMessage: [String : Any]?) {
        if let json = businessMessage?["data"] as? String {
            do {
                let obj = try? JSONSerialization.jsonObject(with: json.data(using: .utf8)!, options: .fragmentsAllowed) as? [String: Any]
                customBusinessSubject.onNext(obj?["body"] as? [String: Any])
            } catch (let e) {
                print("onRecvCustomBusinessMessage - catch \(e)")
            }
        }
        
    }
}

extension IMController: OIMUserListener {
    public func onUserStatusChanged(_ info: OIMUserStatusInfo) {
        let status = info.toUserStatusInfo()
        userStatusSubject.onNext(status)
    }
    
    public func onSelfInfoUpdated(_ info: OIMUserInfo) {
        let user = info.toUserInfo()
        currentUserRelay.accept(user)
    }
}



public class UserInfo: Codable {
    public var userID: String!
    public var nickname: String?
    public var remark: String?
    public var faceURL: String?
    public var gender: Gender?
    public var phoneNumber: String?
    public var birth: Int?
    public var email: String?
    public var createTime: Int = 0
    public var landline: String? 
    public var ex: String?
    public var globalRecvMsgOpt: ReceiveMessageOpt = .receive

    public var forbidden: Int?
    public var allowAddFriend: Int?
    
    public init(userID: String,
                nickname: String? = nil,
                remark: String? = nil,
                phoneNumber: String? = nil,
                email: String? = nil,
                faceURL: String? = nil,
                birth: Int? = nil,
                gender: Gender? = nil,
                landline: String? = nil,
                forbidden: Int? = nil,
                allowAddFriend: Int? = nil) {
        self.userID = userID
        self.nickname = nickname
        self.remark = remark
        self.phoneNumber = phoneNumber
        self.email = email
        self.faceURL = faceURL
        self.birth = birth
        self.gender = gender
        self.landline = landline
        self.forbidden = forbidden
        self.allowAddFriend = allowAddFriend
    }

    public var isSelected: Bool = false
}

public class FriendApplication {
    public var fromUserID: String = ""
    public var fromNickname: String?
    public var fromFaceURL: String?
    public var toUserID: String = ""
    public var toNickname: String?
    public var toFaceURL: String?
    public var handleResult: ApplicationStatus = .normal
    public var reqMsg: String?
    public var handlerUserID: String?
    public var handleMsg: String?
    public var handleTime: Int = 0
    public var createTime: Int = 0
}

public class GroupApplicationInfo {
    public var groupID: String = ""
    public var groupName: String?
    public var groupFaceURL: String?
    public var creatorUserID: String = ""
    public var ownerUserID: String = ""
    public var memberCount: Int = 0
    public var userID: String?
    public var nickname: String?
    public var userFaceURL: String?
    public var reqMsg: String?
    public var reqTime: Int?
    public var handleUserID: String?
    public var handledMsg: String?
    public var handledTime: Int?
    public var handleResult: ApplicationStatus = .normal
    public var joinSource: JoinSource = .search
    public var inviterUserID: String?
}

public enum ApplicationStatus: Int {

    case decline = -1

    case normal = 0

    case accept = 1
}

public enum ReceiveMessageOpt: Int, Codable {

    case receive = 0

    case notReceive = 1

    case notNotify = 2
}

public class ConversationInfo: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case latestMsg
        case conversationID
        case userID
        case groupID
        case showName
        case faceURL
        case recvMsgOpt
        case unreadCount
        case conversationType
        case latestMsgSendTime
        case draftText
        case draftTextTime
        case isPinned
        case groupAtType
        case ex
        case isPrivateChat
        case burnDuration
        case isMsgDestruct
        case msgDestructTime
        case isNotInGroup
    }
    
    public let conversationID: String
    public var userID: String?
    public var groupID: String?
    public var showName: String?
    public var faceURL: String?
    public var recvMsgOpt: ReceiveMessageOpt = .receive
    public var unreadCount: Int = 0
    public var conversationType: ConversationType = .c2c
    public var latestMsgSendTime: Int = 0
    public var draftText: String?
    public var draftTextTime: Int = 0
    public var isPinned: Bool = false
    public var latestMsg: MessageInfo?
    public var groupAtType: GroupAtType = .normal
    public var ex: String?
    public var isPrivateChat: Bool = false
    public var burnDuration: Double = 30
    public var isMsgDestruct: Bool = false
    public var msgDestructTime: Double = 0
    public var isNotInGroup: Bool = true

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conversationID = try container.decode(String.self, forKey: .conversationID)
        userID = try? container.decode(String.self, forKey: .userID)
        groupID = try? container.decode(String.self, forKey: .groupID)
        showName = try? container.decode(String.self, forKey: .showName)
        faceURL = try? container.decode(String.self, forKey: .faceURL)
        recvMsgOpt = try container.decode(ReceiveMessageOpt.self, forKey: .recvMsgOpt)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        conversationType = try container.decode(ConversationType.self, forKey: .conversationType)
        latestMsgSendTime = try container.decode(Int.self, forKey: .latestMsgSendTime)
        draftText = try? container.decode(String.self, forKey: .draftText)
        draftTextTime = try container.decode(Int.self, forKey: .draftTextTime)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        latestMsg = try? container.decode(MessageInfo.self, forKey: .latestMsg)
        groupAtType = try container.decode(GroupAtType.self, forKey: .groupAtType)
        ex = try? container.decode(String.self, forKey: .ex)
        isPrivateChat = try container.decode(Bool.self, forKey: .isPrivateChat)
        burnDuration = try container.decode(Double.self, forKey: .burnDuration)
        isMsgDestruct = try container.decode(Bool.self, forKey: .isMsgDestruct)
        msgDestructTime = try container.decode(Double.self, forKey: .msgDestructTime)
        isNotInGroup = try container.decode(Bool.self, forKey: .isNotInGroup)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conversationID, forKey: .conversationID)
        try container.encodeIfPresent(userID, forKey: .userID)
        try container.encodeIfPresent(groupID, forKey: .groupID)
        try container.encodeIfPresent(showName, forKey: .showName)
        try container.encodeIfPresent(faceURL, forKey: .faceURL)
        try container.encode(recvMsgOpt, forKey: .recvMsgOpt)
        try container.encode(unreadCount, forKey: .unreadCount)
        try container.encode(conversationType, forKey: .conversationType)
        try container.encode(latestMsgSendTime, forKey: .latestMsgSendTime)
        try container.encodeIfPresent(draftText, forKey: .draftText)
        try container.encode(draftTextTime, forKey: .draftTextTime)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encodeIfPresent(latestMsg, forKey: .latestMsg)
        try container.encode(groupAtType, forKey: .groupAtType)
        try container.encodeIfPresent(ex, forKey: .ex)
        try container.encode(isPrivateChat, forKey: .isPrivateChat)
        try container.encode(burnDuration, forKey: .burnDuration)
        try container.encode(isMsgDestruct, forKey: .isMsgDestruct)
        try container.encode(msgDestructTime, forKey: .msgDestructTime)
        try container.encode(isNotInGroup, forKey: .isNotInGroup)
    }
    
    public init(conversationID: String) {
        self.conversationID = conversationID
    }
}


open class MessageInfo: Codable {
    public var clientMsgID: String = ""
    public var serverMsgID: String?
    public var createTime: TimeInterval = 0
    public var sendTime: TimeInterval = 0
    public var sessionType: ConversationType = .c2c
    public var sendID: String = ""
    public var recvID: String?
    public var handleMsg: String?
    public var msgFrom: MessageLevel = .user
    public var contentType: MessageContentType = .unknown
    public var senderPlatformID: Int = 1
    public var senderNickname: String?
    public var senderFaceUrl: String?
    public var groupID: String?
    public var content: String?

    var seq: Int = 0
    public var isRead: Bool = false 
    public var status: MessageStatus = .undefine
    public var attachedInfo: String?
    public var ex: String?
    public var localEx: String?
    public var offlinePushInfo: OfflinePushInfo = .init()
    public var textElem: TextElem?
    public var pictureElem: PictureElem?
    public var soundElem: SoundElem?
    public var videoElem: VideoElem?
    public var fileElem: FileElem?
    public var mergeElem: MergeElem?
    public var atTextElem: AtTextElem?
    public var locationElem: LocationElem?
    public var quoteElem: QuoteElem?
    public var customElem: CustomElem?
    public var notificationElem: NotificationElem?
    public var faceElem: FaceElem?
    public var attachedInfoElem: AttachedInfoElem?

    public var cardElem: CardElem?
    public var typingElem: TypingElem?

    public var isPlaying = false
    public var isSelected = false
    public var isAnchor = false 
    
    public func isCalling() -> Bool {
        if let data = customElem?.data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            if let type = obj["customType"] as? Int, type == 901 {
                return true
            }
        }
        
        return false
    }
    
    public func isTyping() -> Bool {
        guard contentType == .typing else { return false }
        
        return typingElem?.msgTips == "yes"
    }
}

extension MessageInfo {
    public var revokedInfo: MessageRevoked {
        assert(contentType == .revoke)
        if let detail = notificationElem?.detail ?? content {
            return JsonTool.fromJson(detail, toClass: MessageRevoked.self) ?? MessageRevoked()
        }
        
        return MessageRevoked()
    }
    
    public var isMine: Bool {
        sendID == IMController.shared.uid
    }
}

public class GroupMemberBaseInfo: Codable {
    public var userID: String?
    public var roleLevel: GroupMemberRole = .member
}

public enum GroupMemberFilter: Int, Codable {
    case all = 0

    case owner = 1
    case admin = 2
    case member = 3
    case adminAndMember = 4
    case superAndAdmin = 5
}

public enum GroupMemberRole: Int, Codable {
    case owner  = 100
    case admin  = 60
    case member = 20
    case unkhown = 0
}

public class GroupMemberInfo: GroupMemberBaseInfo {
    
    private enum CodingKeys: String, CodingKey {
        case groupID
        case nickname
        case faceURL
        case joinTime
        case joinSource
        case operatorUserID
        case inviterUserID
        case muteEndTime
        case ex
    }
    
    public var groupID: String?
    public var nickname: String?
    public var faceURL: String?
    public var joinTime: Int = 0
    public var joinSource: JoinSource = .search
    public var operatorUserID: String?
    public var inviterUserID: String?
    public var muteEndTime: Double = 0
    public var ex: String?
    
    public override init() {
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.groupID = try container.decode(String.self, forKey: .groupID)
        self.nickname = try container.decode(String.self, forKey: .nickname)
        self.faceURL = try container.decode(String.self, forKey: .faceURL)
        self.joinTime = try container.decode(Int.self, forKey: .joinTime)
        self.joinSource = try container.decode(JoinSource.self, forKey: .joinSource)
        self.operatorUserID = try container.decode(String.self, forKey: .operatorUserID)
        self.inviterUserID = try container.decode(String.self, forKey: .inviterUserID)
        self.muteEndTime = try container.decode(Double.self, forKey: .muteEndTime)
        self.ex = try container.decode(String.self, forKey: .ex)
        
        try super.init(from: decoder)
    }

    public var inviterUserName: String?
}

public class UserStatusInfo: Decodable {
    public var userID: String = ""
    public var status: Int = 0
    public var platformIDs: [Int]?
    
    public init() {
        
    }
}

public class InputStatusChangedData: Decodable {
    public var conversationID: String = ""
    public var userID: String = ""
    public var platformIDs: [Int]?
}

public enum MessageContentType: Int, Codable {
    case unknown = -1

    
    case text = 101
    case image
    case audio
    case video
    case file

    case at

    case merge

    case card
    case location
    case custom = 110
    case typing = 113
    case quote = 114

    case face = 115
    case advancedText = 117
    case reactionMessageModifier = 121
    case reactionMessageDeleter = 122

    
    case friendAppApproved = 1201
    case friendAppRejected
    case friendApplication
    case friendAdded
    case friendDeleted

    case friendRemarkSet
    case blackAdded
    case blackDeleted

    case conversationOptChange = 1300
    case userInfoUpdated = 1303

    case conversationNotification = 1307

    case conversationNotNotification

    case oaNotification = 1400
    case groupCreated = 1501

    case groupInfoSet
    case joinGroupApplication
    case memberQuit
    case groupAppAccepted
    case groupAppRejected

    case groupOwnerTransferred
    case memberKicked
    case memberInvited
    case memberEnter

    case dismissGroup

    case groupMemberMuted = 1512

    case groupMemberCancelMuted = 1513

    case groupMuted = 1514

    case groupCancelMuted = 1515
    
    case groupMemberInfoSet = 1516
    case groupAnnouncement = 1519
    case groupSetName = 1520

    case privateMessage = 1701
    case business = 2001
    case revoke = 2101

    case hasReadReceipt = 2150

    case groupHasReadReceipt = 2155
}

public enum MessageStatus: Int, Codable {
    case undefine = 0
    case sending
    case sendSuccess
    case sendFailure
    case deleted
    case revoke
}

public enum MessageLevel: Int, Codable {
    case undefine = -1
    case user = 100
    case system = 200
}

public enum ConversationType: Int, Codable {

    case undefine = 0

    case c2c = 1

    case superGroup = 3

    case notification = 4
}

public enum GroupAtType: Int, Codable {
    case normal = 0
    case atMe = 1
    case atAll = 2
    case atAllAtMe = 3
    case announcement = 4
}

public enum GroupType: Int, Codable {
    case normal = 0
    case `super` = 1
    case working = 2
}

public enum GroupStatus: Int, Codable {
    case ok = 0
    case beBan = 1
    case dismissed = 2
    case muted = 3
}

public enum JoinSource: Int, Codable {
    case invited = 2 
    case search = 3 
    case QRCode = 4 
}

public enum GroupVerificationType: Int, Codable {
    case applyNeedVerificationInviteDirectly = 0 
    case allNeedVerification = 1 
    case directly = 2 
    
}

public class GroupBaseInfo: Codable {
    public var groupName: String?
    public var introduction: String?
    public var notification: String?
    public var faceURL: String?
}

public class GroupInfo: GroupBaseInfo {
    public var groupID: String = ""
    public var ownerUserID: String?
    public var createTime: Int = 0
    public var memberCount: Int = 0
    public var creatorUserID: String?
    public var groupType: GroupType = .working
    public var status: GroupStatus = .ok
    public var needVerification: GroupVerificationType = .applyNeedVerificationInviteDirectly
    public var lookMemberInfo: Int = 0
    public var applyMemberFriend: Int = 0
    public var notificationUpdateTime: Int = 0
    public var notificationUserID: String?
    public var displayIsRead: Bool = false
    public var ex: String?
    
    public var isMine: Bool {
        return ownerUserID == IMController.shared.uid
    }
    
    public init(groupID: String = "", groupName: String? = nil) {
        super.init()
        self.groupID = groupID
        self.groupName = groupName
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

public class ConversationNotDisturbInfo {
    public  let conversationId: String
    public var result: ReceiveMessageOpt = .receive
    init(conversationId: String) {
        self.conversationId = conversationId
    }
}


public class FaceElem: Codable {
    public var index: Int = 0
    public var data: String?
}

public class AttachedInfoElem: Codable {
    public var groupHasReadInfo: GroupHasReadInfo?
    public var isPrivateChat: Bool = false
    public var burnDuration: Double = 30
    public var hasReadTime: Double = 0
}

public class GroupHasReadInfo: Codable {
    public var hasReadCount: Int = 0
    public var unreadCount: Int = 0
}

public class NotificationElem: Codable {
    public var detail: String?
    
    private(set) var opUser: GroupMemberInfo?
    private(set) var quitUser: GroupMemberInfo?
    private(set) var entrantUser: GroupMemberInfo?

    private(set) var groupNewOwner: GroupMemberInfo?
    public private(set) var group: GroupInfo?
    private(set) var kickedUserList: [GroupMemberInfo]?
    private(set) var invitedUserList: [GroupMemberInfo]?
    init(opUser: GroupMemberInfo?, quitUser: GroupMemberInfo?, entrantUser: GroupMemberInfo?, groupNewOwner: GroupMemberInfo?, group: GroupInfo?, kickedUserList: [GroupMemberInfo]?, invitedUserList: [GroupMemberInfo]?) {
        self.opUser = opUser
        self.quitUser = quitUser
        self.entrantUser = entrantUser
        self.groupNewOwner = groupNewOwner
        self.group = group
        self.kickedUserList = kickedUserList
        self.invitedUserList = invitedUserList
    }
    public var detailObject: [String: Any] {
        guard let detail else {
            return [:]
        }
        
        if let obj = try? JSONSerialization.jsonObject(with: detail.data(using: .utf8)!) as? [String : Any] {
            return obj
        }
        
        return [:]
    }
}

public class OfflinePushInfo: Codable {
    public var title: String?
    public var desc: String?
    public var iOSPushSound: String?
    public var iOSBadgeCount: Bool = false
    public var operatorUserID: String?
    public var ex: String?
}

public class TextElem: Codable {
    public var content: String!
}

public class CardElem: Codable {
    public var userID: String!
    public var nickname: String!
    public var faceURL: String?
    public var ex: String?
    
    public init(userID: String, nickname: String, faceURL: String?) {
        self.userID = userID
        self.nickname = nickname
        self.faceURL = faceURL
    }
}

public class TypingElem: Codable {
    public var msgTips: String?
}

public class PictureElem: Codable {

    public var sourcePath: String?

    public var sourcePicture: PictureInfo?

    public var bigPicture: PictureInfo?

    public var snapshotPicture: PictureInfo?
}

public class PictureInfo: Codable {
    public var uuID: String?
    public var type: String?
    public var size: Int = 0
    public var width: CGFloat = 0
    public var height: CGFloat = 0

    public var url: String?
}

public class SoundElem: Codable {
    public var uuID: String?

    public var soundPath: String?

    public var sourceUrl: String?
    public var dataSize: Int = 0
    public var duration: Int = 0
}

public class VideoElem: Codable {
    public var videoUUID: String?
    public var videoPath: String?
    public var videoUrl: String?
    public var videoType: String?
    public var videoSize: Int = 0
    public var duration: Int = 0

    public var snapshotPath: String?

    public var snapshotUUID: String?
    public var snapshotSize: Int = 0

    public var snapshotUrl: String?
    public var snapshotWidth: CGFloat = 0
    public var snapshotHeight: CGFloat = 0
}

public class FileElem: Codable {
    public var filePath: String?
    public var uuID: String?

    public var sourceUrl: String?
    public var fileName: String?
    public var fileSize: Int = 0
}

public class MergeElem: Codable {
    public var title: String?
    public var abstractList: [String]?
    public var multiMessage: [MessageInfo]?
}

public class AtTextElem: Codable {
    public var text: String?
    public var atUserList: [String]?
    public var atUsersInfo: [AtInfo]?
    public var quoteMessage: MessageInfo?
    public var isAtSelf: Bool = false
}

public class AtInfo: Codable {
    public var atUserID: String?
    public var groupNickname: String?
    
    public init(atUserID: String, groupNickname: String) {
        self.atUserID = atUserID
        self.groupNickname = groupNickname
    }
}

public class LocationElem: Codable {
    public var desc: String?
    public var longitude: Double = 0
    public var latitude: Double = 0
}

public class QuoteElem: Codable {
    public var text: String?
    public var quoteMessage: MessageInfo?
}

public class CustomElem: Codable {
    public var data: String?
    public var ext: String?
    public var description: String?
    
    public func value() -> [String: Any]? {
        if let data = data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            return obj["data"] as? [String: Any]
        }
        
        return nil
    }
    
    public var type: CustomMessageType? {
        if let data = data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            let t = obj["customType"] as! Int
            
            return CustomMessageType.init(rawValue: t)
        }
        
        return nil
    }
}

public struct BusinessCard: Codable {
    public let faceURL: String?
    public let nickname: String?
    public let userID: String
    public init(faceURL: String?, nickname: String?, userID: String) {
        self.faceURL = faceURL
        self.nickname = nickname
        self.userID = userID
    }
}

public class ReceiptInfo {
    public var userID: String?
    public var groupID: String?

    public var msgIDList: [String]?
    public var readTime: Int = 0
    public var msgFrom: MessageLevel = .user
    public var contentType: MessageContentType = .hasReadReceipt
    public var sessionType: ConversationType = .undefine
}

public class GroupMessageReceipt {
    public var conversationID: String = ""
    public var groupMessageReadInfo: [GroupMessageReadInfo]?
}

public class GroupMessageReadInfo {
    public var clientMsgID: String = ""

    public var unreadCount: Int = 0
    public var hasReadCount: Int = 0
    public var readMembers: [GroupMemberInfo]?
}

public class MessageRevoked: Codable {
    public var revokerID: String?
    public var revokerNickname: String?
    public var revokerRole: GroupMemberRole = .member
    public var clientMsgID: String?
    public var revokeTime: Double = 0
    public var sourceMessageSendTime: Double = 0
    public var sourceMessageSendID: String?
    public var sourceMessageSenderNickname: String?
    public var sessionType: ConversationType = .c2c
    
    public init(revokerID: String? = nil, revokerNickname: String? = nil, revokerRole: GroupMemberRole = .member, clientMsgID: String? = nil, revokeTime: Double = 0, sourceMessageSendTime: Double = 0, sourceMessageSendID: String? = nil, sourceMessageSenderNickname: String? = nil, sessionType: ConversationType = .c2c) {
        self.revokerID = revokerID
        self.revokerNickname = revokerNickname
        self.revokerRole = revokerRole
        self.clientMsgID = clientMsgID
        self.revokeTime = revokeTime
        self.sourceMessageSendID = sourceMessageSendID
        self.sourceMessageSenderNickname = sourceMessageSenderNickname
        self.sessionType = sessionType
    }
}

extension MessageRevoked {
    public var revokerIsSelf: Bool {
        return revokerID == IMController.shared.uid
    }
    
    public var sourceMessageSendIDIsSelf: Bool {
        return sourceMessageSendID == IMController.shared.uid
    }
}

public enum Gender: Int, Codable {
    case undefine = 0
    case male = 1
    case female = 2
    
    public var description: String {
        switch self {
        case .male:
            return "man".innerLocalized()
        case .female:
            return "woman".innerLocalized()
        case .undefine:
            return "-".innerLocalized()
        }
    }
}

public enum Relationship: Int, Codable {
    case black = 0
    case friends = 1
}

public class PublicUserInfo: Encodable {
    public var userID: String?
    public var nickname: String?
    public var faceURL: String?
    public var gender: Gender = .male
    
    public init(userID: String? = nil, nickname: String? = nil, faceURL: String? = nil, gender: Gender = .male) {
        self.userID = userID
        self.nickname = nickname
        self.faceURL = faceURL
        self.gender = gender
    }
}

public class FriendInfo: PublicUserInfo {
    public var ownerUserID: String?
    public var remark: String?
    public var createTime: Int = 0
    public var addSource: Int = 0
    public var operatorUserID: String?
    public var phoneNumber: String?
    public var birth: Int = 0
    public var email: String?
    public var attachedInfo: String?
    public var ex: String?
    
    public func toUserInfo() -> UserInfo? {
        let json = JsonTool.toJson(fromObject: self)
        let obj = JsonTool.fromJson(json, toClass: UserInfo.self)
        return obj
    }
    
    public init(userID: String? = nil, nickname: String? = nil, faceURL: String? = nil, gender: Gender = .male, ownerUserID: String? = nil, remark: String? = nil, createTime: Int = 0, addSource: Int = 0, operatorUserID: String? = nil, phoneNumber: String? = nil, birth: Int = 0, email: String? = nil, attachedInfo: String? = nil, ex: String? = nil) {
        super.init(userID: userID, nickname: nickname, faceURL: faceURL)
        
        self.ownerUserID = ownerUserID
        self.remark = remark
        self.createTime = createTime
        self.addSource = addSource
        self.operatorUserID = operatorUserID
        self.phoneNumber = phoneNumber
        self.birth = birth
        self.email = email
        self.attachedInfo = attachedInfo
        self.ex = ex
    }
}

public class BlackInfo: PublicUserInfo {
    public var operatorUserID: String?
    public var createTime: Int = 0
    public var addSource: Int = 0
    public var attachedInfo: String?
    public var ex: String?
}

public class SearchParam {
    public var conversationID: String = ""
    public var keywordList: [String] = []
    public var messageTypeList: [MessageContentType]?
    public var searchTimePosition: Int = 0
    public var searchTimePeriod: Int = 0
    public var pageIndex: Int = 1
    public var count: Int = 100
    public init() {
        
    }
}

public class SearchResultInfo {
    public var totalCount: Int = 0
    public var searchResultItems: [SearchResultItemInfo] = []
}

public class SearchResultItemInfo {
    public var conversationID: String = ""
    public var messageCount: Int = 0
    public var conversationType: ConversationType = .c2c
    public var showName: String = ""
    public var faceURL: String = ""
    public var messageList: [MessageInfo] = []
    
    public init() {
        
    }
}

public class SearchGroupParam {
    public var keywordList: [String] = []
    public var isSearchGroupID: Bool = true
    public var isSearchGroupName: Bool = true
    public init() {
        
    }
}

public class SearchUserParam {
    public var keywordList: [String] = []
    public var isSearchUserID: Bool = true
    public var isSearchNickname: Bool = true
    public var isSearchRemark: Bool = true
    public init() {
        
    }
}

public class SearchUserInfo: FriendInfo {
    public var relationship: Relationship = .friends
    
    public init(relationship: Relationship = .friends) {
        self.relationship = relationship
    }
}

public struct SearchGroupMemberParam {
    public var groupID: String
    public var keywordList: [String] = []
    public var isSearchUserID: Bool = true
    public var isSearchNickname: Bool = true
    public var offset: Int = 0
    public var count: Int = 0
    
    public init(groupID: String, keywordList: [String], isSearchUserID: Bool = true, isSearchNickname: Bool = true, offset: Int = 0, count: Int = 1000) {
        self.groupID = groupID
        self.keywordList = keywordList
        self.isSearchUserID = isSearchUserID
        self.isSearchNickname = isSearchNickname
        self.offset = offset
        self.count = count
    }
}


extension MessageInfo {
    public func toOIMMessageInfo() -> OIMMessageInfo {
        let map = JsonTool.toMap(fromObject: self)
        if let item = OIMMessageInfo.mj_object(withKeyValues: map) {
            item.locationElem?.desc = locationElem?.desc
            
            return item
        }
        return OIMMessageInfo()
    }
    
    public var isOutgoing: Bool {
        return sendID == IMController.shared.uid
    }
}

extension OfflinePushInfo {
    func toOIMOfflinePushInfo() -> OIMOfflinePushInfo {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMOfflinePushInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMOfflinePushInfo()
    }
}

extension MessageContentType {
    func toOIMMessageContentType() -> OIMMessageContentType {
        let type = OIMMessageContentType(rawValue: rawValue) ?? OIMMessageContentType.text
        return type
    }
}

extension OIMGroupInfo {
    func toGroupInfo() -> GroupInfo {
        let item = GroupInfo()
        item.groupID = groupID ?? ""
        item.faceURL = faceURL
        item.createTime = createTime
        item.ownerUserID = ownerUserID
        item.creatorUserID = creatorUserID
        item.memberCount = memberCount
        item.introduction = introduction
        item.notification = notification
        item.groupName = groupName
        item.groupType = GroupType(rawValue: groupType.rawValue) ?? .working
        item.status = GroupStatus(rawValue: status.rawValue) ?? .ok
        item.needVerification = GroupVerificationType(rawValue: needVerification.rawValue) ?? .applyNeedVerificationInviteDirectly
        item.lookMemberInfo = lookMemberInfo.rawValue
        item.applyMemberFriend = applyMemberFriend.rawValue
        item.notificationUserID = notificationUserID
        item.notificationUpdateTime = notificationUpdateTime
        item.ex = ex
        
        return item
    }
}

extension OIMUserInfo {
    public func toUserInfo() -> UserInfo {
        let item = UserInfo(userID: userID!)
        item.faceURL = faceURL
        item.nickname = nickname
        item.createTime = createTime
        item.ex = ex
        item.globalRecvMsgOpt = ReceiveMessageOpt(rawValue: globalRecvMsgOpt.rawValue) ?? .receive
        
        return item
    }
}

extension OIMGroupApplicationInfo {
    func toGroupApplicationInfo() -> GroupApplicationInfo {
        let item = GroupApplicationInfo()
        item.groupID = groupID ?? ""
        item.groupName = groupName
        item.groupFaceURL = groupFaceURL
        item.creatorUserID = creatorUserID ?? ""
        item.ownerUserID = ownerUserID ?? ""
        item.memberCount = memberCount
        item.userID = userID
        item.nickname = nickname
        item.userFaceURL = userFaceURL
        item.reqMsg = reqMsg
        item.reqTime = reqTime
        item.handleUserID = handleUserID
        item.handledMsg = handledMsg
        item.handledTime = handledTime
        item.handleResult = ApplicationStatus(rawValue: handleResult.rawValue) ?? .normal
        item.joinSource = JoinSource(rawValue: Int(joinSource.rawValue)) ?? .search
        item.inviterUserID = inviterUserID
        return item
    }
}

extension OIMFriendApplication {
    func toFriendApplication() -> FriendApplication {
        let item = FriendApplication()
        item.fromUserID = fromUserID ?? ""
        item.fromNickname = fromNickname
        item.fromFaceURL = fromFaceURL
        item.toUserID = toUserID ?? ""
        item.toNickname = toNickname
        item.toFaceURL = toFaceURL
        item.handleResult = ApplicationStatus(rawValue: handleResult.rawValue) ?? .normal
        item.reqMsg = reqMsg
        item.handlerUserID = handlerUserID
        item.handleMsg = handleMsg
        item.handleTime = handleTime
        item.createTime = createTime
        
        return item
    }
}

extension OIMPublicUserInfo {
    public func toUserInfo() -> UserInfo {
        let item = UserInfo(userID: userID!)
        item.faceURL = faceURL

        item.nickname = nickname
        
        return item
    }
}

extension OIMConversationInfo {
    func toConversationInfo() -> ConversationInfo {
        let item = ConversationInfo(conversationID: conversationID ?? "")
        item.userID = userID
        item.groupID = groupID
        item.showName = showName
        item.faceURL = faceURL
        item.recvMsgOpt = recvMsgOpt.toReceiveMessageOpt()
        item.unreadCount = unreadCount
        item.conversationType = conversationType.toConversationType()
        item.latestMsgSendTime = latestMsgSendTime
        item.draftText = draftText
        item.draftTextTime = draftTextTime
        item.isPinned = isPinned
        item.latestMsg = latestMsg?.toMessageInfo()
        item.isPrivateChat = isPrivateChat
        item.burnDuration = burnDuration
        item.isNotInGroup = isNotInGroup
        item.groupAtType = GroupAtType(rawValue: groupAtType.rawValue)!
#if ENABLE_MOMENTS || ENABLE_CALL
        item.isMsgDestruct = isMsgDestruct
        item.msgDestructTime = msgDestructTime
#endif
        item.ex = ex
        return item
    }
}

extension OIMMessageInfo {
    public func toMessageInfo() -> MessageInfo {
        let item = MessageInfo()
        item.clientMsgID = clientMsgID ?? ""
        item.serverMsgID = serverMsgID
        item.createTime = createTime
        item.sendTime = sendTime
        item.sessionType = sessionType.toConversationType()
        item.sendID = sendID ?? ""
        item.recvID = recvID
        item.handleMsg = handleMsg
        item.msgFrom = msgFrom.toMessageLevel()
        item.contentType = contentType.toMessageContentType()
        item.senderPlatformID = senderPlatformID.rawValue
        item.senderNickname = senderNickname
        item.senderFaceUrl = senderFaceUrl
        item.groupID = groupID
        item.content = content
        item.seq = seq
        item.isRead = isRead
        item.status = status.toMessageStatus()
        item.attachedInfo = attachedInfo
        item.ex = ex
        item.localEx = localEx

        item.offlinePushInfo = offlinePush.toOfflinePushInfo()
        item.textElem = textElem?.toTextElem()
        item.pictureElem = pictureElem?.toPictureElem()
        item.soundElem = soundElem?.toSoundElem()
        item.videoElem = videoElem?.toVideoElem()
        item.fileElem = fileElem?.toFileElem()
        item.mergeElem = mergeElem?.toMergeElem()
        item.atTextElem = atTextElem?.toAtTextElem()
        item.locationElem = locationElem?.toLocationElem()
        item.quoteElem = quoteElem?.toQuoteElem()
        item.customElem = customElem?.toCustomElem()
        item.notificationElem = notificationElem?.toNotificationElem()
        item.faceElem = faceElem?.toFaceElem()
        item.attachedInfoElem = attachedInfoElem?.toAttachedInfoElem()

        item.cardElem = cardElem?.toCardElem()
        item.typingElem = typingElem?.toTypingElem()
        
        return item
    }
}

extension OIMReceiveMessageOpt {
    func toReceiveMessageOpt() -> ReceiveMessageOpt {
        switch self {
        case .receive:
            return .receive
        case .notReceive:
            return .notReceive
        case .notNotify:
            return .notNotify
        }
    }
}

extension OIMConversationType {
    func toConversationType() -> ConversationType {
        switch self {
        case .undefine:
            return .undefine
        case .C2C:
            return .c2c
        case .superGroup:
            return .superGroup
        case .notification:
            return .notification
        default:
            return .undefine
        }
    }
}

extension OIMMessageLevel {
    func toMessageLevel() -> MessageLevel {
        switch self {
        case .user:
            return .user
        case .system:
            return .system
        default:
            return .undefine
        }
    }
}

extension OIMMessageContentType {
    func toMessageContentType() -> MessageContentType {
        let item = MessageContentType(rawValue: rawValue) ?? MessageContentType.unknown
        return item
    }
}

extension OIMMessageStatus {
    func toMessageStatus() -> MessageStatus {
        switch self {
        case .undefine:
            return .undefine
        case .sending:
            return .sending
        case .sendSuccess:
            return .sendSuccess
        case .sendFailure:
            return .sendFailure
        case .revoke:
            return .revoke
        @unknown
        default:
            return .undefine
        }
    }
}

extension OIMOfflinePushInfo {
    func toOfflinePushInfo() -> OfflinePushInfo {
        let item = OfflinePushInfo()
        item.title = title
        item.desc = desc
        item.iOSPushSound = iOSPushSound
        item.iOSBadgeCount = iOSBadgeCount
        item.operatorUserID = operatorUserID
        item.ex = ex
        return item
    }
}

extension OIMTextElem {
    func toTextElem() -> TextElem {
        let item = TextElem()
        item.content = content
        
        return item
    }
}

extension OIMCardElem {
    func toCardElem() -> CardElem {
        let item = CardElem(userID: userID, nickname: nickname, faceURL: faceURL)
        item.ex = ex
        
        return item
    }
}

extension OIMTypingElem {
    func toTypingElem() -> TypingElem {
        let item = TypingElem()
        item.msgTips = msgTips
        
        return item
    }
}

extension OIMPictureElem {
    func toPictureElem() -> PictureElem {
        let item = PictureElem()
        item.sourcePath = sourcePath
        item.sourcePicture = sourcePicture?.toPictureInfo()
        item.bigPicture = bigPicture?.toPictureInfo()
        item.snapshotPicture = snapshotPicture?.toPictureInfo()
        return item
    }
}

extension OIMPictureInfo {
    func toPictureInfo() -> PictureInfo {
        let item = PictureInfo()
        item.uuID = uuID
        item.type = type
        item.size = size
        item.width = width
        item.height = height
        item.url = url
        return item
    }
}

extension OIMSoundElem {
    func toSoundElem() -> SoundElem {
        let item = SoundElem()
        item.uuID = uuID
        item.soundPath = soundPath
        item.sourceUrl = sourceUrl
        item.dataSize = dataSize
        item.duration = duration
        return item
    }
}

extension OIMVideoElem {
    func toVideoElem() -> VideoElem {
        let item = VideoElem()
        item.videoUUID = videoUUID
        item.videoPath = videoPath
        item.videoUrl = videoUrl
        item.videoType = videoType
        item.videoSize = videoSize
        item.duration = duration
        item.snapshotPath = snapshotPath
        item.snapshotUUID = snapshotUUID
        item.snapshotSize = snapshotSize
        item.snapshotUrl = snapshotUrl
        item.snapshotWidth = snapshotWidth
        item.snapshotHeight = snapshotHeight
        return item
    }
}

extension OIMFileElem {
    func toFileElem() -> FileElem {
        let item = FileElem()
        item.uuID = uuID
        item.filePath = filePath
        item.sourceUrl = sourceUrl
        item.fileName = fileName
        item.fileSize = fileSize
        return item
    }
}

extension OIMMergeElem {
    func toMergeElem() -> MergeElem {
        let item = MergeElem()
        item.title = title
        item.abstractList = abstractList
        item.multiMessage = multiMessage?.compactMap { $0.toMessageInfo() }
        return item
    }
}

extension OIMAtTextElem {
    func toAtTextElem() -> AtTextElem {
        let item = AtTextElem()
        item.text = text
        item.atUserList = atUserList
        item.atUsersInfo = atUsersInfo?.compactMap { $0.toAtInfo() }
        item.isAtSelf = isAtSelf
        item.quoteMessage = quoteMessage?.toMessageInfo()
        
        return item
    }
}

extension OIMAtInfo {
    func toAtInfo() -> AtInfo {
        let item = AtInfo(atUserID: atUserID!, groupNickname: groupNickname ?? "Unkonw")
        
        return item
    }
}

extension OIMLocationElem {
    func toLocationElem() -> LocationElem {
        let item = LocationElem()
        item.desc = desc
        item.longitude = longitude
        item.latitude = latitude
        return item
    }
}

extension OIMQuoteElem {
    func toQuoteElem() -> QuoteElem {
        let item = QuoteElem()
        item.text = text
        item.quoteMessage = quoteMessage?.toMessageInfo()
        return item
    }
}

extension OIMCustomElem {
    func toCustomElem() -> CustomElem {
        let item = CustomElem()
        item.data = data
        item.ext = self.extension
        item.description = description_
        
        return item
    }
}

extension OIMFaceElem {
    func toFaceElem() -> FaceElem {
        let item = FaceElem()
        item.index = index
        item.data = data
        return item
    }
}

extension OIMAttachedInfoElem {
    func toAttachedInfoElem() -> AttachedInfoElem {
        let item = AttachedInfoElem()
        item.isPrivateChat = isPrivateChat
        item.burnDuration = burnDuration
        item.hasReadTime = hasReadTime
        return item
    }
}

extension OIMNotificationElem {
    func toNotificationElem() -> NotificationElem {
        let item = NotificationElem(opUser: opUser?.toGroupMemberInfo(),
                                    quitUser: quitUser?.toGroupMemberInfo(),
                                    entrantUser: entrantUser?.toGroupMemberInfo(),
                                    groupNewOwner: groupNewOwner?.toGroupMemberInfo(),
                                    group: group?.toGroupInfo(),
                                    kickedUserList: kickedUserList?.compactMap { $0.toGroupMemberInfo() },
                                    invitedUserList: invitedUserList?.compactMap { $0.toGroupMemberInfo() })
        item.detail = detail
        
        return item
    }
}

extension OIMGroupMemberInfo {
    public func toGroupMemberInfo() -> GroupMemberInfo {
        
        let item = GroupMemberInfo()
        item.userID = userID
        item.roleLevel = GroupMemberRole(rawValue: roleLevel.rawValue) ?? .member
        item.groupID = groupID
        item.nickname = nickname
        item.faceURL = faceURL
        item.joinTime = joinTime
        item.joinSource = JoinSource(rawValue: Int(joinSource.rawValue)) ?? .search
        item.operatorUserID = operatorUserID
        item.inviterUserID = inviterUserID
        item.muteEndTime = muteEndTime
        item.ex = ex
        return item
    }
}

extension OIMGroupMemberRole {
}

extension OIMConversationNotDisturbInfo {
    func toConversationNotDisturbInfo() -> ConversationNotDisturbInfo {
        let item = ConversationNotDisturbInfo(conversationId: conversationID ?? "")
        item.result = result.toReceiveMessageOpt()
        return item
    }
}

extension OIMReceiptInfo {
    func toReceiptInfo() -> ReceiptInfo {
        let item = ReceiptInfo()
        item.userID = userID
        item.groupID = groupID
        item.msgIDList = msgIDList
        item.readTime = readTime
        item.msgFrom = msgFrom.toMessageLevel()
        item.contentType = contentType.toMessageContentType()
        item.sessionType = sessionType.toConversationType()
        return item
    }
}

extension OIMPublicUserInfo {
    func toPublicUserInfo() -> PublicUserInfo {
        let item = PublicUserInfo()
        item.userID = userID
        item.nickname = nickname
        item.faceURL = faceURL

        return item
    }
}

extension OIMBlackInfo {
    func toBlackInfo() -> BlackInfo {
        let item = BlackInfo()
        item.operatorUserID = operatorUserID
        item.createTime = createTime
        item.addSource = addSource
        item.userID = userID
        item.faceURL = faceURL
        item.nickname = nickname
        item.attachedInfo = attachedInfo
        item.ex = ex
        return item
    }
}

extension OIMFriendInfo {
    func toFriendInfo() -> FriendInfo {
        let item = FriendInfo()
        item.nickname = nickname
        item.faceURL = faceURL
        item.userID = userID
        item.ownerUserID = ownerUserID
        item.remark = remark
        item.createTime = createTime
        item.addSource = addSource
        item.operatorUserID = operatorUserID
        item.attachedInfo = attachedInfo
        item.ex = ex
        return item
    }
}

extension OIMSearchFriendsInfo {
    func toSearchFriendsInfo() -> SearchUserInfo {
        let item = SearchUserInfo()
        item.relationship = Relationship(rawValue: relationship.rawValue) ?? .friends
        item.nickname = nickname
        item.faceURL = faceURL
        item.userID = userID
        item.ownerUserID = ownerUserID
        item.remark = remark
        item.createTime = createTime
        item.addSource = addSource
        item.operatorUserID = operatorUserID
        item.attachedInfo = attachedInfo
        item.ex = ex
        return item
    }
}

extension OIMSearchResultInfo {
    func toSearchResultInfo() -> SearchResultInfo {
        let item = SearchResultInfo()
        item.totalCount = totalCount
        item.searchResultItems = searchResultItems.compactMap { $0.toSearchResultItemInfo() }
        return item
    }
}

extension OIMSearchResultItemInfo {
    func toSearchResultItemInfo() -> SearchResultItemInfo {
        let item = SearchResultItemInfo()
        item.conversationID = conversationID
        item.messageCount = messageCount
        item.conversationType = ConversationType(rawValue: conversationType.rawValue) ?? .c2c
        item.showName = showName
        item.faceURL = faceURL
        item.messageList = messageList.compactMap { $0.toMessageInfo() }
        return item
    }
}

extension OIMMessageRevokedInfo {
    func toMessageRevoked() -> MessageRevoked {
        let item = MessageRevoked()
        item.clientMsgID = clientMsgID
        item.revokeTime = revokeTime
        item.revokerID = revokerID
        item.revokerNickname = revokerNickname
        item.revokerRole = GroupMemberRole(rawValue: revokerRole.rawValue) ?? .member
        item.sessionType = ConversationType(rawValue: sessionType.rawValue) ?? .c2c
        item.sourceMessageSendID = sourceMessageSendID
        item.sourceMessageSendTime = sourceMessageSendTime
        item.sourceMessageSenderNickname = sourceMessageSenderNickname
        
        return item
    }
}

extension OIMUserStatusInfo {
    func toUserStatusInfo() -> UserStatusInfo {
        let item = UserStatusInfo()
        item.userID = userID!
        item.status = status
        item.platformIDs = (platformIDs ?? []) as [Int]
        
        return item
    }
}

extension OIMInputStatusChangedData {
    func toInputStatusChangedData() -> InputStatusChangedData {
        let item = InputStatusChangedData()
        item.conversationID = conversationID
        item.userID = userID
        item.platformIDs = platformIDs.compactMap({ Int($0) })
        
        return item
    }
}


extension UserInfo {
    public func toOIMUserInfo() -> OIMUserInfo {
        let json = JsonTool.toJson(fromObject: self)
        if let item = OIMUserInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMUserInfo()
    }
}

extension GroupInfo {
    func toOIMGroupInfo(exceptDisplayIsRead: Bool = false) -> OIMGroupInfo {
        let item = OIMGroupInfo()
        item.groupID = groupID
        item.faceURL = faceURL
        item.groupName = groupName
        item.introduction = introduction
        item.notification = notification
        item.lookMemberInfo = OIMAllowType(rawValue: lookMemberInfo)!
        item.applyMemberFriend = OIMAllowType(rawValue: applyMemberFriend)!
        item.needVerification = OIMGroupVerificationType(rawValue: needVerification.rawValue)!
        item.groupType = OIMGroupType(rawValue: groupType.rawValue)!
        item.notificationUserID = notificationUserID
        item.notificationUpdateTime = notificationUpdateTime
        item.ex = ex
        
        return item
    }
}

public extension SearchParam {
    public func toOIMSearchParam() -> OIMSearchParam {
        let item = OIMSearchParam()
        item.conversationID = conversationID
        item.keywordList = keywordList
        item.messageTypeList = messageTypeList?.compactMap { $0.rawValue }
        item.searchTimePeriod = searchTimePeriod
        item.searchTimePosition = searchTimePosition
        item.pageIndex = pageIndex
        item.count = count
        return item
    }
}

public extension SearchUserParam {
    func toOIMSearchUserParam() -> OIMSearchFriendsParam {
        let item = OIMSearchFriendsParam()
        item.keywordList = keywordList
        item.isSearchRemark = isSearchRemark
        item.isSearchNickname = isSearchNickname
        item.isSearchUserID = isSearchUserID
        
        return item
    }
}

public extension SearchGroupParam {
    func toOIMSearchGroupParam() -> OIMSearchGroupParam {
        let item = OIMSearchGroupParam()
        item.keywordList = keywordList
        item.isSearchGroupID = isSearchGroupID
        item.isSearchGroupName = isSearchGroupName
        
        return item
    }
}

public extension SearchGroupMemberParam {
    func toOIMSearchGroupMemberParam() -> OIMSearchGroupMembersParam {
        let item = OIMSearchGroupMembersParam()
        item.groupID = groupID
        item.keywordList = keywordList
        item.isSearchUserID = isSearchUserID
        item.isSearchMemberNickname = isSearchNickname
        item.offset = offset
        item.count = count
        
        return item
    }
}

extension MessageRevoked {
    func toOIMMessageRevoked() -> OIMMessageRevokedInfo {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMMessageRevokedInfo.mj_object(withKeyValues: json) {
            return item
        }
        return OIMMessageRevokedInfo()
    }
}

extension CardElem {
    func toOIMCardElem() -> OIMCardElem {
        let json: String = JsonTool.toJson(fromObject: self)
        if let item = OIMCardElem.mj_object(withKeyValues: json) {
            return item
        }
        return OIMCardElem()
    }
}
