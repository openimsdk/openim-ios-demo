

























import Foundation

@objc public enum ZLLanguageType: Int, CaseIterable {
    case system
    case chineseSimplified
    case chineseTraditional
    case english
    case japanese
    case french
    case german
    case russian
    case vietnamese
    case korean
    case malay
    case italian
    case indonesian
    case portuguese
    case spanish
    case turkish
    case arabic
    case dutch
    
    var key: String {
        var key = "en"
        
        switch self {
        case .system:
            key = Locale.preferredLanguages.first ?? "en"
            
            if key.hasPrefix("zh") {
                if key.range(of: "Hans") != nil {
                    key = "zh-Hans"
                } else {
                    key = "zh-Hant"
                }
            } else if key.hasPrefix("ja") {
                key = "ja-US"
            } else if key.hasPrefix("fr") {
                key = "fr"
            } else if key.hasPrefix("de") {
                key = "de"
            } else if key.hasPrefix("ru") {
                key = "ru"
            } else if key.hasPrefix("vi") {
                key = "vi"
            } else if key.hasPrefix("ko") {
                key = "ko"
            } else if key.hasPrefix("ms") {
                key = "ms"
            } else if key.hasPrefix("it") {
                key = "it"
            } else if key.hasPrefix("id") {
                key = "id"
            } else if key.hasPrefix("pt") {
                key = "pt-BR"
            } else if key.hasPrefix("es") {
                key = "es-419"
            } else if key.hasPrefix("tr") {
                key = "tr"
            } else if key.hasPrefix("ar") {
                key = "ar"
            } else if key.hasPrefix("nl") {
                key = "nl"
            } else {
                key = "en"
            }
        case .chineseSimplified:
            key = "zh-Hans"
        case .chineseTraditional:
            key = "zh-Hant"
        case .english:
            key = "en"
        case .japanese:
            key = "ja-US"
        case .french:
            key = "fr"
        case .german:
            key = "de"
        case .russian:
            key = "ru"
        case .vietnamese:
            key = "vi"
        case .korean:
            key = "ko"
        case .malay:
            key = "ms"
        case .italian:
            key = "it"
        case .indonesian:
            key = "id"
        case .portuguese:
            key = "pt-BR"
        case .spanish:
            key = "es-419"
        case .turkish:
            key = "tr"
        case .arabic:
            key = "ar"
        case .dutch:
            key = "nl"
        }
        
        return key
    }
}

public struct ZLLocalLanguageKey: Hashable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let previewCamera = ZLLocalLanguageKey(rawValue: "previewCamera")

    public static let previewCameraRecord = ZLLocalLanguageKey(rawValue: "previewCameraRecord")

    public static let previewAlbum = ZLLocalLanguageKey(rawValue: "previewAlbum")

    public static let cancel = ZLLocalLanguageKey(rawValue: "cancel")

    public static let noPhotoTips = ZLLocalLanguageKey(rawValue: "noPhotoTips")

    public static let hudLoading = ZLLocalLanguageKey(rawValue: "hudLoading")

    public static let hudProcessing = ZLLocalLanguageKey(rawValue: "hudProcessing")

    public static let done = ZLLocalLanguageKey(rawValue: "done")

    public static let cameraDone = ZLLocalLanguageKey(rawValue: "cameraDone")

    public static let inputDone = ZLLocalLanguageKey(rawValue: "inputDone")

    public static let ok = ZLLocalLanguageKey(rawValue: "ok")

    public static let timeout = ZLLocalLanguageKey(rawValue: "timeout")


    public static let noPhotoLibratyAuthority = ZLLocalLanguageKey(rawValue: "noPhotoLibratyAuthority")


    public static let noCameraAuthority = ZLLocalLanguageKey(rawValue: "noCameraAuthority")


    public static let noMicrophoneAuthority = ZLLocalLanguageKey(rawValue: "noMicrophoneAuthority")

    public static let cameraUnavailable = ZLLocalLanguageKey(rawValue: "cameraUnavailable")

    public static let keepRecording = ZLLocalLanguageKey(rawValue: "keepRecording")

    public static let gotoSettings = ZLLocalLanguageKey(rawValue: "gotoSettings")

    public static let photo = ZLLocalLanguageKey(rawValue: "photo")

    public static let originalPhoto = ZLLocalLanguageKey(rawValue: "originalPhoto")

    public static let originalTotalSize = ZLLocalLanguageKey(rawValue: "originalTotalSize")

    public static let back = ZLLocalLanguageKey(rawValue: "back")

    public static let edit = ZLLocalLanguageKey(rawValue: "edit")

    public static let editFinish = ZLLocalLanguageKey(rawValue: "editFinish")

    public static let revert = ZLLocalLanguageKey(rawValue: "revert")

    public static let brightness = ZLLocalLanguageKey(rawValue: "brightness")

    public static let contrast = ZLLocalLanguageKey(rawValue: "contrast")

    public static let saturation = ZLLocalLanguageKey(rawValue: "saturation")

    public static let preview = ZLLocalLanguageKey(rawValue: "preview")

    public static let save = ZLLocalLanguageKey(rawValue: "save")

    public static let saveImageError = ZLLocalLanguageKey(rawValue: "saveImageError")

    public static let saveVideoError = ZLLocalLanguageKey(rawValue: "saveVideoError")

    public static let exceededMaxSelectCount = ZLLocalLanguageKey(rawValue: "exceededMaxSelectCount")

    public static let exceededMaxVideoSelectCount = ZLLocalLanguageKey(rawValue: "exceededMaxVideoSelectCount")

    public static let lessThanMinVideoSelectCount = ZLLocalLanguageKey(rawValue: "lessThanMinVideoSelectCount")


    public static let longerThanMaxVideoDuration = ZLLocalLanguageKey(rawValue: "longerThanMaxVideoDuration")


    public static let shorterThanMinVideoDuration = ZLLocalLanguageKey(rawValue: "shorterThanMinVideoDuration")


    public static let largerThanMaxVideoDataSize = ZLLocalLanguageKey(rawValue: "largerThanMaxVideoDataSize")


    public static let smallerThanMinVideoDataSize = ZLLocalLanguageKey(rawValue: "smallerThanMinVideoDataSize")

    public static let iCloudVideoLoadFaild = ZLLocalLanguageKey(rawValue: "iCloudVideoLoadFaild")

    public static let imageLoadFailed = ZLLocalLanguageKey(rawValue: "imageLoadFailed")

    public static let customCameraTips = ZLLocalLanguageKey(rawValue: "customCameraTips")

    public static let customCameraTakePhotoTips = ZLLocalLanguageKey(rawValue: "customCameraTakePhotoTips")

    public static let customCameraRecordVideoTips = ZLLocalLanguageKey(rawValue: "customCameraRecordVideoTips")

    public static let minRecordTimeTips = ZLLocalLanguageKey(rawValue: "minRecordTimeTips")

    public static let cameraRoll = ZLLocalLanguageKey(rawValue: "cameraRoll")

    public static let panoramas = ZLLocalLanguageKey(rawValue: "panoramas")

    public static let videos = ZLLocalLanguageKey(rawValue: "videos")

    public static let favorites = ZLLocalLanguageKey(rawValue: "favorites")

    public static let timelapses = ZLLocalLanguageKey(rawValue: "timelapses")

    public static let recentlyAdded = ZLLocalLanguageKey(rawValue: "recentlyAdded")

    public static let bursts = ZLLocalLanguageKey(rawValue: "bursts")

    public static let slomoVideos = ZLLocalLanguageKey(rawValue: "slomoVideos")

    public static let selfPortraits = ZLLocalLanguageKey(rawValue: "selfPortraits")

    public static let screenshots = ZLLocalLanguageKey(rawValue: "screenshots")

    public static let depthEffect = ZLLocalLanguageKey(rawValue: "depthEffect")

    public static let livePhotos = ZLLocalLanguageKey(rawValue: "livePhotos")

    public static let animated = ZLLocalLanguageKey(rawValue: "animated")

    public static let myPhotoStream = ZLLocalLanguageKey(rawValue: "myPhotoStream")

    public static let noTitleAlbumListPlaceholder = ZLLocalLanguageKey(rawValue: "noTitleAlbumListPlaceholder")

    public static let unableToAccessAllPhotos = ZLLocalLanguageKey(rawValue: "unableToAccessAllPhotos")

    public static let textStickerRemoveTips = ZLLocalLanguageKey(rawValue: "textStickerRemoveTips")
}

func localLanguageTextValue(_ key: ZLLocalLanguageKey) -> String {
    if let value = ZLCustomLanguageDeploy.deploy[key] {
        return value
    }
    return Bundle.zlLocalizedString(key.rawValue)
}
