

























import UIKit


@objcMembers
public class ZLPhotoUIConfiguration: NSObject {
    @objc public enum CancelButtonStyle: Int {
        case text
        case image
    }
    
    private static var single = ZLPhotoUIConfiguration()
    
    public class func `default`() -> ZLPhotoUIConfiguration {
        return ZLPhotoUIConfiguration.single
    }
    
    public class func resetConfiguration() {
        ZLPhotoUIConfiguration.single = ZLPhotoUIConfiguration()
    }


    public var sortAscending = true
    
    public var style: ZLPhotoBrowserStyle = .embedAlbumList
    
    public var statusBarStyle: UIStatusBarStyle = .lightContent

    public var navCancelButtonStyle: ZLPhotoUIConfiguration.CancelButtonStyle = .image

    public var showStatusBarInPreviewInterface = false

    public var hudStyle: ZLProgressHUD.Style = .dark

    public var adjustSliderType: ZLAdjustSliderType = .vertical
    
    public var cellCornerRadio: CGFloat = 0

    public var customAlertClass: ZLCustomAlertProtocol.Type?
    
    private var pri_columnCount = 4








    public var columnCount: Int {
        get {
            pri_columnCount
        }
        set {
            pri_columnCount = min(6, max(newValue, 2))
        }
    }


    public var columnCountBlock: ((_ collectionViewWidth: CGFloat) -> Int)?

    public var minimumInteritemSpacing: CGFloat = 2

    public var minimumLineSpacing: CGFloat = 2

    public var animateSelectBtnWhenSelectInThumbVC = false

    public var animateSelectBtnWhenSelectInPreviewVC = true

    public var selectBtnAnimationDuration: CFTimeInterval = 0.5

    public var showIndexOnSelectBtn = false

    public var showScrollToBottomBtn = false

    public var showCaptureImageOnTakePhotoBtn = false

    public var showSelectedMask = true

    public var showSelectedBorder = false

    public var showInvalidMask = true

    public var showSelectedPhotoPreview = true

    public var showAddPhotoButton = true


    public var showEnterSettingTips = true

    public var timeout: TimeInterval = 20


    public var navViewBlurEffectOfAlbumList: UIBlurEffect? = UIBlurEffect(style: .dark)

    public var navViewBlurEffectOfPreview: UIBlurEffect? = UIBlurEffect(style: .dark)

    public var bottomViewBlurEffectOfAlbumList: UIBlurEffect? = UIBlurEffect(style: .dark)

    public var bottomViewBlurEffectOfPreview: UIBlurEffect? = UIBlurEffect(style: .dark)




    public var customImageNames: [String] = [] {
        didSet {
            ZLCustomImageDeploy.imageNames = customImageNames
        }
    }



    public var customImageForKey: [String: UIImage?] = [:] {
        didSet {
            customImageForKey.forEach { ZLCustomImageDeploy.imageForKey[$0.key] = $0.value }
        }
    }



    public var customImageForKey_objc: [String: UIImage] = [:] {
        didSet {
            ZLCustomImageDeploy.imageForKey = customImageForKey_objc
        }
    }


    public var languageType: ZLLanguageType = .system {
        didSet {
            ZLCustomLanguageDeploy.language = languageType
            Bundle.resetLanguage()
        }
    }





    public var customLanguageKeyValue: [ZLLocalLanguageKey: String] = [:] {
        didSet {
            ZLCustomLanguageDeploy.deploy = customLanguageKeyValue
        }
    }





    public var customLanguageKeyValue_objc: [String: String] = [:] {
        didSet {
            var swiftParams: [ZLLocalLanguageKey: String] = [:]
            customLanguageKeyValue_objc.forEach { key, value in
                swiftParams[ZLLocalLanguageKey(rawValue: key)] = value
            }
            customLanguageKeyValue = swiftParams
        }
    }


    public var themeFontName: String? {
        didSet {
            ZLCustomFontDeploy.fontName = themeFontName
        }
    }



    public var themeColor: UIColor = .zl.rgba(0, 193, 94)


    public var sheetTranslucentColor: UIColor = .black.withAlphaComponent(0.1)


    public var sheetBtnBgColor: UIColor = .white


    public var sheetBtnTitleColor: UIColor = .black
    
    private var pri_sheetBtnTitleTintColor: UIColor?


    public var sheetBtnTitleTintColor: UIColor {
        get {
            pri_sheetBtnTitleTintColor ?? themeColor
        }
        set {
            pri_sheetBtnTitleTintColor = newValue
        }
    }


    public var navBarColor: UIColor = .zl.rgba(140, 140, 140, 0.75)


    public var navBarColorOfPreviewVC: UIColor = .zl.rgba(50, 50, 50)


    public var navTitleColor: UIColor = .white


    public var navTitleColorOfPreviewVC: UIColor = .white


    public var navEmbedTitleViewBgColor: UIColor = .zl.rgba(80, 80, 80)


    public var albumListBgColor: UIColor = .zl.rgba(45, 45, 45)


    public var embedAlbumListTranslucentColor: UIColor = .black.withAlphaComponent(0.8)


    public var albumListTitleColor: UIColor = .white


    public var albumListCountColor: UIColor = .zl.rgba(180, 180, 180)


    public var separatorColor: UIColor = .zl.rgba(60, 60, 60)


    public var thumbnailBgColor: UIColor = .zl.rgba(25, 25, 25)


    public var previewVCBgColor: UIColor = .black


    public var bottomToolViewBgColor: UIColor = .zl.rgba(35, 35, 35, 0.3)


    public var bottomToolViewBgColorOfPreviewVC: UIColor = .zl.rgba(35, 35, 35, 0.3)


    public var originalSizeLabelTextColor: UIColor = .zl.rgba(130, 130, 130)


    public var originalSizeLabelTextColorOfPreviewVC: UIColor = .zl.rgba(130, 130, 130)


    public var bottomToolViewBtnNormalTitleColor: UIColor = .white


    public var bottomToolViewDoneBtnNormalTitleColor: UIColor = .white


    public var bottomToolViewBtnNormalTitleColorOfPreviewVC: UIColor = .white


    public var bottomToolViewDoneBtnNormalTitleColorOfPreviewVC: UIColor = .white


    public var bottomToolViewBtnDisableTitleColor: UIColor = .zl.rgba(168, 168, 168)


    public var bottomToolViewDoneBtnDisableTitleColor: UIColor = .zl.rgba(168, 168, 168)


    public var bottomToolViewBtnDisableTitleColorOfPreviewVC: UIColor = .zl.rgba(168, 168, 168)


    public var bottomToolViewDoneBtnDisableTitleColorOfPreviewVC: UIColor = .zl.rgba(168, 168, 168)
    
    private var pri_bottomToolViewBtnNormalBgColor: UIColor?


    public var bottomToolViewBtnNormalBgColor: UIColor {
        get {
            pri_bottomToolViewBtnNormalBgColor ?? themeColor
        }
        set {
            pri_bottomToolViewBtnNormalBgColor = newValue
        }
    }
    
    private var pri_bottomToolViewBtnNormalBgColorOfPreviewVC: UIColor?


    public var bottomToolViewBtnNormalBgColorOfPreviewVC: UIColor {
        get {
            pri_bottomToolViewBtnNormalBgColorOfPreviewVC ?? themeColor
        }
        set {
            pri_bottomToolViewBtnNormalBgColorOfPreviewVC = newValue
        }
    }


    public var bottomToolViewBtnDisableBgColor: UIColor = .zl.rgba(50, 50, 50)


    public var bottomToolViewBtnDisableBgColorOfPreviewVC: UIColor = .zl.rgba(50, 50, 50)


    public var limitedAuthorityTipsColor: UIColor = .white
    
    private var pri_cameraRecodeProgressColor: UIColor?


    public var cameraRecodeProgressColor: UIColor {
        get {
            pri_cameraRecodeProgressColor ?? themeColor
        }
        set {
            pri_cameraRecodeProgressColor = newValue
        }
    }


    public var selectedMaskColor: UIColor = .black.withAlphaComponent(0.45)
    
    private var pri_selectedBorderColor: UIColor?


    public var selectedBorderColor: UIColor {
        get {
            pri_selectedBorderColor ?? themeColor
        }
        set {
            pri_selectedBorderColor = newValue
        }
    }


    public var invalidMaskColor: UIColor = .zl.rgba(32, 32, 32, 0.85)


    public var indexLabelTextColor: UIColor = .zl.rgba(220, 220, 220)
    
    private var pri_indexLabelBgColor: UIColor?


    public var indexLabelBgColor: UIColor {
        get {
            pri_indexLabelBgColor ?? (showIndexOnSelectBtn ? themeColor : .clear)
        }
        set {
            pri_indexLabelBgColor = newValue
        }
    }


    public var cameraCellBgColor: UIColor = .zl.rgba(76, 76, 76)


    public var adjustSliderNormalColor: UIColor = .white
    
    private var pri_adjustSliderTintColor: UIColor?


    public var adjustSliderTintColor: UIColor {
        get {
            pri_adjustSliderTintColor ?? themeColor
        }
        set {
            pri_adjustSliderTintColor = newValue
        }
    }


    public var imageEditorToolTitleNormalColor: UIColor = .zl.rgba(160, 160, 160)


    public var imageEditorToolTitleTintColor: UIColor = .white


    public var imageEditorToolIconTintColor: UIColor?


    public var trashCanBackgroundNormalColor: UIColor = .zl.rgba(40, 40, 40, 0.8)


    public var trashCanBackgroundTintColor: UIColor = .zl.rgba(241, 79, 79, 0.98)
}

enum ZLCustomFontDeploy {
    static var fontName: String?
}

enum ZLCustomImageDeploy {
    static var imageNames: [String] = []
    
    static var imageForKey: [String: UIImage] = [:]
}

@objc public enum ZLPhotoBrowserStyle: Int {

    case embedAlbumList

    case externalAlbumList
}

enum ZLCustomLanguageDeploy {
    static var language: ZLLanguageType = .system
    
    static var deploy: [ZLLocalLanguageKey: String] = [:]
}

@objc public enum ZLAdjustSliderType: Int {
    case vertical
    case horizontal
}
