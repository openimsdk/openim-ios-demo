
import Foundation
import CryptoKit

extension URL {
    public var md5: String {
        let inputData = Data(self.relativeString.utf8)
        let md5Data = Insecure.MD5.hash(data: inputData)
        let md5Hex = md5Data.map { String(format: "%02hhx", $0) }.joined()
        
        return md5Hex
    }
    
    public var defaultThumbnailURL: URL? {
        absoluteString.defaultThumbnailURL
    }
    
    public func customThumbnailURL(size: CGSize = CGSize(width: 960, height: 960)) -> URL? {
        let r = absoluteString.customThumbnailURLString(size: size)
            
        return URL(string: r)
    }
    
    var parameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
        let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
