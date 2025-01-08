
import Foundation
import ImageIO

public enum ColorConfig {
    case alpha8
    case rgb565
    case argb8888
    case rgbaF16
    case unknown 
}

public class ImageCompress {






    public static func changeColorWithImageData(_ rawData:Data, config: ColorConfig) -> Data? {
        guard let imageConfig = config.imageConfig else {
            return rawData
        }
        
        guard let imageSource = CGImageSourceCreateWithData(rawData as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let writeData = CFDataCreateMutable(nil, 0),
              let imageType = CGImageSourceGetType(imageSource),
              let imageDestination = CGImageDestinationCreateWithData(writeData, imageType, 1, nil),
              let rawDataProvider = CGDataProvider(data: rawData as CFData),
              let imageFrame = CGImage(width: Int(rawData.imageSize.width),
                                       height: Int(rawData.imageSize.height),
                                       bitsPerComponent: imageConfig.bitsPerComponent,
                                       bitsPerPixel: imageConfig.bitsPerPixel,
                                       bytesPerRow: 0,
                                       space: CGColorSpaceCreateDeviceRGB(),
                                       bitmapInfo: imageConfig.bitmapInfo,
                                       provider: rawDataProvider,
                                       decode: nil,
                                       shouldInterpolate: true,
                                       intent: .defaultIntent) else {
            return nil
        }
        CGImageDestinationAddImage(imageDestination, imageFrame, nil)
        guard CGImageDestinationFinalize(imageDestination) else {
            return nil
        }
        return writeData as Data
    }




    public static func getColorConfigWithImageData(_ rawData: Data) -> ColorConfig {
        guard let imageSource = CGImageSourceCreateWithData(rawData as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let imageFrame = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return .unknown
        }
        return imageFrame.colorConfig
    }






    public static func compressImageData(_ rawData:Data, limitLongWidth: CGFloat) -> Data?{
        guard max(rawData.imageSize.height, rawData.imageSize.width) > limitLongWidth else {
            return rawData
        }
        
        guard let imageSource = CGImageSourceCreateWithData(rawData as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let writeData = CFDataCreateMutable(nil, 0),
              let imageType = CGImageSourceGetType(imageSource) else {
            return nil
        }
        
        
        let frameCount = CGImageSourceGetCount(imageSource)
        
        guard let imageDestination = CGImageDestinationCreateWithData(writeData, imageType, frameCount, nil) else{
            return nil
        }

        let options = [kCGImageSourceThumbnailMaxPixelSize: limitLongWidth, kCGImageSourceCreateThumbnailWithTransform:true, kCGImageSourceCreateThumbnailFromImageIfAbsent:true] as CFDictionary
        
        if frameCount > 1 {

            let frameDurations = imageSource.frameDurations

            let resizedImageFrames = (0..<frameCount).compactMap{ CGImageSourceCreateThumbnailAtIndex(imageSource, $0, options) }

            zip(resizedImageFrames, frameDurations).forEach {

                let frameProperties = [kCGImagePropertyGIFDictionary : [kCGImagePropertyGIFDelayTime: $1, kCGImagePropertyGIFUnclampedDelayTime: $1]]
                CGImageDestinationAddImage(imageDestination, $0, frameProperties as CFDictionary)
            }
        } else {
            guard let resizedImageFrame = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
                return nil
            }
            CGImageDestinationAddImage(imageDestination, resizedImageFrame, nil)
        }
        
        guard CGImageDestinationFinalize(imageDestination) else {
            return nil
        }
        
        return writeData as Data
    }






    public static func compressImageData(_ rawData: Data, expectSize: Int) -> Data?{
        guard rawData.count > expectSize else {
            return rawData
        }
        
        var resultData = rawData

        if resultData.imageFormat == .jpeg {
            var compression: Double = 1
            var maxCompression: Double = 1
            var minCompression: Double = 0
            for _ in 0..<6 {
                compression = (maxCompression + minCompression) / 2
                if let data = compressImageData(resultData, compression: compression){
                    resultData = data
                } else {
                    return nil
                }
                if resultData.count < Int(CGFloat(expectSize) * 0.9) {
                    minCompression = compression
                } else if resultData.count > expectSize {
                    maxCompression = compression
                } else {
                    break
                }
            }
            if resultData.count <= expectSize {
                return resultData
            }
        }

        if resultData.imageFormat == .gif {
            let sampleCount = resultData.fitSampleCount
            if let data = compressImageData(resultData, sampleCount: sampleCount){
                resultData = data
            } else {
                return nil
            }
            if resultData.count <= expectSize {
                return resultData
            }
        }
        
        var longSideWidth = max(resultData.imageSize.height, resultData.imageSize.width)

        while resultData.count > expectSize {
            let ratio = sqrt(CGFloat(expectSize) / CGFloat(resultData.count))
            longSideWidth *= ratio
            if let data = compressImageData(resultData, limitLongWidth: longSideWidth) {
                resultData = data
            } else {
                return nil
            }
        }
        return resultData
    }






    static func compressImageData(_ rawData:Data, sampleCount:Int) -> Data?{
        guard let imageSource = CGImageSourceCreateWithData(rawData as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let writeData = CFDataCreateMutable(nil, 0),
              let imageType = CGImageSourceGetType(imageSource) else {
            return nil
        }

        let frameDurations = imageSource.frameDurations

        let mergeFrameDurations = (0..<frameDurations.count).filter{ $0 % sampleCount == 0 }.map{ min(frameDurations[$0..<min($0 + sampleCount, frameDurations.count)].reduce(0.0) { $0 + $1 }, 0.2) }

        let sampleImageFrames = (0..<frameDurations.count).filter{ $0 % sampleCount == 0 }.compactMap{ CGImageSourceCreateImageAtIndex(imageSource, $0, nil) }
        
        guard let imageDestination = CGImageDestinationCreateWithData(writeData, imageType, sampleImageFrames.count, nil) else{
            return nil
        }

        zip(sampleImageFrames, mergeFrameDurations).forEach{

            let frameProperties = [kCGImagePropertyGIFDictionary : [kCGImagePropertyGIFDelayTime: $1, kCGImagePropertyGIFUnclampedDelayTime: $1]]
            CGImageDestinationAddImage(imageDestination, $0, frameProperties as CFDictionary)
        }
        
        guard CGImageDestinationFinalize(imageDestination) else {
            return nil
        }
        
        return writeData as Data
    }






    static func compressImageData(_ rawData:Data, compression:Double) -> Data?{
        guard let imageSource = CGImageSourceCreateWithData(rawData as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let writeData = CFDataCreateMutable(nil, 0),
              let imageType = CGImageSourceGetType(imageSource),
              let imageDestination = CGImageDestinationCreateWithData(writeData, imageType, 1, nil) else {
            return nil
        }
        
        let frameProperties = [kCGImageDestinationLossyCompressionQuality: compression] as CFDictionary
        CGImageDestinationAddImageFromSource(imageDestination, imageSource, 0, frameProperties)
        guard CGImageDestinationFinalize(imageDestination) else {
            return nil
        }
        return writeData as Data
    }
}

extension CGImageSource {
    func frameDurationAtIndex(_ index: Int) -> Double{
        var frameDuration = Double(0.1)
        guard let frameProperties = CGImageSourceCopyPropertiesAtIndex(self, index, nil) as? [AnyHashable:Any], let gifProperties = frameProperties[kCGImagePropertyGIFDictionary] as? [AnyHashable:Any] else {
            return frameDuration
        }
        
        if let unclampedDuration = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber {
            frameDuration = unclampedDuration.doubleValue
        } else {
            if let clampedDuration = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber {
                frameDuration = clampedDuration.doubleValue
            }
        }
        
        if frameDuration < 0.011 {
            frameDuration = 0.1
        }
        
        return frameDuration
    }
    
    var frameDurations:[Double]{
        let frameCount = CGImageSourceGetCount(self)
        return (0..<frameCount).map{ self.frameDurationAtIndex($0) }
    }
}

extension ColorConfig {
    struct CGImageConfig{
        let bitsPerComponent:Int
        let bitsPerPixel:Int
        let bitmapInfo: CGBitmapInfo
    }
    
    var imageConfig:CGImageConfig? {
        switch self {
        case .alpha8:
            return CGImageConfig(bitsPerComponent: 8, bitsPerPixel: 8, bitmapInfo: CGBitmapInfo(.alphaOnly))
        case .rgb565:
            return CGImageConfig(bitsPerComponent: 5, bitsPerPixel: 16, bitmapInfo: CGBitmapInfo(.noneSkipFirst))
        case .argb8888:
            return CGImageConfig(bitsPerComponent: 8, bitsPerPixel: 32, bitmapInfo: CGBitmapInfo(.premultipliedFirst))
        case .rgbaF16:
            return CGImageConfig(bitsPerComponent: 16, bitsPerPixel: 64, bitmapInfo: CGBitmapInfo(.premultipliedLast, true))
        case .unknown:
            return nil
        }
    }
}

extension CGBitmapInfo {
    init(_ alphaInfo:CGImageAlphaInfo, _ isFloatComponents:Bool = false) {
        var array = [
            CGBitmapInfo(rawValue: alphaInfo.rawValue),
            CGBitmapInfo(rawValue: CGImageByteOrderInfo.orderDefault.rawValue)
        ]
        
        if isFloatComponents {
            array.append(.floatComponents)
        }
        
        self.init(array)
    }
}


extension CGImage {
    var colorConfig:ColorConfig{
        if isColorConfig(.alpha8) {
            return .alpha8
        } else if isColorConfig(.rgb565) {
            return .rgb565
        } else if isColorConfig(.argb8888) {
            return .argb8888
        } else if isColorConfig(.rgbaF16) {
            return .rgbaF16
        } else {
            return .unknown
        }
    }
    
    func isColorConfig(_ colorConfig:ColorConfig) -> Bool{
        guard let imageConfig = colorConfig.imageConfig else {
            return false
        }
        
        if bitsPerComponent == imageConfig.bitsPerComponent &&
            bitsPerPixel == imageConfig.bitsPerPixel &&
            imageConfig.bitmapInfo.contains(CGBitmapInfo(alphaInfo)) &&
            imageConfig.bitmapInfo.contains(.floatComponents) {
            return true
        } else {
            return false
        }
    }
}
