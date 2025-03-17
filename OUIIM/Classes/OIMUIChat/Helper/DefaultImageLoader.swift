
import Foundation
import Kingfisher

class DefaultImageCacher {
    class func loadImage(url: URL, thumbURL: URL?, processorSize: CGSize = CGSize(width: 420.0, height: 420.0), completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString

        if KingfisherManager.shared.cache.isCached(forKey: key) {
            if let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: key, options: nil) {
                
                completion(image)
            } else {
                if let data = try? KingfisherManager.shared.cache.diskStorage.value(forKey: key) {
                    let image = UIImage(data: data)
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        } else {
            let tempURL = thumbURL ?? url
            
            KingfisherManager.shared.retrieveImage(with: tempURL,
                                                   options: [
                                                    .processor(DownsamplingImageProcessor(size: processorSize)),
                                                    .scaleFactor(UIScreen.main.scale),
                                                    .cacheOriginalImage
                                                   ]) { [self] result in
                switch result {
                case .success(let imgResult):
                    let image = imgResult.image
                    
                    completion(image)
                case .failure(let error):
                    print("\(#function) throw error: \(error)")
                }
            }
        }
    }
    
    
    public class func cacheLocalData(path: String, completion: ((Data?) -> Void)? = nil) {
        DispatchQueue.global().async { [self] in
            let url = URL(string: path)

            if let url, let data = try? Data(contentsOf: url) {
                if path.lowercased().hasSuffix(".gif") {
                    cacheLoacalGIF(path: path, data: data)
                } else {
                    if let image = UIImage(data: data) {
                        cacheLocalImage(path: path, image: image)
                    }
                }
                
                completion?(data)
            } else {
                completion?(nil)
            }
        }
    }
    
    public class func cacheLocalImage(path: String, image: UIImage? = nil) -> UIImage? {
        if let image {
            KingfisherManager.shared.cache.store(image, forKey: path)
        } else {
            if path.lowercased().hasSuffix(".gif") {
                cacheLoacalGIF(path: path)
            } else {
                if let image = UIImage(contentsOfFile: path) {
                    do {
                        KingfisherManager.shared.cache.store(image, forKey: path)
                    } catch (let e) {
                        print("\(#function) throw error:\(e)")
                    }
                    
                    return image
                }
            }
        }
        return nil
    }
    
    public class func cacheLoacalGIF(path: String, data: Data? = nil) {
        guard let url = URL(string: path) else { return }

        DispatchQueue.global().async {
            if let data {
                let option: KingfisherParsedOptionsInfo = KingfisherParsedOptionsInfo(nil)
                if let image = DefaultImageProcessor.default.process(item: .data(data), options: option) {
                    KingfisherManager.shared.cache.store(image, original: data, forKey: path, toDisk: true)
                }
            } else {
                if let data = try? Data(contentsOf: url) {
                    let option: KingfisherParsedOptionsInfo = KingfisherParsedOptionsInfo(nil)
                    if let image = DefaultImageProcessor.default.process(item: .data(data), options: option) {
                        KingfisherManager.shared.cache.store(image, original: data, forKey: path, toDisk: true)
                    }
                }
            }
        }
    }
}
