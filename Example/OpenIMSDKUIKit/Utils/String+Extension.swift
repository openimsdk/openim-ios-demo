
import Foundation
import CommonCrypto

extension String {
    func md5() -> String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate()
        return String(format: hash as String)
    }
    // Contains at least one number, one letter, and one special character.
    func validatePassword() -> Bool {
        let passwordRegex = "^(?=.*[a-zA-Z])(?=.*\\d).{6,20}$"
        
        do {
            let regex = try NSRegularExpression(pattern: passwordRegex, options: [])
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            return matches.count > 0
        } catch {
            print("Invalid regex pattern: \(error.localizedDescription)")
            return false
        }
    }
}
