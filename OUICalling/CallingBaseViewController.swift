
import AVFAudio
import Foundation
import LiveKitClient
import Lottie
import ProgressHUD
import RxSwift
import UIKit
import Kingfisher
import SnapKit
import OUICore

public typealias UserInfoHandler = () -> [CallingUserInfo]

@objc public class CallingUserInfo: NSObject {
    public var userID: String = ""
    public var nickname: String = ""
    public var faceURL: String?
    public var ex: String?
    
    @objc public init(userID: String? = nil,
                      nickname: String? = nil,
                      faceURL: String? = nil,
                      ex: String? = nil) {
        self.userID = userID ?? ""
        self.nickname = nickname ?? ""
        self.faceURL = faceURL
        self.ex = ex
    }
}

public class CallingBaseViewController: CallingBaseController {
    var inviter: UserInfoHandler!
    var users: UserInfoHandler!
    var isVideo: Bool = true
    
    internal let disposeBag = DisposeBag()
    internal var room: Room = Room()
    internal var funcBttonsView: UIStackView?
    internal let sdk = DispatchQueue(label: "com.calling.rtc.queue", qos: .userInitiated)
    internal let ringToneQueue: OperationQueue = {
        let v = OperationQueue()
        v.name = "com.calling.ringtone.queue"
        v.maxConcurrentOperationCount = 1
        
        return v
    }()
    internal var minimizeButton: UIButton = .init()
    internal var linkedTimer: Timer? 
    
    private var audioPlayer: AVAudioPlayer?
    
    internal var poorNetwork = false 
    
    public var linkingDuration: Int = 0 
    
    /**
     链接房间
     */
    public override func connectRoom(liveURL: String, token: String) {
        connectRoom(url: liveURL, token: token)
    }
    /**
     挂断、拒绝等关闭界面
     */
    public override func dismiss() {
        linkedTimer?.invalidate()
        linkedTimer = nil
        stopSounds()
        room.removeAllDelegates()
        
        Task {
            await room.disconnect()
        }
        DispatchQueue.main.async { [self] in
            UIViewController.currentViewController().dismiss(animated: true)
            removeMiniWindow()
        }
    }
    
    public override func isConnected() -> Bool {
        room.connectionState == .connected
    }
    
    var isSignal: Bool {
        true
    }

    private let linkingView: AnimationView = {
        let bundle = Bundle.callingBundle()
        let v = AnimationView(name: "linking", bundle: bundle)
        v.loopMode = .loop
        v.isHidden = true
        
        return v
    }()
    
    internal var smallViewIsMe = true
    internal var remoteMuted = false
    internal var localMuted = false
    internal var smallTrack: VideoTrack? {
        didSet {
            smallVideoView?.removeFromSuperview()
            smallVideoView = nil
            smallVideoView = setupVideoView()
            smallVideoView?.track = smallTrack
            smallContentView.addSubview(smallVideoView!)
            smallVideoView?.frame = smallContentView.bounds
        }
    }
    
    internal var bigTrack: VideoTrack? {
        didSet {
            bigVideoView?.removeFromSuperview()
            bigVideoView = nil
            bigVideoView = setupVideoView()
            bigVideoView?.track = bigTrack
            bigContentView.addSubview(bigVideoView!)
            bigVideoView?.frame = bigContentView.bounds
        }
    }
    
    internal func setupSmallPlaceholerView(user: CallingUserInfo) {
        smallDisableVideoImageView.image = nil
        smallAvatarView.reset()
    
        smallVideoView?.bringSubviewToFront(smallDisableVideoImageView)
        
        if let avatar = user.faceURL, !avatar.isEmpty {
            smallDisableVideoImageView.setImage(with: avatar)
            smallContentView.bringSubviewToFront(smallDisableVideoImageView)
        } else {
            let nickname = user.nickname
            smallAvatarView.setAvatar(url: nil, text: nickname)
            smallAvatarView.isHidden = false
        }
    }
    
    internal func setupBigPlaceholerView(user: CallingUserInfo) {
        bigDisableVideoImageView.image = nil
        bigAvatarView.reset()
        
        bigVideoView?.bringSubviewToFront(bigDisableVideoImageView)
        
        if let avatar = user.faceURL, !avatar.isEmpty {
            bigDisableVideoImageView.setImage(with: avatar)
            bigContentView.bringSubviewToFront(bigDisableVideoImageView)
        } else {
            let nickname = user.nickname
            bigAvatarView.setAvatar(url: nil, text: nickname)
            bigAvatarView.isHidden = false
        }
    }

    internal let tipsLabel: UILabel = {
        let t = UILabel()
        t.layer.cornerRadius = 6
        t.layer.masksToBounds = true
        t.text = ""
        t.textAlignment = .center
        t.textColor = .white
        return t
    }()

    internal let linkedTimeLabel: UILabel = {
        let t = UILabel()
        t.layer.cornerRadius = 6
        t.layer.masksToBounds = true
        t.text = ""
        t.textAlignment = .center
        t.textColor = .white
        return t
    }()
    
    internal lazy var bigContentView: UIView = {
        let v = UIView()
        v.frame = view.bounds
        
        bigVideoView = setupVideoView()
        v.addSubview(bigVideoView!)
        bigVideoView!.frame = v.bounds

        bigDisableVideoImageView.addSubview(bigAvatarView)
        bigAvatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        v.addSubview(bigDisableVideoImageView)
        bigDisableVideoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return v
    }()
    
    private var bigVideoView: VideoView?
    
    private let localViewTopInset = UIApplication.safeAreaInsets.top + 70
    
    internal lazy var smallContentView: UIView = {
        let v = UIView()
        v.frame = CGRectMake(CGRectGetWidth(UIScreen.main.bounds) - (120 + 12), localViewTopInset, 120, 180)
        
        smallVideoView = setupVideoView()
        
        v.addSubview(smallVideoView!)
        smallVideoView!.frame = v.bounds
        
        smallDisableVideoImageView.addSubview(smallAvatarView)
        smallAvatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        v.addSubview(smallDisableVideoImageView)
        smallDisableVideoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        v.isUserInteractionEnabled = true
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(movePreview))
        v.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handlesmallVideoViewTap(_:)))
        v.addGestureRecognizer(tap)
        
        return v
    }()
    
    private var smallVideoView: VideoView?
    
    private func setupVideoView() -> VideoView {
        let t = VideoView()
        t.layoutMode = .fill
        
        return t
    }
    
    @objc private func movePreview(gesture: UIPanGestureRecognizer) {

        let moveState = gesture.state
        switch moveState {
        case .changed:

            let point = gesture.translation(in: smallContentView.superview)
            smallContentView.center = CGPoint(x: smallContentView.center.x + point.x, y: smallContentView.center.y + point.y)
            break
        case .ended:

            let point = gesture.translation(in: smallContentView.superview)
            let newPoint = CGPoint(x: smallContentView.center.x + point.x, y: smallContentView.center.y + point.y)

            UIView.animate(withDuration: 0.1) { [self] in
                self.smallContentView.center = self.resetPosition(point: newPoint)
            }
            break
        default: break
        }

        gesture.setTranslation(.zero, in: smallContentView.superview!)
    }
    
    private func resetPosition(point: CGPoint) -> CGPoint {
        var newPoint = point
        let limitMargin = 20.0
        let bottomMargin = CGRectGetMaxY(smallContentView.superview!.frame) - 200

        if point.x <= (CGRectGetWidth(smallContentView.superview!.frame) / 2) {
            newPoint.x = (CGRectGetWidth(smallContentView.frame) / 2.0) + limitMargin
        } else {
            newPoint.x = CGRectGetWidth(smallContentView.superview!.frame) - (CGRectGetWidth(smallContentView.frame) / 2) - limitMargin
        }

        if point.y <= localViewTopInset {
            newPoint.y = localViewTopInset
        } else if point.y > bottomMargin {
            newPoint.y = bottomMargin
        }
        
        return newPoint
    }
    
    @objc
    private func handlesmallVideoViewTap(_ sender: UITapGestureRecognizer) {
        smallViewIsMe = !smallViewIsMe
        smallDisableVideoImageView.isHidden = true
        bigDisableVideoImageView.isHidden = true
        
        let temp = smallTrack

        smallTrack = bigTrack
        bigTrack = temp
        
        if let user = users().first, let me = inviter().first {
            if smallViewIsMe {
                smallDisableVideoImageView.isHidden = !localMuted
                bigDisableVideoImageView.isHidden = !remoteMuted
                setupBigPlaceholerView(user: user)
                setupSmallPlaceholerView(user: me)
            } else {
                smallDisableVideoImageView.isHidden = !remoteMuted
                bigDisableVideoImageView.isHidden = !localMuted
                setupBigPlaceholerView(user: me)
                setupSmallPlaceholerView(user: user)
            }
        }
    }
    
    internal let bigAvatarView: AvatarView = {
        let v = AvatarView()
        v.isHidden = true
        
        return v
    }()
    
    internal let bigDisableVideoImageView: UIImageView = {
        let v = UIImageView()
        v.backgroundColor = .gray
        v.isHidden = true
        v.contentMode = .scaleAspectFit
        
        return v
    }()
    
    internal let smallAvatarView: AvatarView = {
        let v = AvatarView()
        v.isHidden = true
        
        return v
    }()
    
    internal let smallDisableVideoImageView: UIImageView = {
        let v = UIImageView()
        v.backgroundColor = .gray
        v.isHidden = true
        v.contentMode = .scaleAspectFit
        
        return v
    }()
    
    private let acceptButtonCoverView: UIView = {
        let v = UIView()
        v.backgroundColor = .c00D66A
        v.layer.cornerRadius = 24
        v.isHidden = true
        v.layer.masksToBounds = true
        
        let i = UIActivityIndicatorView(style: .large)
        i.color = .white
        i.startAnimating()
        v.addSubview(i)
        
        i.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        return v
    }()
    
    override open func viewDidLoad() {
        view.backgroundColor = .init(red: 38 / 255, green: 38 / 255, blue: 38 / 255, alpha: 1)
        setupTopFuncButtons()
        toggleSpeakerphoneEnabled()
        UIApplication.shared.isIdleTimerDisabled = true
        
        view.insertSubview(bigContentView, belowSubview: minimizeButton)
        view.insertSubview(smallContentView, belowSubview: minimizeButton)

        if !isSignal {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
        }
    }
    
    @objc func handleAudioRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        if reason == .categoryChange || reason == .newDeviceAvailable {
            audioPlayer?.volume = 0.4
        }
    }
    
    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
        
        if room.connectionState == .connected {
            Task {
                await room.disconnect()
            }
        }
        linkedTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func scale() {
        print("缩放到小窗口：\(self.linkingDuration)")
        self.suspend(coverImageName: "contact_my_friend_icon", tips: self.linkingDuration > 0 ? "通话中".innerLocalized() : nil)
    }
    
    private lazy var micButton: UIButton = {
        let v = UIButton(type: .custom)

        v.setImage(UIImage(nameInBundle: "mic_open"), for: .normal)
        v.setImage(UIImage(nameInBundle: "mic_close"), for: .selected)
        v.titleLabel?.textAlignment = .center
        
        v.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
            self?.micButtonAction(sender: v)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    @objc func micButtonAction(sender: UIButton) {
        print("\(#function)")

        sender.isSelected = !sender.isSelected
        sender.isEnabled = false
        
        Task {
            await toggleMicrophoneEnabled()
            sender.isEnabled = true
        }
    }
    
    private lazy var cancelButton: UIButton = {
        let v = UIButton(type: .custom)

        v.setImage(UIImage(nameInBundle: "hang_up"), for: .normal)
        v.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
            self?.cancelButtonAction(sender: v)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    
    private lazy var thirdButton: UIButton = {
        let v = UIButton(type: .custom)
        v.setImage(.init(nameInBundle: "speaker_open"), for: .normal)
        v.setImage(.init(nameInBundle: "speaker_close"), for: .selected)
        
        v.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                
            self?.thirdButtonAction(sender: v)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    @objc func cancelButtonAction(sender: UIButton) {
        print("\(#function)")

        sender.isSelected = !sender.isSelected

        if self.linkingDuration > 0 {
            self.onHungup?(self.linkingDuration)
        } else {
            self.onCancel?()
        }
    }
    
    @objc func thirdButtonAction(sender: UIButton) {
        print("\(#function)")

        sender.isSelected = !sender.isSelected
        toggleSpeakerphoneEnabled(enabled: !sender.isSelected)
    }
    
    @objc func rejectButtonAction(sender: UIButton) {
        print("\(#function)")

        sender.isSelected = !sender.isSelected
        self.stopSounds()
        self.onRejected?()
    }
    
    @objc func acceptButtonAction(sender: UIButton) {
        print("\(#function)")

        sender.isSelected = !sender.isSelected
        acceptButtonCoverView.isHidden = false
        self.onAccepted?()
        self.stopSounds()
        self.onTapAccepted()
    }

    private lazy var cameraEnabledButton: UIButton = {
        let v = UIButton(type: .custom)
        v.setImage(UIImage(nameInBundle: "video_close"), for: .normal)
        v.setImage(UIImage(nameInBundle: "video_open"), for: .selected)
        
        v.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                
                cameraEnabledButtonAction(sender: v)
            }).disposed(by: disposeBag)
        
        return v
    }()
    
    @objc func cameraEnabledButtonAction(sender: UIButton) {
        print("\(#function)")
        
        sender.isSelected = !sender.isSelected
        sender.isEnabled = false
        switchCameraButton.isEnabled = !sender.isSelected
        
        Task {
            await toggleCameraEnabled()
            sender.isEnabled = true
        }
    }

    private lazy var switchCameraButton: UIButton = {
        let v = UIButton(type: .custom)
        v.setImage(UIImage(nameInBundle: "trun_camera_flag"), for: .normal)

        v.rx.tap.throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                
                cameraPositionButtonAction(sender: v)
            }).disposed(by: disposeBag)
        
        return v
    }()
    
    @objc func cameraPositionButtonAction(sender: UIButton) {
        print("\(#function)")
        
        sender.isSelected = !sender.isSelected
        sender.isEnabled = false
        
        Task {
            await switchCameraPosition()
            sender.isEnabled = true
        }
    }
    
    internal func setupTopFuncButtons() {
        minimizeButton.setImage(UIImage(nameInBundle: "minimize"), for: .normal)
        minimizeButton.addTarget(self, action: #selector(scale), for: .touchUpInside)
        
        view.addSubview(minimizeButton)
        
        minimizeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(24)
            make.leading.equalToSuperview().offset(24)
            make.width.equalTo(33)
            make.height.equalTo(30)
        }

        if !isSignal {
            view.addSubview(linkedTimeLabel)
            linkedTimeLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalTo(minimizeButton)
            }
        } else {
            if isVideo {
                view.addSubview(linkedTimeLabel)
                linkedTimeLabel.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    
                    funcBttonsView != nil ?
                    make.centerY.equalTo(funcBttonsView!.snp.top).inset(48) :
                    make.centerY.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(134)

                }
            }
        }
    }
    
    func onlineTopMoreFuncButtons() {
        guard isVideo else { return }
        
        view.addSubview(cameraEnabledButton)
        cameraEnabledButton.snp.makeConstraints { make in
            
            make.centerY.equalTo(minimizeButton)
            make.width.height.equalTo(minimizeButton)
        }
        
        view.addSubview(switchCameraButton)
        switchCameraButton.snp.makeConstraints { make in
            
            make.centerY.equalTo(minimizeButton)
            make.leading.equalTo(cameraEnabledButton.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(24)
            make.width.height.equalTo(minimizeButton)
        }
    }

    internal func onlineFuncButtons() {

        funcBttonsView?.removeFromSuperview()
        funcBttonsView = UIStackView(arrangedSubviews: [micButton, cancelButton, thirdButton])
        funcBttonsView!.axis = .horizontal
        funcBttonsView!.distribution = .fillEqually
        view.addSubview(funcBttonsView!)
        
        funcBttonsView!.snp.remakeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-48)
            make.leading.trailing.equalToSuperview()
        }
    }

    internal func senderPreviewFuncButtons() {
        onlineFuncButtons()
    }
    
    internal func previewFuncButtons() {

        let cancelButton = UIButton()
        cancelButton.setImage(UIImage(nameInBundle: "hang_up"), for: .normal)
        cancelButton.addTarget(self, action: #selector(rejectButtonAction), for: .touchUpInside)
        
        let pickUpButton = UIButton()
        pickUpButton.setImage(.init(nameInBundle: "pick_up"), for: .normal)
        pickUpButton.addTarget(self, action: #selector(acceptButtonAction), for: .touchUpInside)
        
        pickUpButton.addSubview(acceptButtonCoverView)
        acceptButtonCoverView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.width.equalTo(pickUpButton.imageView!)
        }
        
        funcBttonsView?.removeFromSuperview()
        funcBttonsView = UIStackView(arrangedSubviews: [cancelButton, pickUpButton])
        funcBttonsView!.axis = .horizontal
        funcBttonsView?.distribution = .fillEqually
        view.addSubview(funcBttonsView!)
        
        funcBttonsView!.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-48)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    internal func playSounds() {
        ringToneQueue.cancelAllOperations()
        
        ringToneQueue.addBarrierBlock { [self] in
            
            if let path = Bundle.callingBundle().path(forResource: "call_ring", ofType: "mp3") {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
                    try session.setActive(true)
                    
                    let url = URL(fileURLWithPath: path)
                    audioPlayer = try? AVAudioPlayer(contentsOf: url)
                    audioPlayer!.play()
                    audioPlayer!.numberOfLoops = 99
                    
                } catch {
                    print(error)
                }
            }
        }
    }
    
    internal func stopSounds() {
        ringToneQueue.addOperation { [self] in
            if audioPlayer?.isPlaying == true {
                audioPlayer?.pause()
            }
        }
    }
    
    internal func publishMicrophone() {
        Task {
            do {
                await try room.localParticipant.setMicrophone(enabled: true)
                
                if self.micButton.isSelected {
                    await self.toggleMicrophoneEnabled(forceEnable: false)
                }
            } catch (let error) {
                print("Failed to publish microphone, error: \(error)")
            }
        }
    }

    internal func toggleMicrophoneEnabled(forceEnable: Bool? = nil) async -> Bool {
        let enable = forceEnable ?? !room.localParticipant.isMicrophoneEnabled()
        
        do {
            return (try await room.localParticipant.setMicrophone(enabled: enable)) != nil
        } catch (let error) {
            print("Failed to publish microphone, error: \(error)")
            return false
        }
    }

    internal func switchCameraPosition() async -> Bool {
        
        guard let track = room.localParticipant.firstCameraPublication?.track as? LocalVideoTrack,
              let cameraCapturer = track.capturer as? CameraCapturer,
              (try? await CameraCapturer.canSwitchPosition()) == true
        else {
            print("Track or a CameraCapturer doesn't exist")
            return false
        }
        
        do {
            return try await cameraCapturer.switchCameraPosition()
        } catch (let error) {
            print("\(#function) throw an error: \(error)")
            return false
        }
    }

    internal func toggleCameraEnabled() async -> Bool  {
        let enable = !room.localParticipant.isCameraEnabled()
        
        do {
            return (try await room.localParticipant.setCamera(enabled: enable) != nil)
        } catch (let error) {
            print("\(#function) throw an error: \(error)")
            return false
        }
    }

    internal func toggleSpeakerphoneEnabled(enabled: Bool = true) {
        print("toggleSpeakerphoneEnabled:\(enabled)")
        do {
            let session = AVAudioSession.sharedInstance()
            
            if !enabled {
                try session.setCategory(.playAndRecord, mode: .default, options: .allowBluetooth)
                try session.overrideOutputAudioPort(.none)
            } else {
                try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
                try session.overrideOutputAudioPort(.speaker)
            }
            try session.setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    private func connectRoom(url: String, token: String) {
        showLinkingView()
        if isSignal {
            stopSounds()
        }
        
        Task {
            do {
                let roomOptions = RoomOptions(
                    defaultCameraCaptureOptions: CameraCaptureOptions(
                        position: .front,
                        dimensions: .h720_169,
                        fps: 30
                    ),
                    defaultVideoPublishOptions: VideoPublishOptions(preferredCodec: .vp8),
                    adaptiveStream: true,
                    dynacast: true
                )
                
                iLogger.print("connect live kit room, url: \(url), token: \(token)")
                
                try await room.connect(url: url, token: token, roomOptions: roomOptions)
                showLinkingView(show: false)
                
                if !isSignal {
                    onlineFuncButtons()
                }
                publishMicrophone()
                onlineTopMoreFuncButtons()
                
                if let publication = try await room.localParticipant.setCamera(enabled: isVideo) {
                    return true
                } else {
                    return false
                }
            } catch (let error) {
                onConnectFailure?()
                showLinkingView(show: false)
                iLogger.print("connect livekit throw an error: \(error)", functionName: "\(#function)")
                
                return false
            }
        }
    }

    internal func insertLinkingViewAbove(aboveView: UIView) {
        view.insertSubview(linkingView, aboveSubview: aboveView)
        
        linkingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(50)
        }
    }

    internal func showLinkingView(show: Bool = true) {
        if show {
            linkingView.isHidden = false
            linkingView.play()
        } else {
            linkingView.isHidden = true
            linkingView.stop()
        }
    }

    internal func linkingTimer(fire: Bool = true) {
        if linkedTimer != nil {
            return
        }
        
        linkedTimer = Timer.scheduledTimer(withTimeInterval: 1,
                                           repeats: true) { [weak self] _ in
            
            guard let wself = self else { return }
            
            wself.linkingDuration += 1
            let m = wself.linkingDuration / 60
            let s = wself.linkingDuration % 60
            
            var timeline = ""
            
            if m > 99 {
                timeline = String(format: "%d:%02d", m, s)
            } else {
                timeline = String(format: "%02d:%02d", m, s)
            }
            
            wself.tipsLabel.text = timeline
            wself.linkedTimeLabel.text = timeline

            wself.updateSuspendTips(text: timeline)
        }
    }

    internal func onTapAccepted() {}
}

