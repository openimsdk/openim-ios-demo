
import Foundation
import Photos
import UIKit
import ProgressHUD
import ZLPhotoBrowser
import MobileCoreServices
import KTVHTTPCache

open class PhotoHelper {
    public var didPhotoSelected: ((_ images: [UIImage], _ assets: [PHAsset]) -> Void)?
    
    public var didPhotoSelectedCancel: (() -> Void)?
    
    public var didCameraFinished: ((UIImage?, URL?) -> Void)?
    
    public init() {
        resetConfigToSendMedia()
    }
    
    func resetConfigToSendMedia() {
        let editConfig = ZLPhotoConfiguration.default().editImageConfiguration
        editConfig.tools([.draw, .clip, .textSticker, .mosaic])
        ZLPhotoConfiguration.default().editImageConfiguration(editConfig)
            .canSelectAsset { _ in true }
            .noAuthorityCallback { (authType: ZLNoAuthorityType) in
                switch authType {
                case .library:
                    debugPrint("No library authority")
                case .camera:
                    debugPrint("No camera authority")
                case .microphone:
                    debugPrint("No microphone authority")
                }
            }
    }
    
    public func setConfigToPickAvatar() {
        let editConfig = ZLPhotoConfiguration.default().editImageConfiguration
        editConfig.tools([.draw, .clip, .textSticker, .mosaic])
            .clipRatios([ZLImageClipRatio.wh1x1])
        ZLPhotoConfiguration.default().maxSelectCount(1)
            .editAfterSelectThumbnailImage(true)
            .allowMixSelect(false)
            .allowSelectGif(false)
            .allowSelectVideo(false)
            .allowSelectLivePhoto(false)
            .allowSelectOriginal(false)
            .editImageConfiguration(editConfig)
            .showClipDirectlyIfOnlyHasClipTool(true)
            .canSelectAsset { _ in true }
            .saveNewImageAfterEdit(false)
            .noAuthorityCallback { (authType: ZLNoAuthorityType) in
                switch authType {
                case .library:
                    debugPrint("No library authority")
                case .camera:
                    debugPrint("No camera authority")
                case .microphone:
                    debugPrint("No microphone authority")
                }
            }
    }
    
    public func setConfigToPickBackground() {
        ZLPhotoConfiguration.default().maxSelectCount(1)
            .editAfterSelectThumbnailImage(true)
            .allowMixSelect(false)
            .allowSelectGif(false)
            .allowSelectVideo(false)
            .allowSelectImage(true)
            .allowSelectLivePhoto(false)
            .allowSelectOriginal(false)
            .allowEditImage(false)
            .allowEditVideo(false)
            .canSelectAsset { _ in true }
            .saveNewImageAfterEdit(false)
            .noAuthorityCallback { (authType: ZLNoAuthorityType) in
                switch authType {
                case .library:
                    debugPrint("No library authority")
                case .camera:
                    debugPrint("No camera authority")
                case .microphone:
                    debugPrint("No microphone authority")
                }
            }
    }
    
    public func setConfigToPickImageForChat(canSelectAsset: ((PHAsset) -> Bool)? = nil) {
        let config = ZLPhotoConfiguration.default()
        config.allowSelectImage = true
        config.allowSelectVideo = true
        config.allowSelectGif = true
        config.allowSelectLivePhoto = false
        config.allowSelectOriginal = false
        config.cropVideoAfterSelectThumbnail = true
        config.allowEditVideo = false
        config.allowEditImage = false
        config.allowMixSelect = true
        config.maxSelectCount = 9
        config.maxEditVideoTime = 60
        config.canSelectAsset = canSelectAsset
        
        let cameraConfig = ZLCameraConfiguration()
        cameraConfig.videoExportType = .mp4
        config.cameraConfiguration = cameraConfig
    }
    
    public func setConfigToMultipleSelected(forVideo: Bool = false, maxSelectCount: Int = 9) {
        
        let config = ZLPhotoConfiguration.default()
        config.allowSelectImage = !forVideo
        config.allowSelectVideo = forVideo
        config.allowSelectGif = false
        config.allowSelectLivePhoto = false
        config.allowSelectOriginal = false
        config.cropVideoAfterSelectThumbnail = true
        config.allowEditVideo = true
        config.allowMixSelect = false
        config.maxSelectCount = maxSelectCount
        config.maxEditVideoTime = 15
        
        
        let cameraConfig = ZLCameraConfiguration()
        cameraConfig.sessionPreset = .vga640x480
        config.cameraConfiguration = cameraConfig
    }
    
    public func setConfigToPickImageForScanQrcode() {
        let config = ZLPhotoConfiguration.default()
        config.allowSelectImage = true
        config.allowSelectVideo = false
        config.allowSelectGif = false
        config.allowSelectLivePhoto = false
        config.allowSelectOriginal = false
        config.cropVideoAfterSelectThumbnail = false
        config.allowEditVideo = false
        config.allowEditImage = false
        config.allowMixSelect = false
        config.maxSelectCount = 1
        config.allowTakePhotoInLibrary = false
    }
    
    public func setConfigToPickImageForAddFaceEmoji() {
        let config = ZLPhotoConfiguration.default()
        config.allowSelectImage = true
        config.allowSelectVideo = false
        config.allowSelectGif = true
        config.allowSelectLivePhoto = false
        config.allowSelectOriginal = false
        config.cropVideoAfterSelectThumbnail = false
        config.allowEditVideo = false
        config.allowEditImage = false
        config.allowMixSelect = true
        config.maxSelectCount = 9
        config.allowTakePhotoInLibrary = false
    }
    
    func presentPhotoLibraryOnlyEdit(byController: UIViewController) {
        let sheet = ZLPhotoPreviewSheet(selectedAssets: nil)
        sheet.selectImageBlock = { [weak self] models, result in
            let images = models.map { $0.image }
            let assets = models.map { $0.asset }
            
            self?.didPhotoSelected?(images, assets)
        }
        sheet.cancelBlock = didPhotoSelectedCancel
        sheet.showPhotoLibrary(sender: byController)
    }
    
    public func presentPhotoLibrary(byController: UIViewController) {
        let sheet = ZLPhotoPreviewSheet(selectedAssets: nil)
        sheet.selectImageBlock = { [weak self] models, result in
            let images = models.map { $0.image }
            let assets = models.map { $0.asset }
            
            self?.didPhotoSelected?(images, assets)
        }
        sheet.cancelBlock = didPhotoSelectedCancel
        sheet.showPhotoLibrary(sender: byController)
    }
    
    public func presentCamera(byController: UIViewController) {
        let camera = ZLCustomCamera()
        camera.takeDoneBlock = didCameraFinished
        camera.modalPresentationStyle = .overCurrentContext
        byController.showDetailViewController(camera, sender: nil)
    }
    
    public static func getVideoAt(url: URL, handler: @escaping (_ main: FileHelper.FileWriteResult, _ thumb: FileHelper.FileWriteResult, _ duration: Int) -> Void) {
        let asset = AVURLAsset(url: url)
        let assetGen = AVAssetImageGenerator(asset: asset)
        assetGen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: .zero, preferredTimescale: 600)
        var actualTime: CMTime = .zero
        DispatchQueue.global().async {
            do {
                let cgImage = try assetGen.copyCGImage(at: time, actualTime: &actualTime)
                let thumbnail = UIImage(cgImage: cgImage)
                let result = FileHelper.shared.saveImage(image: thumbnail)
                let p = FileHelper.shared.saveVideo(from: url.path)
                handler(p, result, Int(asset.duration.seconds))
            } catch {
#if DEBUG
                print("获取视频帧错误:", error)
#endif
            }
        }
    }
    
    public static func getFirstRate(fromVideo: URL, completionHandler: @escaping (_ path: String, _ duration: Int) -> Void) {
        
        let asset = AVURLAsset(url: fromVideo)
        let assetGen = AVAssetImageGenerator(asset: asset)
        assetGen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: .zero, preferredTimescale: 600)
        var actualTime: CMTime = .zero
        DispatchQueue.global().async {
            do {
                let cgImage = try assetGen.copyCGImage(at: time, actualTime: &actualTime)
                let thumbnail = UIImage(cgImage: cgImage)
                let result = FileHelper.shared.saveImage(image: thumbnail)
                let thumbnailPath = result.fullPath
                completionHandler(thumbnailPath, Int(asset.duration.seconds))
            } catch {
#if DEBUG
                print("获取视频帧错误:", error)
#endif
                completionHandler("", 0)
            }
        }
    }
    
    public func showSelectMetaSheet(byController: UIViewController) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photoAction = UIAlertAction(title: "相册", style: .default, handler: { [weak self] (alert) -> Void in
            guard let sself = self else {
                return
            }
            sself.presentPhotoLibrary(byController: byController)
        })
        
        let cameraAction = UIAlertAction(title: "拍摄", style: .default, handler: { [weak self] (alert) -> Void in
            guard let sself = self else {
                return
            }
            sself.presentCamera(byController: byController)
        })
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil )
        
        alertController.addAction(photoAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)
        byController.present(alertController, animated: true, completion: nil)
    }
    
    public static func compressVideoToMp4(asset: PHAsset, thumbnail: UIImage?, handler: @escaping (_ main: FileHelper.FileWriteResult, _ thumb: FileHelper.FileWriteResult, _ duration: Int) -> Void) {
        let fileHelper = FileHelper.shared
        let thumbnail = fileHelper.saveImage(image: thumbnail!)
        
        ZLVideoManager.exportVideo(for: asset, exportType: .mp4, presetName: AVAssetExportPreset960x540) { (url: URL?, _: Error?) in
            guard let url = url else { return }
            let p = fileHelper.saveVideo(from: url.path)
            handler(p, thumbnail, Int(asset.duration))
        }
    }
    
    public static func saveImage(image: UIImage) -> String {
        let result = FileHelper.shared.saveImage(image: image)
        
        return result.fullPath
    }
    
    public func saveImageToAlbum(image: UIImage, showToast: Bool = true) {
        if showToast {
            DispatchQueue.main.async {
                ProgressHUD.animate(interaction: false)
            }
        }
        PHPhotoLibrary.shared().performChanges({
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
            }
        }) { (success, error) in
            if success {
                print("图片保存成功！")
                if showToast {
                    DispatchQueue.main.async {
                        ProgressHUD.success("图片保存成功".innerLocalized())
                    }
                }
            } else {
                if let error {
                    print("保存图片时出错：\(error.localizedDescription)")
                } else {
                    print("未知错误发生")
                }
            }
        }
    }
    
    public func saveVideoToAlbum(path: String, showToast: Bool = true, removeOrigin: Bool = true, fileSize: Int = 0) {
        guard let url = URL(string: path) else { return }
        
        if url.isFileURL {
            if showToast {
                DispatchQueue.main.async {
                    ProgressHUD.animate()
                }
            }
            save(fileURL: url)
        } else {
            if let fileURL = KTVHTTPCache.cacheCompleteFileURL(with: url) {
                save(fileURL: fileURL)
                
                return
            }
            
            if showToast {
                DispatchQueue.main.async {
                    ProgressHUD.progress(0)
                }
            }
            downloadVideo(from: url, fileSize: fileSize) { progress in
                ProgressHUD.progress(progress)
            } onCompletion: { fileURL in
                save(fileURL: fileURL)
            }
        }
        
        func save(fileURL: URL) {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }) { (success, error) in
                if success {
                    if showToast {
                        DispatchQueue.main.async {
                            ProgressHUD.success("saveSuccessfully".innerLocalized())
                        }
                    }
                    if removeOrigin {
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                } else {
                    if let error {
                        let tips = "\("saveFailed".innerLocalized()): \(error.localizedDescription)"
                        print(tips)
                        if showToast {
                            DispatchQueue.main.async {
                                ProgressHUD.error(tips)
                            }
                        }
                    } else {
                        print("未知错误发生")
                    }
                }
            }
        }
        
        func downloadVideo(from url: URL,
                           fileSize: Int = 0,
                           onProgress: @escaping ((Double) -> Void),
                           onCompletion: @escaping (_ fileURL: URL) -> Void) {
            Task.detached {
                do {
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let destinationPath = documentsDirectory.appendingPathComponent("downloadedVideo.mp4")
                    
                    let downloader = MultiThreadDownloader(url: url, fileSize: fileSize)
                    let path = try await downloader.start()
                    
                    onCompletion(path)
                    iLogger.print("download complete: \(path)")
                } catch (let e) {
                    iLogger.print("download video throw an error: \(e)", functionName: "\(#function)")
                }
            }
        }
    }
    
    public class func isGIF(asset: PHAsset, completion: @escaping (Data?, Bool) -> Void) {
        let imageManager = PHImageManager.default()
        
        imageManager.requestImageData(for: asset, options: nil) { (data, uti, _, _) in
            guard let imageData = data,
                  let imageUTI = uti,
                  UTTypeConformsTo(imageUTI as CFString, kUTTypeGIF) else {
                completion(data, false)
                return
            }
            
            let isGIF = imageData.starts(with: [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) ||  // "GIF89a"
            imageData.starts(with: [0x47, 0x49, 0x46, 0x38, 0x37, 0x61])     // "GIF87a"
            
            completion(imageData, isGIF)
        }
    }
    
    public struct MediaTuple {
        let thumbnail: UIImage
        let asset: PHAsset
        public init(thumbnail: UIImage, asset: PHAsset) {
            self.thumbnail = thumbnail
            self.asset = asset
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}
