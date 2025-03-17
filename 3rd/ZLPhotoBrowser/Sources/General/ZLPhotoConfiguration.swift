

























import UIKit
import Photos

@objcMembers
public class ZLPhotoConfiguration: NSObject {
    public typealias Second = Int
    
    public typealias KBUnit = CGFloat
    
    private static var single = ZLPhotoConfiguration()
    
    public class func `default`() -> ZLPhotoConfiguration {
        ZLPhotoConfiguration.single
    }
    
    public class func resetConfiguration() {
        ZLPhotoConfiguration.single = ZLPhotoConfiguration()
    }
    
    private var pri_maxSelectCount = 9

    public var maxSelectCount: Int {
        get {
            pri_maxSelectCount
        }
        set {
            pri_maxSelectCount = max(1, newValue)
        }
    }
    
    private var pri_maxVideoSelectCount = 0


    public var maxVideoSelectCount: Int {
        get {
            if pri_maxVideoSelectCount <= 0 {
                return maxSelectCount
            } else {
                return max(minVideoSelectCount, min(pri_maxVideoSelectCount, maxSelectCount))
            }
        }
        set {
            pri_maxVideoSelectCount = newValue
        }
    }
    
    private var pri_minVideoSelectCount = 0


    public var minVideoSelectCount: Int {
        get {
            min(maxSelectCount, max(pri_minVideoSelectCount, 0))
        }
        set {
            pri_minVideoSelectCount = newValue
        }
    }


    public var allowMixSelect = true

    public var maxPreviewCount = 20
    
    private var pri_initialIndex = 1

    public var initialIndex: Int {
        get {
            max(pri_initialIndex, 1)
        }
        set {
            pri_initialIndex = newValue
        }
    }

    public var allowSelectImage = true
    
    public var allowSelectVideo = true


    public var downloadVideoBeforeSelecting = false


    public var allowSelectGif = true


    public var allowSelectLivePhoto = false
    
    private var pri_allowTakePhotoInLibrary = true


    public var allowTakePhotoInLibrary: Bool {
        get {
            pri_allowTakePhotoInLibrary && (cameraConfiguration.allowTakePhoto || cameraConfiguration.allowRecordVideo)
        }
        set {
            pri_allowTakePhotoInLibrary = newValue
        }
    }

    public var callbackDirectlyAfterTakingPhoto = false
    
    private var pri_allowEditImage = true
    public var allowEditImage: Bool {
        get {
            pri_allowEditImage
        }
        set {
            pri_allowEditImage = newValue
        }
    }

    private var pri_allowEditVideo = false
    public var allowEditVideo: Bool {
        get {
            pri_allowEditVideo
        }
        set {
            pri_allowEditVideo = newValue
        }
    }



    public var editAfterSelectThumbnailImage = false


    public var cropVideoAfterSelectThumbnail = true

    public var showClipDirectlyIfOnlyHasClipTool = false

    public var saveNewImageAfterEdit = true

    public var allowSlideSelect = true

    public var autoScrollWhenSlideSelectIsActive = true

    public var autoScrollMaxSpeed: CGFloat = 600

    public var allowDragSelect = false

    public var allowSelectOriginal = true


    public var alwaysRequestOriginal = false


    public var showOriginalSizeWhenSelectOriginal = true

    public var allowPreviewPhotos = true

    public var showPreviewButtonInAlbum = true

    public var showSelectCountOnDoneBtn = true

    public var showSelectBtnWhenSingleSelect = false

    public var showSelectedIndex = true

    public var maxEditVideoTime: ZLPhotoConfiguration.Second = 10

    public var maxSelectVideoDuration: ZLPhotoConfiguration.Second = 120

    public var minSelectVideoDuration: ZLPhotoConfiguration.Second = 0

    public var maxSelectVideoDataSize: ZLPhotoConfiguration.KBUnit = .greatestFiniteMagnitude

    public var minSelectVideoDataSize: ZLPhotoConfiguration.KBUnit = 0

    public var editImageConfiguration = ZLEditImageConfiguration()

    public var useCustomCamera = true

    public var cameraConfiguration = ZLCameraConfiguration()



    public var canSelectAsset: ((PHAsset) -> Bool)?

    public var didSelectAsset: ((PHAsset) -> Void)?

    public var didDeselectAsset: ((PHAsset) -> Void)?

    public var maxFrameCountForGIF = 50

    public var gifPlayBlock: ((UIImageView, Data, [AnyHashable: Any]?) -> Void)?

    public var pauseGIFBlock: ((UIImageView) -> Void)?

    public var resumeGIFBlock: ((UIImageView) -> Void)?

    public var noAuthorityCallback: ((ZLNoAuthorityType) -> Void)?




    public var operateBeforeDoneAction: ((UIViewController, @escaping () -> Void) -> Void)?
}

@objc public enum ZLNoAuthorityType: Int {
    case library
    case camera
    case microphone
}
