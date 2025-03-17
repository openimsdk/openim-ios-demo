
import Kingfisher
import UIKit

extension UIImageView {
    public func setImage(url: URL, thumbURL: URL? = nil, processorSize: CGSize = CGSize(width: 420.0, height: 420.0)) {
        kf.indicatorType = .activity
        
        let option: KingfisherOptionsInfo = thumbURL != nil ?
        [.backgroundDecode] :
            [
            .processor(DownsamplingImageProcessor(size: processorSize)),
            .scaleFactor(UIScreen.main.scale),
            .cacheOriginalImage,
        ]
        
        kf.setImage(with: thumbURL ?? url, options: option) { [weak self] r in
            guard let self else { return }
            
            if thumbURL != nil {
                kf.setImage(with: url, options: option)
            }
        }
    }
    
    public func setImage(with string: String?,
                         placeHolder: String? = nil,
                         placeholderImage: UIImage? = nil,
                         showIndicator: Bool = false,
                         original: Bool = true,
                         completion: ((UIImage?) -> Void)? = nil) {
        
        guard let string, !string.isEmpty, let url = URL(string: string) else {
            if let placeHolder = placeHolder {
                image = UIImage(named: placeHolder, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
            } else {
                image = nil
            }
            return
        }
        let placeImage: UIImage?
        if let placeHolder {
            placeImage = UIImage(named: placeHolder, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
        } else if let placeholderImage {
            placeImage = placeholderImage
        } else {
            placeImage = nil
        }
                
        if showIndicator {
            kf.indicatorType = .activity
        } else {
            kf.indicatorType = .none
        }
        
        var options: KingfisherOptionsInfo = original ? [.backgroundDecode, .cacheOriginalImage] :
            [.processor(DownsamplingImageProcessor(size: CGSize(width: 120, height: 120))),
            .scaleFactor(UIScreen.main.scale),
            .backgroundDecode]
        
        kf.setImage(with: url,
                    placeholder: placeImage,
                    options: options) { [weak self] r in
                            guard let self else { return }
                            
                            if case .success(let image) = r {
                                completion?(image.image)
                            } else {
                                completion?(nil)
                            }
        }
    }
    
    public func setImagePath(_ path: String, placeHolder _: String?) {
        if !FileManager.default.fileExists(atPath: path) {
            return
        }
        let url = URL(fileURLWithPath: path)
        image = UIImage(contentsOfFile: url.path)
    }
    
    public func cancelDownload() {
        kf.cancelDownloadTask()
    }
}

extension UIImage {
    public convenience init?(nameInBundle: String) {
        self.init(named: nameInBundle, in: ViewControllerFactory.getBundle(), compatibleWith: nil)
    }
    
    public convenience init?(nameInEmoji: String) {
        self.init(named: nameInEmoji, in: ViewControllerFactory.getEmojiBundle(), compatibleWith: nil)
    }
    
    public convenience init?(path: String?) {
        if let path = path {
            self.init(contentsOfFile: path)
        } else {
            return nil
        }
    }
    
    public func compress(expectSize: Int) -> UIImage {
        
        if let inputData = pngData(), let data = ImageCompress.compressImageData(inputData, expectSize: expectSize) {
            return UIImage(data: data) ?? self
        }
        
        return self
    }
}

extension UIImage {
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        
        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)
            }
        }
        
        return UIImage.animatedImage(with: images, duration: 0.0)
    }
}

extension UIImageView {
    public func loadGif(name: String? = nil, url: String? = nil, expectSize: Int = 200 * 1024) {
        
        DispatchQueue.global().async {
            if name != nil {
                let image = UIImage.gif(name: name!)
                DispatchQueue.main.async {
                    self.image = image
                }
            } else if url != nil {
                let image = UIImage.gif(url: url!, expectSize: expectSize)
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}

extension UIImage {
    public class func gif(data: Data) -> UIImage? {

        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("SwiftGif: Source for the image does not exist")
            return nil
        }
        return UIImage.animatedImageWithSource(source)
    }
    public class func gif(url: String, expectSize: Int) -> UIImage? {

        guard let bundleURL = URL(string: url) else {
            print("SwiftGif: This image named \"\(url)\" does not exist")
            return nil
        }
        
        if let path = FileHelper.shared.exsit(path: url),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            return gif(data: data)
        } else {

            guard let imageData = try? Data(contentsOf: bundleURL) else {
                print("SwiftGif: Cannot turn image named \"\(url)\" into NSData")
                return nil
            }
            
            let compressData = ImageCompress.compressImageData(imageData, expectSize: expectSize) ?? imageData
            FileHelper.shared.saveFileData(data: compressData, path: url)
            
            return gif(data: compressData)
        }
    }
    
    public class func gif(name: String) -> UIImage? {

        guard let bundle = ViewControllerFactory.getBundle(), let bundleURL = bundle.url(forResource: name, withExtension: "gif") else {
            print("SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }

        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        return gif(data: imageData)
    }
    internal class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1

        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        if CFDictionaryGetValueIfPresent(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque(), gifPropertiesPointer) == false {
            return delay
        }
        let gifProperties:CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)

        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                                 Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        delay = delayObject as? Double ?? 0
        if delay < 0.1 {
            delay = 0.1 // Make sure they're not too fast
        }
        return delay
    }
    internal class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b

        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }

        if a! < b! {
            let c = a
            a = b
            b = c
        }

        var rest: Int
        while true {
            rest = a! % b!
            if rest == 0 {
                return b! // Found it
            } else {
                a = b
                b = rest
            }
        }
    }
    internal class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        var gcd = array[0]
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        return gcd
    }
    internal class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        for i in 0..<count {

            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }

            let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                                                            source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }

        let duration: Int = {
            var sum = 0
            for val: Int in delays {
                sum += val
            }
            return sum
        }()

        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }

        let animation = UIImage.animatedImage(with: frames,
                                              duration: Double(duration) / 3000.0)
        return animation
    }
}

extension UIImage {
    public class func image(with color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
