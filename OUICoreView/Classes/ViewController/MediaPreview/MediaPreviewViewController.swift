
import Lantern
import AVKit
import Kingfisher
import ProgressHUD
import OUICore

public enum PreviewMediaType {
    case image
    case video
    case gif
}

public struct MediaResource {
    public let thumbUrl: URL?
    public let url: URL
    public let type: PreviewMediaType
    public let ID: String?
    public let fileSize: Int
    
    public init(thumbUrl: URL? = nil, url: URL, type: PreviewMediaType = .image, ID: String? = nil, fileSize: Int = 0) {
        self.thumbUrl = thumbUrl
        self.url = url
        self.type = type
        self.ID = ID
        self.fileSize = fileSize
    }
}

public class MediaPreviewViewController {
    
    private let lantern: Lantern = {
        let v = Lantern()
        v.setStatusBar(hidden: true)
        return v
    }()
    
    public var onDelete: ((Int) -> Void)?
    public var onButtonAction: ((PreviewModalView.ActionType) -> Void)?
    public var onDismiss: (() -> Void)?
    
    private var showIndicator = false
    private let modalView = PreviewModalView()
    
    public init(resources: [MediaResource], index: Int = 0, showIndicator: Bool = false) {
        self.dataSource = resources
        self.showIndicator = showIndicator
        self.currentIndex = index
    }
    
    public func showIn(controller: UIViewController, senders: [UIView] = []) {
        if !senders.isEmpty {
            lantern.transitionAnimator = LanternZoomAnimator(previousView: { index -> UIView? in
                return senders[index]
            })
        }
        
        DispatchQueue.main.async { [self] in
            self.setupBrowers()
            self.lantern.show(method: .present(fromVC: controller, embed: nil))
        }
    }
    
    public func showIn(controller: UIViewController, sender: ((_ index: Int) -> UIView?)? = nil) {
        
        if let sender {
            lantern.transitionAnimator = LanternZoomAnimator(previousView: { index -> UIView? in
                sender(index)
            })
        }
        self.setupBrowers()
        self.lantern.show(method: .present(fromVC: controller, embed: nil))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var dataSource: [MediaResource]!
    private var currentIndex = 0












    private func setupBrowers() {
        lantern.pageIndex = currentIndex
        
        if showIndicator {
            let indicator = PageIndicator()
            lantern.pageIndicator = indicator
            
            if onDelete != nil {
                indicator.deleteButton.isHidden = false
                indicator.onDelete = { [weak self, weak lantern] index in
                    guard let self, let lantern else { return }
                    dataSource.remove(at: index)
                    onDelete!(index)
                    lantern.reloadData()
                }
            }
        }
        
        lantern.numberOfItems = { [weak self] in
            self?.dataSource.count ?? 0
        }
        lantern.cellClassAtIndex = { [weak self] index in
            guard let self else { return ImageZoomCell.self }
            let resource = self.dataSource[index]
            return resource.type == .video ? VideoZoomCell.self : ImageZoomCell.self
        }
        lantern.reloadCellAtIndex = { [weak self] context in
            guard let resource = self?.dataSource[context.index] else { return }
            if resource.type == .video {
                let lanternCell = context.cell as? VideoZoomCell
                
                lanternCell?.setInfo(thumbPath: resource.thumbUrl?.relativeString, videoURL: resource.url, autoPlay: context.index == self?.currentIndex)
                
                lanternCell?.frameChangedHandler = { [weak self] frame in

                }
                lanternCell?.dismissHandler = { [weak self] in
                    self?.dismissView()
                    self?.onDismiss?()
                }
                lanternCell?.longPressedHandler = { [weak self, weak lanternCell] in
                    guard let self else { return }
                    modalView.show()
                    modalView.onButtonAction = { [self] type in
                        switch type {
                        case .save:
                            PhotoHelper().saveVideoToAlbum(path: resource.url.absoluteString, fileSize: resource.fileSize)
                        case .forward:
                            self.dismissView()
                            self.onButtonAction?(type)
                        }
                    }
                }
                
                lanternCell?.singleTapHandler = { [weak self] in
                    PhotoHelper().saveVideoToAlbum(path: resource.url.absoluteString)
                }
            } else {
                let lanternCell = context.cell as? ImageZoomCell
                if let thumb = resource.thumbUrl?.absoluteString {
                    
                    if thumb.lowercased().hasSuffix(".gif") {
                        DispatchQueue.main.async {
                            lanternCell?.imageView.kf.setImage(with: thumb.defaultThumbnailURL)
                        }
                    } else {
                        print("image url: \(resource.url.absoluteString), thumb url: \(resource.thumbUrl?.absoluteString ?? "")")
                        lanternCell?.imageView.setImage(url: resource.url, thumbURL: resource.thumbUrl)
                    }
                }
                
                lanternCell?.frameChangedHandler = { [weak self] frame in

                }
                lanternCell?.dismissHandler = { [weak self] in
                    self?.dismissView()
                }
                lanternCell?.longPressedAction = { [weak self, weak lanternCell] (cell, state) in
                    guard let self, let image = cell.imageView.image else { return }
                    modalView.show()
                    modalView.onButtonAction = { [self] type in
                        switch type {
                        case .save:
                            PhotoHelper().saveImageToAlbum(image: image)
                        case .forward:
                            self.dismissView()
                            self.onButtonAction?(type)
                        }
                    }
                }
            }
        }
        lantern.cellDidAppear = { [weak self] cell, index in
            self?.currentIndex = index
        }
    }
    
    private func dismissView() {

    }
    
    deinit {
        print("media preview deinit")
    }
}
