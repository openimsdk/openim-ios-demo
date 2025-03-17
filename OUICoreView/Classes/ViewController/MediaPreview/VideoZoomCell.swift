
import UIKit
import Foundation
import OUICore
import AVFoundation
import Lantern
import ZFPlayer
import KTVHTTPCache
import Kingfisher

class VideoZoomCell: UIView, UIScrollViewDelegate, UIGestureRecognizerDelegate, LanternCell, LanternZoomSupportedCell {

    weak var lantern: Lantern?
    
    var frameChangedHandler: ((CGRect) -> Void)?
    var dismissHandler: (() -> Void)?
    var singleTapHandler: (() -> Void)?
    var longPressedHandler: (() -> Void)?
    
    func setInfo(thumbPath: String?, videoURL: URL?, autoPlay: Bool = false) {
        if var videoURL, playerManager.assetURL != videoURL {
            
            var result = videoURL
            
            if videoURL.isFileURL {
                let exist = FileManager.default.fileExists(atPath: videoURL.path)
                print("\(#function): video exsit: \(exist)")
            } else {
                var temp = KTVHTTPCache.cacheCompleteFileURL(with: videoURL)
                    
                if temp == nil {
                    temp = KTVHTTPCache.proxyURL(withOriginalURL: videoURL)
                }
                if let temp {
                    result = temp
                }
            }
            print("\(#function): video URL \(result ?? videoURL)")

            let options = ["AVURLAssetOutOfBandMIMETypeKey": "video/mp4; codecs=\"avc1.42E01E, mp4a.40.2\""]
            playerManager.requestHeader = options
            playerManager.assetURL = result ?? videoURL
            playerManager.shouldAutoPlay = autoPlay
            
            if let thumbPath {
                
                let cacheImage = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: thumbPath)
                
                if let cacheImage {
                    playerManager.view.coverImageView.image = cacheImage
                } else {
                    controlView.showTitle("", coverURLString: thumbPath, fullScreenMode: .portrait)
                }
            } else {
                controlView.showTitle("", coverURLString: thumbPath, fullScreenMode: .portrait)
            }
            
            controlView.resetControlView()
        } else {
            playerManager.assetURL = nil
        }
    }

    var index: Int = 0
    
    private lazy var contentView: UIView = {
        let v = UIView()
        v.frame = bounds
        v.layer.masksToBounds = true
        
        return v
    }()
    
    private lazy var scrollView: UIScrollView = {
        let v = UIScrollView()
        v.maximumZoomScale = 2.0
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.contentInsetAdjustmentBehavior = .never
        v.delaysContentTouches = false
        v.frame = bounds
        
        return v
    }()
    
    private var player: ZFPlayerController!
    
    private lazy var playerManager: ZFAVPlayerManager = ZFAVPlayerManager()
    
    private lazy var controlView: ZFPlayerControlView = {
        let v = ZFPlayerControlView()
        v.fastViewAnimated = true
        v.effectViewShow = false
        v.prepareShowLoading = true
        v.showCustomStatusBar = true
        v.customDisablePanMovingDirection = true
        v.prepareShowLoading = true
        v.prepareShowControlView = true
        v.portraitControlView.fullScreenBtn.setImage(UIImage(systemName: "ellipsis")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        v.portraitControlView.fullScreenBtn.removeTarget(v.portraitControlView, action: nil, for: .touchUpInside)
        v.portraitControlView.fullScreenBtn.addTarget(self, action: #selector(handleMoreAction(_:)), for: .touchUpInside)
        
        return v
    }()
    
    @objc private func handleMoreAction(_ sender: UIButton) {
        let actionSheet = UIActionSheet(title: nil,
                                        delegate: self,
                                        cancelButtonTitle: "cancel".innerLocalized(),
                                        destructiveButtonTitle: nil,
                                        otherButtonTitles: "download".innerLocalized())
        
        actionSheet.show(in: UIApplication.shared.keyWindow!)
    }
    
    private lazy var closeButton: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(systemName: "xmark"), for: .normal)
        v.tintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        v.addTarget(self, action: #selector(handleCloseAction(_:)), for: .touchUpInside)
        
        return v
    }()
    
    @objc
    private func handleCloseAction(_ sender: UIButton) {
        lantern?.dismiss()
        dismissHandler?()
    }
    
    deinit {
        player.stop()
        LanternLog.high("deinit - \(self.classForCoder)")
    }
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public static func generate(with lantern: Lantern) -> Self {
        let cell = Self.init(frame: .zero)
        cell.lantern = lantern
        return cell
    }
    
    private func setup() {
        backgroundColor = .clear
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 100.h),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
        
        player = ZFPlayerController(playerManager: playerManager, containerView: contentView)
        player.controlView = controlView
        player.disableGestureTypes = .pan
        player.disablePanMovingDirection = .horizontal
        
        controlView.backBtnClickCallback = { [weak self] in
            self?.player.stop()
        }

        addPanGesture()

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onSingleTap(_:)))
        addGestureRecognizer(singleTap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPress)
    }
    
    private weak var existedPan: UIPanGestureRecognizer?

    private func addPanGesture() {
        guard existedPan == nil else {
            return
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.delegate = self

        scrollView.addGestureRecognizer(pan)
        existedPan = pan
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        contentView.frame = bounds
        scrollView.setZoomScale(1.0, animated: false)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        contentView.center = computeContentLayoutCenter(in: scrollView)
    }
    
    func computeImageLayoutSize(for image: UIImage?, in scrollView: UIScrollView) -> CGSize {
        guard let imageSize = image?.size, imageSize.width > 0 && imageSize.height > 0 else {
            return .zero
        }
        var width: CGFloat
        var height: CGFloat
        let containerSize = scrollView.bounds.size
        if containerSize.width < containerSize.height {
            width = containerSize.width
            height = imageSize.height / imageSize.width * width
        } else {
            height = containerSize.height
            width = imageSize.width / imageSize.height * height
            if width > containerSize.width {
                width = containerSize.width
                height = imageSize.height / imageSize.width * width
            }
        }
        
        return CGSize(width: width, height: height)
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
    
    @objc
    private func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            longPressedHandler?()
        }
    }

    @objc open func onSingleTap(_ tap: UITapGestureRecognizer) {


    }
    
    private func hideWidgets(hidden: Bool = true) {
        UIView.animate(withDuration: 0.2) { [self] in
            closeButton.alpha = hidden ? 0.0 : 1.0
            lantern?.pageIndicator?.isHidden = hidden
        }
    }

    private var beganFrame = CGRect.zero

    private var beganTouch = CGPoint.zero

    @objc open func onPan(_ pan: UIPanGestureRecognizer) {

        switch pan.state {
        case .began:
            beganFrame = contentView.frame
            beganTouch = pan.location(in: scrollView)
        case .changed:
            let result = panResult(pan)
            contentView.frame = result.frame
            frameChangedHandler?(result.frame)
            
            lantern?.maskView.alpha = result.scale * result.scale
            lantern?.setStatusBar(hidden: result.scale > 0.99)
            hideWidgets(hidden: result.scale < 0.99)
            
            
        case .ended, .cancelled:
            contentView.frame = panResult(pan).frame
            frameChangedHandler?(panResult(pan).frame)
            hideWidgets()
            lantern?.dismiss()
            dismissHandler?()
        default:
            break
        }
    }

    private func panResult(_ pan: UIPanGestureRecognizer) -> (frame: CGRect, scale: CGFloat) {

        let translation = pan.translation(in: scrollView)
        let currentTouch = pan.location(in: scrollView)

        let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))
        
        let width = beganFrame.size.width * scale
        let height = beganFrame.size.height * scale


        let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
        let currentTouchDeltaX = xRate * width
        let x = currentTouch.x - currentTouchDeltaX
        
        let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
        let currentTouchDeltaY = yRate * height
        let y = currentTouch.y - currentTouchDeltaY
        
        return (CGRect(x: x.isNaN ? 0 : x, y: y.isNaN ? 0 : y, width: width, height: height), scale)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = pan.velocity(in: self)

        if velocity.y < 0 {
            return false
        }

        if abs(Int(velocity.x)) > Int(velocity.y) {
            return false
        }

        if scrollView.contentOffset.y > 0 {
            return false
        }

        return true
    }
    
    var showContentView: UIView {
        return contentView
    }
}

extension VideoZoomCell: UIActionSheetDelegate {
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        print(" index: \(buttonIndex)")
        if buttonIndex == 1 {
            singleTapHandler?()
        }
    }
}
