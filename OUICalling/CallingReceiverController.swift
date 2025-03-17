
import AVFoundation
import Foundation
import LiveKitClient
import Lottie
import RxSwift
import SnapKit
import OUICore
import ProgressHUD

public class CallingReceiverController: CallingBaseController {
    
    private var signal: ReceiverSignalViewController?
    private var isPresented: Bool = false

    public var duration: Int {
        signal?.linkingDuration ?? 0
    }
    
    public override func connectRoom(liveURL: String, token: String) {
        signal?.connectRoom(liveURL: liveURL, token: token)
    }

    public override func dismiss() {
        isPresented = false
        signal?.dismiss()
    }

    public override func startLiveChat(inviter: @escaping UserInfoHandler,
                                       others: @escaping UserInfoHandler,
                                       isVideo: Bool = true) {
        if isPresented {
            return
        }
        isPresented = true
        
        signal = ReceiverSignalViewController()
        signal!.inviter = inviter
        signal!.users = others
        signal!.isVideo = isVideo
        signal!.onAccepted = onAccepted
        signal!.onRejected = onRejected
        signal!.onHungup = onHungup
        signal!.onDisconnect = onDisconnect
        signal!.onConnectFailure = onConnectFailure
        
        signal!.modalPresentationStyle = .overCurrentContext
        UIViewController.currentViewController().present(signal!, animated: true)
    }
}

class ReceiverSignalViewController: CallingBaseViewController {
    private var verStackView: UIStackView?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        playSounds()
        room.add(delegate: self)
        setupView()
    }
    
    func setupView() {
        let inviter = inviter().first
        let avatarView = AvatarView()
        avatarView.setAvatar(url: inviter?.faceURL, text: inviter?.nickname)
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(70)
        }
        
        let nameLabel = UILabel()
        nameLabel.layer.cornerRadius = 6
        nameLabel.layer.masksToBounds = true
        nameLabel.text = inviter?.nickname
        nameLabel.font = .systemFont(ofSize: 28)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .white
        
        if !isVideo {
            let infoStackView = UIStackView(arrangedSubviews: [avatarView, nameLabel, tipsLabel])
            infoStackView.axis = .vertical
            infoStackView.spacing = 24
            infoStackView.alignment = .center
            
            tipsLabel.text = "invitedVoiceCallHint".innerLocalized()
            verStackView = UIStackView(arrangedSubviews: [infoStackView, UIView()])
        } else {
            let infoStackView = UIStackView(arrangedSubviews: [nameLabel, tipsLabel])
            infoStackView.axis = .vertical
            infoStackView.distribution = .equalSpacing
            infoStackView.alignment = .leading
            
            let rowStackView = UIStackView(arrangedSubviews: [SizeBox(width: 24), avatarView, SizeBox(width: 8), infoStackView, SizeBox(width: 24)])
            rowStackView.axis = .horizontal
            rowStackView.spacing = 8
            
            tipsLabel.text = "invitedVideoCallHint".innerLocalized()
            verStackView = UIStackView(arrangedSubviews: [rowStackView, UIView()])
        }
        
        verStackView!.axis = .vertical
        verStackView!.distribution = .equalSpacing
        view.addSubview(verStackView!)
        
        verStackView!.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(minimizeButton.snp_bottom).offset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        insertLinkingViewAbove(aboveView: verStackView!)
        previewFuncButtons()
    }
}

extension ReceiverSignalViewController: RoomDelegate {
    func room(_ room: Room, didFailToConnectWithError error: LiveKitError?) {
        iLogger.print("\(#function): \(error?.message)")
        onConnectFailure?()
        dismiss()
    }
    
    func room(_ room: Room, didUpdateConnectionState connectionState: ConnectionState, from oldValue: ConnectionState) {
        iLogger.print("\(#function): \(connectionState)")
        DispatchQueue.main.async { [self] in
            if case .disconnected = connectionState {
                onDisconnect?()
            } else if case .connected = connectionState {
                publishMicrophone()
            }
        }
    }
    
    func roomIsReconnecting(_ room: Room) {
        iLogger.print("\(#function)")
        poorNetwork = true
    }
    
    func roomDidReconnect(_ room: Room) {
        iLogger.print("\(#function)")
        poorNetwork = false
    }
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        iLogger.print("\(#function): \(participant.metadata)")
        linkingTimer()
    }
    
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        iLogger.print("\(#function): \(participant.metadata)")
        
        let identityString = participant.identityString
        
        if poorNetwork {
            ProgressHUD.text("callingInterruption".localized())
        }
    }
    
    func room(_ room: Room, participant: Participant, didUpdateConnectionQuality quality: ConnectionQuality) {
        iLogger.print("\(#function): participant: \(participant.metadata) quality: \(quality)")
        guard room.connectionState != .disconnected else { return }
        
        if quality == .lost || quality == .poor {
            poorNetwork = true
            
            let isMine = participant.identity == room.localParticipant.identity
            
            ProgressHUD.text(isMine ? "networkNotStable".localized() : "otherNetworkNotStableHint".localized())
        } else {
            poorNetwork = false
        }
    }
    
    func room(_ room: Room, participant localParticipant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        iLogger.print("\(#function)")
        DispatchQueue.main.async { [self] in
            onlineFuncButtons()
            showLinkingView(show: false)
            linkingTimer()
        }
        guard let track = localParticipant.firstCameraVideoTrack else {
            iLogger.print("receiver did publish track return")
            return
        }
        
        DispatchQueue.main.async { [self, track] in
            self.smallTrack = track
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        iLogger.print("\(#function) participant: \(participant.metadata) subscribe \(publication.name)")
        DispatchQueue.main.async { [self, participant] in
            if isVideo {
                if let track = participant.firstCameraVideoTrack {

                    self.bigTrack = track
                }
                verStackView?.isHidden = true
            }
            linkingTimer()
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        iLogger.print("\(#function) participant: \(participant.metadata) subscribe \(publication.name)")
        if linkedTimer != nil, participant.identityString == inviter().first?.userID {
            linkedTimer = nil
            DispatchQueue.main.async { [self] in
                if !room.allParticipants.isEmpty {

                }
            }
        }
    }
    
    func room(_ room: Room, participant: Participant, trackPublication publication: TrackPublication, didUpdateIsMuted muted: Bool) {
        if publication.kind == .video, publication.source != .microphone {
            DispatchQueue.main.async { [self] in
                let participantUser = CallingUserInfo(userID: participant.identityString, nickname: participant.showName, faceURL: participant.faceURL)

                if let user = inviter().first, participant.identityString == user.userID {
                    remoteMuted = muted
                    
                    if smallViewIsMe {
                        bigDisableVideoImageView.isHidden = !muted
                        setupBigPlaceholerView(user: participantUser)
                    } else {
                        smallDisableVideoImageView.isHidden = !muted
                        setupSmallPlaceholerView(user: participantUser)
                    }
                } else if let user = users().first, participant.identityString == user.userID {
                    localMuted = muted
                    
                    if smallViewIsMe {
                        smallDisableVideoImageView.isHidden = !muted
                        setupSmallPlaceholerView(user: participantUser)
                    } else {
                        bigDisableVideoImageView.isHidden = !muted
                        setupBigPlaceholerView(user: participantUser)
                    }
                }
            }
        }
    }
}
