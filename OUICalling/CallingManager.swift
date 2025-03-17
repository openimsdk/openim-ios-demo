
import Foundation
import OpenIMSDK
import RxSwift
import RxCocoa
import OUICore
import ProgressHUD

enum CallingState: String {
    case normal = "normal"
    case call = "call" 
    case beCalled = "beCalled" 
    case reject = "reject" 
    case beRejected = "beRejected" 
    case calling = "calling" 
    case beAccepted = "beAccepted" 
    case hangup = "hangup" 
    case beHangup = "beHangup"
    case connecting = "connecting"
    case disConnect = "disConnect"
    case connectFailure = "connectFailure"
    case noReply = "noReply"
    case cancel = "cancel" 
    case beCanceled = "beCanceled" 
    case timeout = "timeout" 
    case join = "join" 
    case accessByOther = "accessByOther"
    case rejectedByOther = "rejectedByOther"
}

public typealias ValueChangedHandler<T> = (_ value: T) -> Void

public class CallingManager: NSObject {
    private let callingTimeout = 60
    
    private let disposeBag = DisposeBag()
    private var signalingInfo: OIMSignalingInfo?
    
    private var senderViewController: CallingSenderController? 
    private var reciverViewController: CallingReceiverController? 
    private var inviter: CallingUserInfo? 
    private var others: [CallingUserInfo]?
    private var isPresented: Bool = false 
    private var liveURL: String?
    private var token: String?
    private var countdownTimer: CountdownTimer?

    public static let manager: CallingManager = CallingManager()
    public var roomParticipantChangedHandler: ValueChangedHandler<OIMParticipantConnectedInfo>?
    public var endCallingHandler: ValueChangedHandler<OIMMessageInfo>?
    
    public func start() {
        OIMManager.callbacker.addAdvancedMsgListener(listener: self)
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: UIApplication.willTerminateNotification, object: nil);
    }
    
    public func end() {
        OIMManager.callbacker.removeAdvancedMsgListener(listener: self)
    }
    
    public func forceDismiss() {
        guard Self.isBusy else { return }
        
        CallingManager.manager.isPresented = false
        
        if let signalingInfo, 
            signalingInfo.isSignal {
        
            hungup()
        }
        
        senderViewController?.dismiss()
        reciverViewController?.dismiss()
    }

    
    static public var isBusy: Bool {
        CallingManager.manager.isPresented
    }
    
    func getTokenForRTC(roomID: String, userID: String) async -> OIMParticipantConnectedInfo? {
        let baseURL = UserDefaults.standard.string(forKey: "io.openim.bussiness.api.adr") ?? ""
        let token = UserDefaults.standard.string(forKey: "bussinessTokenKey") ?? ""
        let body = try? JSONSerialization.data(withJSONObject: ["room": roomID, "identity": userID], options: .fragmentsAllowed)
        guard var request = try? URLRequest(url: URL(string: baseURL + "/user/rtc/get_token")!, method: .post) else { return nil }
        request.httpBody = body
        request.addValue(token, forHTTPHeaderField: "token")
        request.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        let result = try? await URLSession.shared.data(for: request)
                
        if let d = result?.0 {
            guard let map = try? JSONSerialization.jsonObject(with: d, options: .fragmentsAllowed) as? [String: Any],
                  let data = map["data"] as? [String: Any] else { return nil }
            let url = data["serverUrl"] as! String
            let token = data["token"] as! String
            
            let r = OIMParticipantConnectedInfo()
            r.liveURL = url
            r.token = token
            r.roomID = roomID
            
            return r
        }
        
        return nil
    }
    
    @objc private func willTerminate() {
        update(state: .hangup)
    }
    
    private func setupSenderViewController() {
        senderViewController = CallingSenderController()

        senderViewController!.onDisconnect = { [weak self] in
            self?.update(state: .disConnect)
        }
        
        senderViewController!.onConnectFailure = { [weak self] in
            self?.update(state: .connectFailure)
        }
        
        senderViewController!.onCancel = { [weak self] in
            self?.update(state: .cancel)
        }
        
        senderViewController!.onHungup = { [weak self] duration in
            self?.update(state: .hangup, duration: duration)
        }
    }
    
    private func setupReciverViewController() {
        reciverViewController = CallingReceiverController()
        reciverViewController!.onDisconnect = { [weak self] in
            self?.update(state: .disConnect)
        }
        
        reciverViewController!.onConnectFailure = { [weak self] in
            self?.update(state: .connectFailure)
        }
        
        reciverViewController!.onAccepted = { [weak self] in
            self?.acceptCalling()
        }
        
        reciverViewController!.onRejected = { [weak self] in
            self?.update(state: .reject)
        }
        
        reciverViewController!.onHungup = { [weak self] duration in
            self?.update(state: .hangup, duration: duration)
        }
    }
    
    deinit {
    }
    
    public func signalingGetInvitation(by roomID: String, onSuccess: @escaping (_ url: String, _ token: String) -> Void) {
        Task {
            if let r = await getTokenForRTC(roomID: roomID, userID: OIMManager.manager.getLoginUserID()) {
                onSuccess(r.liveURL, r.token)
            }
        }
    }
    
    public func startLiveChat(inviterID: String = OIMManager.manager.getLoginUserID(),
                              othersID: [String],
                              isVideo: Bool = true,
                              incoming: Bool = false) {

        if isPresented {
            return
        }
        isPresented = true
        
        if !incoming {
            ProgressHUD.animate()
            setupSenderViewController()
            
            invite(othersID: othersID, isVideo: isVideo) { [weak self] canStart in
                guard let self, canStart else { return }
                
                getUsersInfo([inviterID] + othersID) { [weak self] r in
                    guard let `self` else { return }
                    
                    self.inviter = r.first
                    self.others = Array(r.dropFirst())
                    ProgressHUD.dismiss()
                    
                    self.senderViewController!.startLiveChat(inviter: { [weak self] in
                        
                        guard let `self` else { return [] }
                        return [self.inviter!]
                    }, others: { [weak self] in
                        
                        guard let `self` else { return [] }
                        return self.others!
                    }, isVideo: isVideo)
                }
            }
        } else {
            setupReciverViewController()
            getUsersInfo([inviterID] + othersID) { [weak self] r in
                guard let `self` else { return }
                
                self.inviter = r.first
                self.others = Array(r.dropFirst())
                ProgressHUD.dismiss()
                
                self.reciverViewController?.startLiveChat(inviter: { [weak self] in
                    
                    guard let `self` else { return [] }
                    return [self.inviter!]
                }, others: { [weak self] in
                    
                    guard let `self` else { return [] }
                    return self.others!
                }, isVideo: isVideo)
            }
            
        }
    }
    
    public func startLiveChat(inviter: CallingUserInfo = CallingUserInfo(userID: OIMManager.manager.getLoginUserID()),
                              others: [CallingUserInfo],
                              isVideo: Bool = true,
                              incoming: Bool = false) {

        if isPresented {
            return
        }
        isPresented = true

        self.inviter = inviter
        self.others = others
        
        if !incoming {
            setupSenderViewController()
            invite(othersID: others.map({$0.userID}), isVideo: isVideo) { [weak self] canStart in
                guard let self, canStart else {
                    self?.isPresented = false

                    return
                }
            }
            
            senderViewController!.startLiveChat(inviter: {
                return [inviter]
            }, others: { [weak self] in
                guard let self else { return [] }
                return self.others!
            }, isVideo: isVideo)
        } else {
            setupReciverViewController()
            self.reciverViewController!.startLiveChat(inviter: {
                return [inviter]
            }, others: {
                return others
            }, isVideo: isVideo)
        }
    }
    
    private func invite(othersID: [String], isVideo: Bool, completion: @escaping ((Bool) -> Void)) {
        Task {
            let info = OIMInvitationInfo()
            info.inviteeUserIDList = othersID
            info.mediaType = isVideo ? "video" : "audio"
            info.timeout = callingTimeout
            info.roomID = UUID().uuidString
            info.inviterUserID = OIMManager.manager.getLoginUserID()
            info.sessionType = .C2C
            
            var offlinePushInfo = OIMOfflinePushInfo()
            
            var s = OIMSignalingInfo()
            s.userID = OIMManager.manager.getLoginUserID()
            s.invitation = info
            s.offlinePushInfo = offlinePushInfo
            
            invite(singalingInfo: s)
            
            if let r = await getTokenForRTC(roomID: info.roomID, userID: s.userID) {
                completion(true)
                liveURL = r.liveURL
                token = r.token
            }
        }
    }
    
    private func getUsersInfo(_ usersID: [String], callback: @escaping ([CallingUserInfo]) -> Void) {
        
            var tempUserIDs: [String] = usersID
            OIMManager.manager.getSpecifiedFriendsInfo(usersID, filterBlack: false) { friends in
                
                var us = friends?.compactMap({ CallingUserInfo(userID: $0.userID, nickname: $0.nickname, faceURL: $0.faceURL )}) ?? []
                tempUserIDs.removeAll(where: { id in
                    us.contains(where: { $0.userID == id }) == true
                })
                
                guard !tempUserIDs.isEmpty else {
                    callback(us)
                    
                    return
                }
                
                OIMManager.manager.getUsersInfo(tempUserIDs) { infos in
                    guard let infos else {
                        callback(us)
                        
                        return
                    }
                    
                    us += infos.compactMap({ CallingUserInfo(userID: $0.userID, nickname: $0.nickname, faceURL: $0.faceURL )})
                    
                    callback(us)
                }
        }
    }
    
    private func showAlert(message: String, handler: (() -> Void)?) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "取消".localized(), style: .cancel, handler: { [weak self] action in
            handler?()
        }))
        UIViewController.currentViewController().present(alertController, animated: true)
    }
    
    private func cancelCalling(noReply: Bool = false) {
        signalingInfo?.userID = Open_im_sdkGetLoginUserID()
        
        if noReply {
            if let signalingInfo, signalingInfo.isSignal {
                cancel()
            }
        } else {
            if let signalingInfo {
                cancel()
            }
        }
    }
    
    private func hungupCalling() {
        signalingInfo?.userID = Open_im_sdkGetLoginUserID()
        if let signalingInfo {
            hungup()
        }
    }
    
    private func rejectCalling() {
        signalingInfo?.userID = Open_im_sdkGetLoginUserID()
        
        if let signalingInfo {
            reject()
        }
    }
    
    private func acceptCalling() {
        countdownTimer?.stop()
        signalingInfo?.userID = Open_im_sdkGetLoginUserID()
        
        if let signalingInfo {
            accept()
            Task {
                if let r = await getTokenForRTC(roomID: signalingInfo.invitation.roomID, userID: signalingInfo.userID) {
                    liveURL = r.liveURL
                    token = r.token
                    
                    await reciverViewController?.connectRoom(liveURL: liveURL!, token: token!)
                }
            }
        }
    }
    
    private func startCountdownTimer() {
      countdownTimer = CountdownTimer(
            seconds: callingTimeout,
            onComplete: { [weak self] in
                guard let self else { return }
                print("Countdown complete without tick!")
                isPresented = false
                
                reciverViewController?.dismiss()
                reciverViewController = nil
                
                senderViewController?.dismiss()
                senderViewController = nil
            }
        )
        
        countdownTimer!.start()
    }
}

extension CallingManager {

    private func update(state: CallingState, duration: Int = 0) {
        print("\(#function): state:\(state)")
        if state == .beAccepted || state == .disConnect {
            if state == .beAccepted {
                if let liveURL, let token, signalingInfo?.isSignal == true {
                    senderViewController?.connectRoom(liveURL: liveURL, token: token)
                }
            } else {
                isPresented = false
                countdownTimer?.stop()
            }
            return
        }
        
        isPresented = false
        
        var timeline = "00:00"
        
        if duration > 0 {
            let m = duration / 60
            let s = duration % 60
            
            if m > 99 {
                timeline = String(format: "%d:%02d", m, s)
            } else {
                timeline = String(format: "%02d:%02d", m, s)
            }
        }
        let loginUserID = OIMManager.manager.getLoginUserID()
        var tips = ""
        var record = CallRecord()
        
        switch state {
        case .normal:
            break
        case .call:
            break
        case .beCalled:
            break
        case .reject:
            rejectCalling()
            tips = "已拒绝".localized()
        case .beRejected:
            tips = "对方已拒绝".localized()
        case .calling:
            break
        case .beAccepted:
            break
        case .hangup:
            hungupCalling()
            tips = "通话结束".localized() + ":\(timeline)"
            record.success = true
        case .connecting:
            break
        case .noReply:
            cancelCalling(noReply: true)
            tips = "无响应".localized()
        case .cancel:
            cancelCalling()
            tips = "已取消".localized()
        case .beCanceled:
            tips = duration > 0 ? "通话结束".localized() + ":\(timeline)" : "对方取消".localized()
            record.success = duration > 0
        case .timeout:
            tips = "超时无人接听".localized()
        case .join:
            break
        case .beHangup:
            if duration > 0 {
                tips = "通话结束".localized() + ":\(timeline)"
                record.success = true
            }
        case .disConnect:
            break
        case .connectFailure:
            tips = "connectionFailed".localized()
        case .accessByOther:
            tips = "通话邀请被其它客户端接受".localized()
            ProgressHUD.text(tips)
        case .rejectedByOther:
            tips = "通话邀请被其它客户端拒绝".localized()
            ProgressHUD.text(tips)
        }
        
        if #available(iOS 15, *) {
            record.date = Int(round(Date.now.timeIntervalSince1970 * 1000))
        } else {
            record.date = Int(round(Date.init().timeIntervalSince1970 * 1000))
        }

        if let signalingInfo {
            record.nickname = others?.first?.nickname
            record.type = signalingInfo.isVideo ? "video": "audio"
            record.faceURL = others?.first?.faceURL
            record.duration = duration
            record.isSingnal = signalingInfo.isSignal
            record.incoming = signalingInfo.invitation.inviterUserID != OIMManager.manager.getLoginUserID()
            record.otherSideID = record.incoming ? signalingInfo.invitation.inviterUserID : signalingInfo.invitation.inviteeUserIDList.first
            
            if signalingInfo.isSignal, !tips.isEmpty {
     
                do {
                    if !tips.isEmpty {
                        let param = ["customType": 901,
                                     "data": ["duration": duration,
                                              "state": state.rawValue,
                                              "type": signalingInfo.invitation.mediaType,
                                              "msg": tips
                                             ]
                        ] as [String : Any]
                        
                        let dataStr = String.init(data: try JSONSerialization.data(withJSONObject: param),
                                                  encoding: .utf8)!
                        
                        let msg = OIMMessageInfo.createCustomMessage(dataStr, extension: nil, description: nil)
                        insertCallingMessage(msg, signaling: signalingInfo, state: state)
                    }
                } catch (let e) {
                    print("catch \(e)")
                }
            }
        }

        countdownTimer?.stop()
        reciverViewController?.dismiss()
        reciverViewController = nil
        senderViewController?.dismiss()
        senderViewController = nil
    }
    
    private func invite(singalingInfo: OIMSignalingInfo) {
        sendMessage(type: .callingInvite, signalingInfo: singalingInfo)
        startCountdownTimer()
    }
    
    private func hungup() {
        sendMessage(type: .callingHungup)
    }
    
    private func reject() {
        sendMessage(type: .callingReject)
    }
    
    private func cancel() {
        sendMessage(type: .callingCancel)
    }
    
    private func accept() {
        sendMessage(type: .callingAccept)
    }
    
    private func sendMessage(type: CustomMessageType, signalingInfo: OIMSignalingInfo? = nil) {
        self.signalingInfo = signalingInfo ?? self.signalingInfo!
        
        let d = self.signalingInfo!.invitation.mj_keyValues()
        
        let data: [String: Any] = [
            "customType": type.rawValue,
            "data": d
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .fragmentsAllowed), let jsonStr = String(data: jsonData, encoding: .utf8) {
            
            let msg = OIMMessageInfo.createCustomMessage(jsonStr, extension: nil, description: nil)
            
            let recvUserID: String
            if self.signalingInfo!.invitation.inviterUserID == OIMManager.manager.getLoginUserID() {
                recvUserID = self.signalingInfo!.invitation.inviteeUserIDList.first!
            } else {
                recvUserID = self.signalingInfo!.invitation.inviterUserID
            }
            
            OIMManager.manager.sendMessage(msg, recvID: recvUserID, groupID: nil, isOnlineOnly: true, offlinePushInfo: OIMOfflinePushInfo()) { r in
                
            } onProgress: { p in
                
            }
        }
    }
}

extension CallingManager {
    
    private func insertCallingMessage(_ msg: OIMMessageInfo, signaling: OIMSignalingInfo, state: CallingState) {
        let loginUserID = OIMManager.manager.getLoginUserID()
        
        if state == .cancel || state == .beRejected || state == .reject || state == .noReply || state == .accessByOther || state == .rejectedByOther {
            OIMManager.manager.insertSingleMessage(toLocalStorage: msg,
                                                   recvID: others!.first!.userID,
                                                   sendID: signaling.invitation.inviterUserID,
                                                   onSuccess: { [weak self] message in
                guard let self, let message else { return }
                endCallingHandler?(message)
            }) { code, msg in
                print("单聊插入本地失败:\(code), \(msg)")
            }
        } else {
            var recvID = signaling.invitation.inviteeUserIDList.first!
            var sendID = signaling.invitation.inviterUserID
            
            OIMManager.manager.insertSingleMessage(toLocalStorage: msg,
                                                   recvID: recvID,
                                                   sendID: sendID,
                                                   onSuccess: { [weak self] message in
                guard let self, let message else { return }
                endCallingHandler?(message)
            }) { code, msg in
                print("单聊插入本地失败:\(code), \(msg)")
            }
        }
        
    }
}

extension CallingManager: OIMAdvancedMsgListener {
    public func onRecvOnlineOnlyMessage(_ message: OIMMessageInfo) {
        if message.contentType == .custom, let dataStr = message.customElem?.data {
            var data = try! JSONSerialization.jsonObject(with: dataStr.data(using: .utf8)!) as! [String: Any]
            let customType = data["customType"] as! Int
            let userID = data["userID"] as? String
            
            data = data["data"] as! [String: Any]
            
            if (customType == 200 ||
                customType == 201 ||
                customType == 202 ||
                customType == 203 ||
                customType == 204) {
                
                let invitation = OIMInvitationInfo()
                invitation.inviterUserID = data["inviterUserID"] as! String
                invitation.roomID = data["roomID"] as? String ?? ""
                invitation.timeout = data["timeout"] as? Int ?? 0
                invitation.mediaType = data["mediaType"] as! String
                invitation.sessionType = .C2C
                invitation.platformID = OIMPlatform(rawValue: (data["platformID"] as! NSNumber).intValue)!
                invitation.inviteeUserIDList = data["inviteeUserIDList"] as! [String]
                
                let signaling = OIMSignalingInfo()
                signaling.userID = userID ?? ""
                signaling.invitation = invitation

                switch (customType) {
                case 200:
                    startCountdownTimer()
                    CallingManager.manager.onReceiveNewInvitation(signaling)
                    break;
                case 201:
                    countdownTimer?.stop()
                    CallingManager.manager.onInviteeAccepted(signaling)
                    break;
                case 202:
                    countdownTimer?.stop()
                    CallingManager.manager.onInviteeRejected(signaling)
                    break;
                case 203:
                    countdownTimer?.stop()
                    CallingManager.manager.onInvitationCancelled(signaling)
                    break;
                case 204:
                    countdownTimer?.stop()
                    CallingManager.manager.onHunguUp(signaling)
                    break;
                default:
                    break
                }
            }
        }
    }
    
    public func onReceiveNewInvitation(_ signalingInfo: OIMSignalingInfo) {
        self.signalingInfo = signalingInfo
        
        startLiveChat(inviterID: signalingInfo.invitation.inviterUserID,
                      othersID: signalingInfo.invitation.inviteeUserIDList,
                      isVideo: signalingInfo.isVideo,
                      incoming: true)
    }
    
    public func onRoomParticipantConnected(_ connectedInfo: OIMParticipantConnectedInfo) {
        iLogger.print("\(#function) participant: \(connectedInfo.participant.map({ $0.userInfo.userID }))")
        
        roomParticipantChangedHandler?(connectedInfo)
    }
    
    public func onRoomParticipantDisconnected(_ disconnectedInfo: OIMParticipantConnectedInfo) {
        iLogger.print("\(#function) participant: \(disconnectedInfo.participant.map({ $0.userInfo.userID }))")
        
        roomParticipantChangedHandler?(disconnectedInfo)
    }
    
    public func onInviteeAccepted(_ signalingInfo: OIMSignalingInfo) {
        iLogger.print("\(#function)", keyAndValues: [signalingInfo.userID, signalingInfo.invitation.inviteeUserIDList])
        
        self.signalingInfo = signalingInfo
        update(state: .beAccepted)
    }
    
    public func onInviteeRejected(_ signalingInfo: OIMSignalingInfo) {
        iLogger.print("\(#function)", keyAndValues: [signalingInfo.userID, signalingInfo.invitation.inviteeUserIDList])

        self.signalingInfo = signalingInfo
        if signalingInfo.isSignal {
            update(state: .beRejected)
        }
    }
    
    public func onInvitationCancelled(_ signalingInfo: OIMSignalingInfo) {
        iLogger.print("\(#function)", keyAndValues: [signalingInfo.userID, signalingInfo.invitation.inviteeUserIDList])

        self.signalingInfo = signalingInfo
        update(state: .beCanceled)
    }
    
    public func onInvitationTimeout(_ signalingInfo: OIMSignalingInfo) {
        iLogger.print("\(#function)", keyAndValues: [signalingInfo.userID, signalingInfo.invitation.inviteeUserIDList])

        self.signalingInfo = signalingInfo
        if signalingInfo.isSignal {
            update(state: .noReply)
        }
    }
    
    public func onHunguUp(_ signalingInfo: OIMSignalingInfo) {
        iLogger.print("\(#function)", keyAndValues: [signalingInfo.userID, signalingInfo.invitation.inviteeUserIDList])

        self.signalingInfo = signalingInfo
        var duration = (senderViewController?.duration ?? reciverViewController?.duration) ?? 0
        update(state: .beHangup, duration: duration)
    }
    
    public func onInviteeAccepted(byOtherDevice signalingInfo: OIMSignalingInfo) {
        iLogger.print("\(#function)", keyAndValues: [signalingInfo.userID, signalingInfo.invitation.inviteeUserIDList])

        self.signalingInfo = signalingInfo
        update(state: .accessByOther)
    }
    
    public func onInviteeRejected(byOtherDevice signalingInfo: OIMSignalingInfo) {
        iLogger.print("\(#function)", keyAndValues: [signalingInfo.userID, signalingInfo.invitation.inviteeUserIDList])

        self.signalingInfo = signalingInfo
        update(state: .rejectedByOther)
    }
}

extension OIMSignalingInfo {
    var isSignal: Bool {
        true
    }
    
    var isVideo: Bool {
        return invitation.isVideo()
    }
}

public class CallRecord: Codable {
    public var otherSideID: String?
    public var nickname: String?
    public var faceURL: String?
    public var type: String?
    public var success: Bool = false
    public var incoming: Bool = false
    public var date: Int = 0
    public var duration: Int = 0
    public var isSingnal: Bool = true
    
    public func typeStr() -> String {
        return type == "audio" ? "语音通话".innerLocalized() : "视频通话".innerLocalized()
    }
    
    public func isVideo() -> Bool {
        return type == "video"
    }
    
    public func inOrOutStr() -> String {
        return incoming ? "呼入".innerLocalized() : "呼出".innerLocalized()
    }
    
    public func durationStr() -> String {
        
        var timeline = "";
        
        if duration > 0 {
            let m = duration / 60
            let s = duration % 60
            
            if m > 99 {
                timeline = String(format: "%d:%02d", m, s)
            } else {
                timeline = String(format: "%02d:%02d", m, s)
            }
        }
        
        return timeline
    }
    
    public func formatDateStr() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let date = Date.init(timeIntervalSince1970: TimeInterval(date / 1000))
        return formatter.string(from: date)
    }
    
    static func fromJson(_ json: String) -> [CallRecord] {
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode([CallRecord].self, from: json.data(using: .utf8)!)
            return result
        } catch let DecodingError.dataCorrupted(context) {
            return []
        } catch let DecodingError.keyNotFound(_, context) {
            return []
        } catch let DecodingError.typeMismatch(_, context) {
            return []
        } catch let DecodingError.valueNotFound(_, context) {
            return []
        } catch {
            return []
        }
    }
    
    func toJson() -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            guard let json = String(data: data, encoding: .utf8) else {
                fatalError("check your data is encodable from utf8!")
            }
            return json
        } catch let err {
            return ""
        }
    }
}

extension Array {
    static func toJson<T: Encodable>(fromObject: T) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(fromObject)
            guard let json = String(data: data, encoding: .utf8) else {
                fatalError("check your data is encodable from utf8!")
            }
            return json
        } catch let err {
            return ""
        }
    }
}

fileprivate class CountdownTimer {
    private var timer: DispatchSourceTimer?
    private var remainingTime: Int
    private let totalTime: Int
    private let onTick: ((Int) -> Void)?
    private let onComplete: () -> Void





    init(seconds: Int, onTick: ((Int) -> Void)? = nil, onComplete: @escaping () -> Void) {
        self.remainingTime = seconds
        self.totalTime = seconds
        self.onTick = onTick
        self.onComplete = onComplete
    }

    func start() {
        guard timer == nil else { return }
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer?.schedule(deadline: .now(), repeating: 1.0)

        timer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            if self.remainingTime > 0 {
                self.remainingTime -= 1
                if let onTick = self.onTick {
                    DispatchQueue.main.async {
                        onTick(self.remainingTime)
                    }
                }
            } else {
                self.stop()
                DispatchQueue.main.async {
                    self.onComplete()
                }
            }
        }
        timer?.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func reset() {
        stop()
        remainingTime = totalTime
    }
}
