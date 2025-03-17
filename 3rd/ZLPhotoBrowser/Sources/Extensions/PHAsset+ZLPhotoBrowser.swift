

























import Photos
import MobileCoreServices

public extension ZLPhotoBrowserWrapper where Base: PHAsset {
    var isInCloud: Bool {
        guard let resource = resource else {
            return false
        }
        return !(resource.value(forKey: "locallyAvailable") as? Bool ?? true)
    }

    var isGif: Bool {
        guard let filename = filename else {
            return false
        }
        
        return filename.hasSuffix("GIF")
    }
    
    var filename: String? {
        base.value(forKey: "filename") as? String
    }
    
    var resource: PHAssetResource? {
        PHAssetResource.assetResources(for: base).first
    }
}
