
import Foundation

extension Data {
    public enum ImageFormat {
        case unkonwn
        case jpeg
        case png
        case gif
        case tiff
        case webp
        case heic
        case heif
        
        public var type: String {
            switch self {
            case .unkonwn:
                return "unkonwn"
            case .jpeg:
                return "jpeg"
            case .png:
                return "png"
            case .gif:
                return "gif"
            case .tiff:
                return "tiff"
            case .webp:
                return "webp"
            case .heic:
                return "heic"
            case .heif:
                return "heif"
            }
        }
    }

    public var imageFormat: ImageFormat  {
        var buffer = [UInt8](repeating: 0, count: 1)
        self.copyBytes(to: &buffer, count: 1)
        
        switch buffer {
        case [0xFF]: return .jpeg
        case [0x89]: return .png
        case [0x47]: return .gif
        case [0x49],[0x4D]: return .tiff
        case [0x52] where self.count >= 12:
            if let str = String(data: self[0...11], encoding: .ascii), str.hasPrefix("RIFF"), str.hasSuffix("WEBP") {
                return .webp
            }
        case [0x00] where self.count >= 12:
            if let str = String(data: self[8...11], encoding: .ascii) {
                let HEICBitMaps = Set(["heic", "heis", "heix", "hevc", "hevx"])
                if HEICBitMaps.contains(str) {
                    return .heic
                }
                let HEIFBitMaps = Set(["mif1", "msf1"])
                if HEIFBitMaps.contains(str) {
                    return .heif
                }
            }
        default: break;
        }
        return .unkonwn
    }
    
    var fitSampleCount:Int{
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return 1
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        var sampleCount = 1
        switch frameCount {
        case 2..<8:
            sampleCount = 2
        case 8..<20:
            sampleCount = 3
        case 20..<30:
            sampleCount = 4
        case 30..<40:
            sampleCount = 5
        case 40..<Int.max:
            sampleCount = 6
        default:break
        }
        
        return sampleCount
    }
    
    var imageSize: CGSize{
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any],
              let imageHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat,
              let imageWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat else {
            return .zero
        }
        return CGSize(width: imageWidth, height: imageHeight)
    }
}
