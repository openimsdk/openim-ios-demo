

























import UIKit
import Photos

public extension ZLPhotoConfiguration {
    @discardableResult
    func maxSelectCount(_ count: Int) -> ZLPhotoConfiguration {
        maxSelectCount = count
        return self
    }
    
    @discardableResult
    func maxVideoSelectCount(_ count: Int) -> ZLPhotoConfiguration {
        maxVideoSelectCount = count
        return self
    }
    
    @discardableResult
    func minVideoSelectCount(_ count: Int) -> ZLPhotoConfiguration {
        minVideoSelectCount = count
        return self
    }
    
    @discardableResult
    func allowMixSelect(_ value: Bool) -> ZLPhotoConfiguration {
        allowMixSelect = value
        return self
    }
    
    @discardableResult
    func maxPreviewCount(_ count: Int) -> ZLPhotoConfiguration {
        maxPreviewCount = count
        return self
    }
    
    @discardableResult
    func initialIndex(_ index: Int) -> ZLPhotoConfiguration {
        initialIndex = index
        return self
    }
    
    @discardableResult
    func allowSelectImage(_ value: Bool) -> ZLPhotoConfiguration {
        allowSelectImage = value
        return self
    }
    
    @discardableResult
    @objc func allowSelectVideo(_ value: Bool) -> ZLPhotoConfiguration {
        allowSelectVideo = value
        return self
    }
    
    @discardableResult
    @objc func downloadVideoBeforeSelecting(_ value: Bool) -> ZLPhotoConfiguration {
        downloadVideoBeforeSelecting = value
        return self
    }
    
    @discardableResult
    func allowSelectGif(_ value: Bool) -> ZLPhotoConfiguration {
        allowSelectGif = value
        return self
    }
    
    @discardableResult
    func allowSelectLivePhoto(_ value: Bool) -> ZLPhotoConfiguration {
        allowSelectLivePhoto = value
        return self
    }
    
    @discardableResult
    func allowTakePhotoInLibrary(_ value: Bool) -> ZLPhotoConfiguration {
        allowTakePhotoInLibrary = value
        return self
    }
    
    @discardableResult
    func callbackDirectlyAfterTakingPhoto(_ value: Bool) -> ZLPhotoConfiguration {
        callbackDirectlyAfterTakingPhoto = value
        return self
    }
    
    @discardableResult
    func allowEditImage(_ value: Bool) -> ZLPhotoConfiguration {
        allowEditImage = value
        return self
    }
    
    @discardableResult
    func allowEditVideo(_ value: Bool) -> ZLPhotoConfiguration {
        allowEditVideo = value
        return self
    }
    
    @discardableResult
    func editAfterSelectThumbnailImage(_ value: Bool) -> ZLPhotoConfiguration {
        editAfterSelectThumbnailImage = value
        return self
    }
    
    @discardableResult
    func cropVideoAfterSelectThumbnail(_ value: Bool) -> ZLPhotoConfiguration {
        cropVideoAfterSelectThumbnail = value
        return self
    }
    
    @discardableResult
    func showClipDirectlyIfOnlyHasClipTool(_ value: Bool) -> ZLPhotoConfiguration {
        showClipDirectlyIfOnlyHasClipTool = value
        return self
    }
    
    @discardableResult
    func saveNewImageAfterEdit(_ value: Bool) -> ZLPhotoConfiguration {
        saveNewImageAfterEdit = value
        return self
    }
    
    @discardableResult
    func allowSlideSelect(_ value: Bool) -> ZLPhotoConfiguration {
        allowSlideSelect = value
        return self
    }
    
    @discardableResult
    func autoScrollWhenSlideSelectIsActive(_ value: Bool) -> ZLPhotoConfiguration {
        autoScrollWhenSlideSelectIsActive = value
        return self
    }
    
    @discardableResult
    func autoScrollMaxSpeed(_ speed: CGFloat) -> ZLPhotoConfiguration {
        autoScrollMaxSpeed = speed
        return self
    }
    
    @discardableResult
    func allowDragSelect(_ value: Bool) -> ZLPhotoConfiguration {
        allowDragSelect = value
        return self
    }
    
    @discardableResult
    func allowSelectOriginal(_ value: Bool) -> ZLPhotoConfiguration {
        allowSelectOriginal = value
        return self
    }
    
    @discardableResult
    func alwaysRequestOriginal(_ value: Bool) -> ZLPhotoConfiguration {
        alwaysRequestOriginal = value
        return self
    }
    
    @discardableResult
    func allowPreviewPhotos(_ value: Bool) -> ZLPhotoConfiguration {
        allowPreviewPhotos = value
        return self
    }
    
    @discardableResult
    func showPreviewButtonInAlbum(_ value: Bool) -> ZLPhotoConfiguration {
        showPreviewButtonInAlbum = value
        return self
    }
    
    @discardableResult
    func showSelectCountOnDoneBtn(_ value: Bool) -> ZLPhotoConfiguration {
        showSelectCountOnDoneBtn = value
        return self
    }
    
    @discardableResult
    func showSelectBtnWhenSingleSelect(_ value: Bool) -> ZLPhotoConfiguration {
        showSelectBtnWhenSingleSelect = value
        return self
    }
    
    @discardableResult
    func showSelectedIndex(_ value: Bool) -> ZLPhotoConfiguration {
        showSelectedIndex = value
        return self
    }
    
    @discardableResult
    func maxEditVideoTime(_ second: Second) -> ZLPhotoConfiguration {
        maxEditVideoTime = second
        return self
    }
    
    @discardableResult
    func maxSelectVideoDuration(_ duration: Second) -> ZLPhotoConfiguration {
        maxSelectVideoDuration = duration
        return self
    }
    
    @discardableResult
    func minSelectVideoDuration(_ duration: Second) -> ZLPhotoConfiguration {
        minSelectVideoDuration = duration
        return self
    }
    
    @discardableResult
    func maxSelectVideoDataSize(_ size: ZLPhotoConfiguration.KBUnit) -> ZLPhotoConfiguration {
        maxSelectVideoDataSize = size
        return self
    }
    
    @discardableResult
    func minSelectVideoDataSize(_ size: ZLPhotoConfiguration.KBUnit) -> ZLPhotoConfiguration {
        minSelectVideoDataSize = size
        return self
    }
    
    @discardableResult
    func editImageConfiguration(_ configuration: ZLEditImageConfiguration) -> ZLPhotoConfiguration {
        editImageConfiguration = configuration
        return self
    }
    
    @discardableResult
    func useCustomCamera(_ value: Bool) -> ZLPhotoConfiguration {
        useCustomCamera = value
        return self
    }
    
    @discardableResult
    func cameraConfiguration(_ configuration: ZLCameraConfiguration) -> ZLPhotoConfiguration {
        cameraConfiguration = configuration
        return self
    }
    
    @discardableResult
    func canSelectAsset(_ block: ((PHAsset) -> Bool)?) -> ZLPhotoConfiguration {
        canSelectAsset = block
        return self
    }
    
    @discardableResult
    func didSelectAsset(_ block: ((PHAsset) -> Void)?) -> ZLPhotoConfiguration {
        didSelectAsset = block
        return self
    }
    
    @discardableResult
    func didDeselectAsset(_ block: ((PHAsset) -> Void)?) -> ZLPhotoConfiguration {
        didDeselectAsset = block
        return self
    }
    
    @discardableResult
    func maxFrameCountForGIF(_ frameCount: Int) -> ZLPhotoConfiguration {
        maxFrameCountForGIF = frameCount
        return self
    }
    
    @discardableResult
    func gifPlayBlock(_ block: ((UIImageView, Data, [AnyHashable: Any]?) -> Void)?) -> ZLPhotoConfiguration {
        gifPlayBlock = block
        return self
    }
    
    @discardableResult
    func pauseGIFBlock(_ block: ((UIImageView) -> Void)?) -> ZLPhotoConfiguration {
        pauseGIFBlock = block
        return self
    }
    
    @discardableResult
    func resumeGIFBlock(_ block: ((UIImageView) -> Void)?) -> ZLPhotoConfiguration {
        resumeGIFBlock = block
        return self
    }
    
    @discardableResult
    func noAuthorityCallback(_ callback: ((ZLNoAuthorityType) -> Void)?) -> ZLPhotoConfiguration {
        noAuthorityCallback = callback
        return self
    }
    
    @discardableResult
    func operateBeforeDoneAction(_ block: ((UIViewController, @escaping () -> Void) -> Void)?) -> ZLPhotoConfiguration {
        operateBeforeDoneAction = block
        return self
    }
}
