
import LiveKitClient
import OUICore
import SnapKit
import RxSwift
import Lottie

public class ParticipantCellUserView: UIView {
    let disposeBag = DisposeBag()

    lazy var avatarView: AvatarView = {
        let v = AvatarView()
        v.layer.masksToBounds = true
        
        return v
    }()
    
    lazy var linkingView: AnimationView = {
        let bundle = Bundle.callingBundle()
        let v = AnimationView(name: "linking", bundle: bundle)
        v.loopMode = .loop
        v.play()
        
        return v
    }()
    
    lazy var overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = .c0C1C33.withAlphaComponent(0.7)
        
        return v
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        
        addSubview(avatarView)
        avatarView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addSubview(linkingView)
        linkingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(100)
        }
    }
}

open class ParticipantCellDefaultView: UIView {
    
    let disposeBag = DisposeBag()

    lazy var avatarView: AvatarView = {
        let v = AvatarView()
        
        return v
    }()
    
    public lazy var hosterImageView: UIImageView = {
        let v = UIImageView(image: UIImage(nameInBundle: "hoster_icon"))
        v.isHidden = true
        
        return v
    }()
    
    lazy var nameLabel: UILabel = {
        let v = UILabel()
        v.textAlignment = .center
        v.textColor = .white
        v.font = .f14
        
        return v
    }()
    
    lazy var micImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.image = UIImage(nameInBundle: "mic_open_flag")
        v.highlightedImage = UIImage(nameInBundle: "mic_close_flag")
        
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .c666666
        
        let nameView: UIView = {
            let v = UIView()
            v.layer.cornerRadius = 5
            v.backgroundColor = .c0C1C33.withAlphaComponent(0.3)
            let nameRow = UIStackView(arrangedSubviews: [nameLabel, micImageView])
            nameRow.spacing = 4
            
            v.addSubview(nameRow)
            nameRow.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(4)
            }
            
            return v
        }()
        
        micImageView.snp.makeConstraints { make in
            make.size.equalTo(15)
        }
        
        let hStack = UIStackView(arrangedSubviews: [hosterImageView, nameView, UIView()])
        hStack.spacing = 8
        hStack.alignment = .center
        
        addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview().inset(8)
            make.height.equalTo(24)
        }
        
        addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum ParticipantCellAction {
    case camera
    case tap
}

open class ParticipantCell: UICollectionViewCell {
    
    public static let reuseIdentifier: String = "ParticipantCell"
    public static var instanceCounter: Int = 0
    
    public let cellId: Int
    public var videoForceEnable: Bool = false
    public var onTap: ((_ action: ParticipantCellAction) -> Void)?
    public var onDoubleTap: (() -> Void)?
    
    public lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.maximumZoomScale = 2.0
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.contentInsetAdjustmentBehavior = .never
        v.delegate = self
        
        return v
    }()
    
    public var videoView: VideoView!

    public lazy var infoView: ParticipantCellDefaultView = {
        let v = ParticipantCellDefaultView()
        
        return v
    }()
    
    
    public lazy var loadingView: ParticipantCellUserView = {
        let v = ParticipantCellUserView()
        v.isHidden = true
        
        return v
    }()
    
    let disableCameraImageView: UIImageView = {
        let r = UIImageView(image: .init(nameInBundle: "video_close"))
        r.contentMode = .center
        r.backgroundColor = .init(red: 46 / 255, green: 46 / 255, blue: 46 / 255, alpha: 1)
        r.isHidden = true
        
        return r
    }()
    
    let speakingView: UIView = {
        let t = UIView()
        t.backgroundColor = .clear
        t.layer.borderColor = UIColor.systemBlue.cgColor
        t.layer.borderWidth = 2.0
        t.isHidden = true
        
        return t
    }()

    public weak var participant: Participant? {
        didSet {
            if participant != nil, participant!.identity == oldValue?.identity {
                return
            }
            
            if let oldValue {


                oldValue.remove(delegate: self)
                videoView.track = nil
            }
            
            if let participant {
                resetFrame()
                scrollView.setZoomScale(1.0, animated: false)

                participant.add(delegate: self)
                setFirstVideoTrack()
                infoView.nameLabel.text = participant.showName
                infoView.avatarView.setAvatar(url: participant.faceURL, text: participant.showName)

                if videoForceEnable {
                    isVideoEnable = true
                } else {
                    isVideoEnable = participant.isCameraEnabled() || participant.isScreenShareEnabled()
                }
                
                isMicEnable = participant.isMicrophoneEnabled()
                print("member's info:\(participant.identityString)")

                setNeedsLayout()
            }
        }
    }
    
    private var isZoomedIn = false
    
    override public init(frame: CGRect) {
        Self.instanceCounter += 1
        self.cellId = Self.instanceCounter
        
        super.init(frame: frame)
        print("\(String(describing: self)) init, instances: \(Self.instanceCounter)")
        backgroundColor = .systemGray4
        
        videoView = setupVideoView()
        
        contentView.addSubview(scrollView)
        scrollView.addSubview(videoView)
        
        contentView.addSubview(disableCameraImageView)
        disableCameraImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.addSubview(infoView)
        infoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.addSubview(speakingView)
        speakingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.isUserInteractionEnabled = true

        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        contentView.addGestureRecognizer(singleTapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTapGesture)

        singleTapGesture.require(toFail: doubleTapGesture)
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var zoomIn = false
    
    deinit {
        Self.instanceCounter -= 1
        
        print("\(String(describing: self)) deinit, instances: \(Self.instanceCounter)")
    }
    
    private func setupVideoView() -> VideoView {
        let r = VideoView()
        r.layoutMode = .fill
        r.backgroundColor = .darkGray
        r.clipsToBounds = true
        r.isUserInteractionEnabled = false
        r.subviews.map({ $0.isUserInteractionEnabled = false })
        
        return r
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            
            if let onDoubleTap {
                onDoubleTap()
            } else {
                if !zoomIn {

                    let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: gesture.location(in: videoView))
                    scrollView.zoom(to: zoomRect, animated: true)
                    
                    zoomIn = true
                } else {

                    scrollView.zoom(to: videoView.bounds, animated: true)
                    resetFrame()
                    videoView.center = computeContentLayoutCenter(in: scrollView)
                    videoView.setNeedsLayout()
                    
                    zoomIn = false
                }
            }
        }
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        zoomRect.size.width = scrollView.frame.size.width / scale
        zoomRect.size.height = scrollView.frame.size.height / scale
        
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        
        if scrollView.zoomScale != scrollView.minimumZoomScale {
            scrollView.zoom(to: videoView.bounds, animated: true)
            videoView.setNeedsLayout()
            
            zoomIn = false
        }
        onTap?(.tap)
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        print("prepareForReuse, cellId: \(cellId)")
        
        videoView.removeFromSuperview()
        videoView = nil
        videoView = setupVideoView()
        scrollView.addSubview(videoView)
        
        infoView.hosterImageView.isHidden = true
        participant = nil
        loadingView.isHidden = true
        loadingView.linkingView.isHidden = false
        loadingView.overlayView.isHidden = false
        zoomIn = false
    }
    
    private func resetFrame() {
        scrollView.frame = CGRect(origin: .zero, size: frame.size)
        videoView.frame = CGRect(origin: .zero, size: frame.size)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if frame.size != scrollView.frame.size {
            resetFrame()
            scrollView.contentSize = scrollView.frame.size
        }
        
        if videoView.frame.origin != .zero {
            scrollView.zoom(to: videoView.bounds, animated: true)
            scrollView.contentSize = scrollView.frame.size
            videoView.frame.origin = .zero
            videoView.center = computeContentLayoutCenter(in: scrollView)
        }
    }
    
    private func setFirstVideoTrack() {
        var track = participant?.firstScreenShareVideoTrack ?? participant?.firstCameraVideoTrack
        
        print("\(#function) : \(track)")
        videoView.track = track
        isVideoEnable = track != nil
    }
    
    private var isMicEnable: Bool = true {
        didSet {
            infoView.micImageView.isHighlighted = !isMicEnable
        }
    }
    
    private var isVideoEnable: Bool = true {
        didSet {
            disableCameraImageView.isHidden = isVideoEnable
            changeInfoByVideoEnable(enable: isVideoEnable)
        }
    }
    
    open func changeInfoByVideoEnable(enable: Bool) {
        infoView.avatarView.isHidden = enable
        infoView.backgroundColor = enable ? .clear : .c666666
    }
}

extension ParticipantCell: ParticipantDelegate {
    public func participant(_ participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        print("\(#function)")
        DispatchQueue.main.async { [weak self] in
            self?.setFirstVideoTrack()
        }
    }
    
    public func participant(_ participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        print("\(#function)")
        DispatchQueue.main.async { [weak self] in
            self?.setFirstVideoTrack()
        }
    }
    
    public func participant(_ participant: Participant, didUpdateIsSpeaking speaking: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.speakingView.isHidden = !speaking
        }
    }
    
    public func participant(_ participant: Participant, trackPublication publication: TrackPublication, didUpdateIsMuted muted: Bool) {
        print("\(#function) muted \(String(describing: participant.showName)) - \(publication.kind) status:\(!muted)")
        DispatchQueue.main.async { [weak self] in
            if publication.kind == .audio {
                self?.isMicEnable = !muted
            } else {
                self?.isVideoEnable = !muted
            }
        }
    }
    
    public func participant(_ participant: RemoteParticipant, trackPublication publication: RemoteTrackPublication, didUpdateStreamState streamState: StreamState) {
        print("\(#function) stream state:\(streamState)")
    }
    
    public func participant(_ participant: Participant, didUpdateConnectionQuality connectionQuality: ConnectionQuality) {
        print("\(#function) stream state:\(connectionQuality)")
    }
}

extension ParticipantCell: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return videoView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        videoView.center = computeContentLayoutCenter(in: scrollView)
    }
    
    func computeContentLayoutCenter(in scrollView: UIScrollView) -> CGPoint {
        var x = scrollView.contentSize.width * 0.5
        var y = scrollView.contentSize.height * 0.5
        let offsetX = (bounds.width - scrollView.contentSize.width) * 0.5
        if offsetX > 0 {
            x += offsetX
        }
        let offsetY = (bounds.height - scrollView.contentSize.height) * 0.5
        if offsetY > 0 {
            y += offsetY
        }
        
        return CGPoint(x: x, y: y)
    }
}

extension Participant {
    public var metadataMap: [String: Any]? {
        if let metadata = metadata, !metadata.isEmpty {
            let data = try! JSONSerialization.jsonObject(with: metadata.data(using: .utf8)!, options: .allowFragments) as! [String: Any]
            return data
        }
        
        return nil
    }
    
    public var showName: String? {
        if let data = metadataMap {
            let userInfo = data["userInfo"] as? [String: Any]
            let name = userInfo?["nickname"] as? String
            
            return name
        }
        
        return nil
    }
    
    public var faceURL: String? {
        if let data = metadataMap {
            let userInfo = data["userInfo"] as? [String: Any]
            let faceURL = userInfo?["faceURL"] as? String
            
            return faceURL
        }
        
        return nil
    }
    
    public var identityString: String? {
        identity?.stringValue
    }
}

