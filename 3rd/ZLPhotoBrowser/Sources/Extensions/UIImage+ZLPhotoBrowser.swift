

























import UIKit
import Accelerate
import MobileCoreServices


public extension ZLPhotoBrowserWrapper where Base: UIImage {
    static func animateGifImage(data: Data) -> UIImage? {

        let info: [String: Any] = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, info as CFDictionary) else {
            return UIImage(data: data)
        }
        
        var frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 1 else {
            return UIImage(data: data)
        }
        
        let maxFrameCount = ZLPhotoConfiguration.default().maxFrameCountForGIF
        
        let ratio = CGFloat(max(frameCount, maxFrameCount)) / CGFloat(maxFrameCount)
        frameCount = min(frameCount, maxFrameCount)
        
        var images = [UIImage]()
        var frameDuration = [Int]()
        
        for i in 0..<frameCount {
            let index = Int(floor(CGFloat(i) * ratio))
            
            guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, info as CFDictionary) else {
                return nil
            }

            let currFrameDuration = getFrameDuration(from: imageSource, at: index) * min(ratio, 3)

            frameDuration.append(Int(currFrameDuration * 1000))
            
            images.append(UIImage(cgImage: imageRef, scale: 1, orientation: .up))
        }

        let duration: Int = {
            var sum = 0
            for val in frameDuration {
                sum += val
            }
            return sum
        }()

        let gcd = gcdForArray(frameDuration)
        var frames = [UIImage]()

        for i in 0..<frameCount {
            let frameImage = images[i]

            let count = Int(frameDuration[i] / gcd)

            for _ in 0..<count {
                frames.append(frameImage)
            }
        }
        
        return .animatedImage(with: frames, duration: TimeInterval(duration) / 1000)
    }

    static func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
            as? [String: Any] else { return 0.0 }

        let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any]
        return getFrameDuration(from: gifInfo)
    }

    static func getFrameDuration(from gifInfo: [String: Any]?) -> TimeInterval {
        let defaultFrameDuration = 0.1
        guard let gifInfo = gifInfo else { return defaultFrameDuration }
        
        let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
        let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
        let duration = unclampedDelayTime ?? delayTime
        
        guard let frameDuration = duration else {
            return defaultFrameDuration
        }
        return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : defaultFrameDuration
    }
    
    private static func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = gcdForPair(val, gcd)
        }

        return gcd
    }

    private static func gcdForPair(_ num1: Int?, _ num2: Int?) -> Int {
        guard var num1 = num1, var num2 = num2 else {
            return num1 ?? (num2 ?? 0)
        }
        
        if num1 < num2 {
            swap(&num1, &num2)
        }

        var rest: Int
        while true {
            rest = num1 % num2

            if rest == 0 {
                return num2
            } else {
                num1 = num2
                num2 = rest
            }
        }
    }
}


public extension ZLPhotoBrowserWrapper where Base: UIImage {

    func fixOrientation() -> UIImage {
        if base.imageOrientation == .up {
            return base
        }
        
        var transform = CGAffineTransform.identity
        
        switch base.imageOrientation {
        case .down, .downMirrored:
            transform = CGAffineTransform(translationX: width, y: height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = CGAffineTransform(translationX: width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            transform = CGAffineTransform(translationX: 0, y: height)
            transform = transform.rotated(by: -CGFloat.pi / 2)
        default:
            break
        }
        
        switch base.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        guard let cgImage = base.cgImage, let colorSpace = cgImage.colorSpace else {
            return base
        }
        let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
        context?.concatenate(transform)
        switch base.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        
        guard let newCgImage = context?.makeImage() else {
            return base
        }
        return UIImage(cgImage: newCgImage)
    }

    func rotate(orientation: UIImage.Orientation) -> UIImage {
        guard let imagRef = base.cgImage else {
            return base
        }
        let rect = CGRect(origin: .zero, size: CGSize(width: CGFloat(imagRef.width), height: CGFloat(imagRef.height)))
        
        var bnds = rect
        
        var transform = CGAffineTransform.identity
        
        switch orientation {
        case .up:
            return base
        case .upMirrored:
            transform = transform.translatedBy(x: rect.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .down:
            transform = transform.translatedBy(x: rect.width, y: rect.height)
            transform = transform.rotated(by: .pi)
        case .downMirrored:
            transform = transform.translatedBy(x: 0, y: rect.height)
            transform = transform.scaledBy(x: 1, y: -1)
        case .left:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: 0, y: rect.width)
            transform = transform.rotated(by: CGFloat.pi * 3 / 2)
        case .leftMirrored:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: rect.height, y: rect.width)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi * 3 / 2)
        case .right:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.translatedBy(x: rect.height, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .rightMirrored:
            bnds = swapRectWidthAndHeight(bnds)
            transform = transform.scaledBy(x: -1, y: 1)
            transform = transform.rotated(by: CGFloat.pi / 2)
        @unknown default:
            return base
        }
        
        UIGraphicsBeginImageContext(bnds.size)
        let context = UIGraphicsGetCurrentContext()
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.scaleBy(x: -1, y: 1)
            context?.translateBy(x: -rect.height, y: 0)
        default:
            context?.scaleBy(x: 1, y: -1)
            context?.translateBy(x: 0, y: -rect.height)
        }
        context?.concatenate(transform)
        context?.draw(imagRef, in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? base
    }
    
    func swapRectWidthAndHeight(_ rect: CGRect) -> CGRect {
        var r = rect
        r.size.width = rect.height
        r.size.height = rect.width
        return r
    }
    
    func rotate(degress: CGFloat) -> UIImage {
        guard degress != 0, let cgImage = base.cgImage else {
            return base
        }
        
        let rotatedViewBox = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let t = CGAffineTransform(rotationAngle: degress)
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size

        UIGraphicsBeginImageContext(rotatedSize)
        
        let bitmap = UIGraphicsGetCurrentContext()
        bitmap?.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        bitmap?.rotate(by: degress)
        bitmap?.scaleBy(x: 1.0, y: -1.0)
        
        bitmap?.draw(cgImage, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? base
    }

    func mosaicImage() -> UIImage? {
        guard let cgImage = base.cgImage else {
            return nil
        }
        
        let scale = 8 * width / UIScreen.main.bounds.width
        let currCiImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(currCiImage, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        
        if let cgImage = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: base.size)) {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }
    
    func resize(_ size: CGSize, scale: CGFloat? = nil) -> UIImage? {
        if size.width <= 0 || size.height <= 0 {
            return nil
        }
        
        return UIGraphicsImageRenderer.zl.renderImage(size: size) { format in
            format.scale = scale ?? base.scale
        } imageActions: { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
        }
    }




    func resize_vI(_ size: CGSize, scale: CGFloat? = nil) -> UIImage? {
        guard let cgImage = base.cgImage else { return nil }
        
        var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: nil,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        
        var sourceBuffer = vImage_Buffer()
        defer {
            if #available(iOS 13.0, *) {
                sourceBuffer.free()
            } else {
                sourceBuffer.data.deallocate()
            }
        }
        
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let destBytesPerRow = destWidth * bytesPerPixel
        
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)

        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }

        guard let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue() else { return nil }
        guard error == kvImageNoError else { return nil }

        return UIImage(cgImage: destCGImage, scale: scale ?? base.scale, orientation: base.imageOrientation)
    }
    
    func toCIImage() -> CIImage? {
        var ciImage = base.ciImage
        if ciImage == nil, let cgImage = base.cgImage {
            ciImage = CIImage(cgImage: cgImage)
        }
        return ciImage
    }
    
    func clipImage(angle: CGFloat, editRect: CGRect, isCircle: Bool) -> UIImage {
        let a = ((Int(angle) % 360) - 360) % 360
        var newImage: UIImage = base
        if a == -90 {
            newImage = rotate(orientation: .left)
        } else if a == -180 {
            newImage = rotate(orientation: .down)
        } else if a == -270 {
            newImage = rotate(orientation: .right)
        }
        guard editRect.size != newImage.size else {
            return newImage
        }
        
        let origin = CGPoint(x: -editRect.minX, y: -editRect.minY)
        
        let temp = UIGraphicsImageRenderer.zl.renderImage(size: editRect.size) { format in
            format.scale = newImage.scale
        } imageActions: { context in
            if isCircle {
                context.addEllipse(in: CGRect(origin: .zero, size: editRect.size))
                context.clip()
            }
            newImage.draw(at: origin)
        }
        
        guard let cgi = temp.cgImage else { return temp }
        
        let clipImage = UIImage(cgImage: cgi, scale: newImage.scale, orientation: .up)
        return clipImage
    }
    
    func blurImage(level: CGFloat) -> UIImage? {
        guard let ciImage = toCIImage() else {
            return nil
        }
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: "inputImage")
        blurFilter?.setValue(level, forKey: "inputRadius")
        
        guard let outputImage = blurFilter?.outputImage else {
            return nil
        }
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    func hasAlphaChannel() -> Bool {
        guard let info = base.cgImage?.alphaInfo else {
            return false
        }
        
        return info == .first || info == .last || info == .premultipliedFirst || info == .premultipliedLast
    }
}

public extension ZLPhotoBrowserWrapper where Base: UIImage {





    func adjust(brightness: Float, contrast: Float, saturation: Float) -> UIImage? {
        guard let ciImage = toCIImage() else {
            return base
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(ZLEditImageConfiguration.AdjustTool.brightness.filterValue(brightness), forKey: ZLEditImageConfiguration.AdjustTool.brightness.key)
        filter?.setValue(ZLEditImageConfiguration.AdjustTool.contrast.filterValue(contrast), forKey: ZLEditImageConfiguration.AdjustTool.contrast.key)
        filter?.setValue(ZLEditImageConfiguration.AdjustTool.saturation.filterValue(saturation), forKey: ZLEditImageConfiguration.AdjustTool.saturation.key)
        let outputCIImage = filter?.outputImage
        return outputCIImage?.zl.toUIImage()
    }
}

public extension ZLPhotoBrowserWrapper where Base: UIImage {
    static func image(withColor color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func fillColor(_ color: UIColor) -> UIImage {
        return UIGraphicsImageRenderer.zl.renderImage(size: base.size) { format in
            format.scale = base.scale
        } imageActions: { _ in
            let drawRect = CGRect(origin: .zero, size: base.size)
            color.setFill()
            UIRectFill(drawRect)
            base.draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
        }

    }
}

public extension ZLPhotoBrowserWrapper where Base: UIImage {
    var width: CGFloat {
        base.size.width
    }
    
    var height: CGFloat {
        base.size.height
    }
}

extension ZLPhotoBrowserWrapper where Base: UIImage {
    static func getImage(_ named: String) -> UIImage? {
        if ZLCustomImageDeploy.imageNames.contains(named), let image = UIImage(named: named) {
            return image
        }
        if let image = ZLCustomImageDeploy.imageForKey[named] {
            return image
        }
        return UIImage(named: named, in: Bundle.zlPhotoBrowserBundle, compatibleWith: nil)
    }
}

public extension ZLPhotoBrowserWrapper where Base: CIImage {
    func toUIImage() -> UIImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(base, from: base.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
