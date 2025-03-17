
import Foundation
import Localize_Swift
import CryptoKit

extension String {

    subscript(of index: Int) -> String {
        if index < 0 || index >= count {
            return ""
        }
        for (i, item) in enumerated() {
            if index == i {
                return "\(item)"
            }
        }
        return ""
    }

    subscript(r: ClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(r.lowerBound, 0))
        let end = index(startIndex, offsetBy: min(r.upperBound, count - 1))
        return String(self[start ... end])
    }

    subscript(r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: max(r.lowerBound, 0))
        let end = index(startIndex, offsetBy: min(r.upperBound, count))
        return String(self[start ..< end])
    }

    subscript(r: PartialRangeThrough<Int>) -> String {
        let end = index(startIndex, offsetBy: min(r.upperBound, count - 1))
        return String(self[startIndex ... end])
    }

    subscript(r: PartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(r.lowerBound, 0))
        let end = index(startIndex, offsetBy: count - 1)
        return String(self[start ... end])
    }

    subscript(r: PartialRangeUpTo<Int>) -> String {
        let end = index(startIndex, offsetBy: min(r.upperBound, count))
        return String(self[startIndex ..< end])
    }



    func subString(_ index: Int) -> String {
        guard index < count else {
            return ""
        }
        let start = self.index(endIndex, offsetBy: index - count)
        return String(self[start ..< endIndex])
    }





    func substring(start: Int, _ count: Int) -> String {
        let begin = index(startIndex, offsetBy: max(0, start))
        let end = index(startIndex, offsetBy: min(count, start + count))
        return String(self[begin ..< end])
    }
    
    public func innerLocalized() -> String {
        let bundle = ViewControllerFactory.getBundle()
        let str = localized(using: nil, in: bundle)
        return str
    }
    
    public func innerLocalizedFormat(arguments: CVarArg...) -> String {
        let bundle = ViewControllerFactory.getBundle()
        let str = localizedFormat(arguments: arguments, using: nil, in: bundle)
        
        return str
    }
    
    public func append(string: String?) -> String {
        if let string = string {
            var mutString: String = self
            mutString.append(string)
            return mutString
        }
        return self
    }
    
    public func getFirstPinyinUppercaseCharactor() -> String? {
        if !self.isEmpty {
            let format: HanyuPinyinOutputFormat = {
                let v = HanyuPinyinOutputFormat.init()!
                v.caseType = CaseType.init(0)
                v.toneType = ToneType.init(1)
                v.vCharType = VCharType.init(1)
                return v
            }()
            let ret = PinyinHelper.toHanyuPinyinString(with: "\(self.first!)", with: format, with: " ")
            
            if let first = ret?.first?.uppercased() {
                if first >= "A", first <= "Z" {
                    return "\(first)"
                }
                return "#"
            }
            return ret
        } else {
            return nil
        }
    }






    public func textLines(_ maxWidth: CGFloat, font: UIFont) -> [String] {
        let myFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        
        let attStr = NSMutableAttributedString(string: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        
        attStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attStr.length))
        attStr.addAttribute(NSAttributedString.Key(kCTFontAttributeName as String), value: myFont, range: NSRange(location: 0, length: attStr.length))
        let frameSetter = CTFramesetterCreateWithAttributedString(attStr)
        
        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width:maxWidth, height: 100000), transform: .identity)
        
        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(CFIndex(0), CFIndex(0)), path, nil)
        let lines = CTFrameGetLines(frame) as? [AnyHashable]
        var linesArray: [String] = []
        
        for line in lines ?? [] {
            let lineRange = CTLineGetStringRange(line as! CTLine)
            let range = NSRange(location: lineRange.location, length: lineRange.length)
            
            let lineString = (self as NSString).substring(with: range)
            CFAttributedStringSetAttribute(attStr, lineRange, kCTKernAttributeName, (NSNumber(value: 0.0)))
            linesArray.append(lineString)
        }
        return linesArray
    }
    
    public var md5: String {
        let inputData = Data(self.utf8)
        let md5Data = Insecure.MD5.hash(data: inputData)
        let md5Hex = md5Data.map { String(format: "%02hhx", $0) }.joined()
        
        return md5Hex
    }
    
    public func customThumbnailURLString(size: CGSize = CGSize(width: 120, height: 120)) -> String {
        let c = self.components(separatedBy: "?")
        if let host  = c.first {
            let ajustHost = host.lowercased().hasSuffix(".gif") ? host : host + "?height=\(size.height)&type=image&width=\(size.width)"
            let temp = ajustHost.removingPercentEncoding
            
            return temp?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ajustHost
        }
        
        return self
    }
    
    public var defaultThumbnailURLString: String {
        customThumbnailURLString(size: CGSize(width: 960, height: 960))
    }
    
    public var defaultThumbnailURL: URL? {
        URL(string: defaultThumbnailURLString)
    }
    
    public func toURL() -> URL? {
        let ajustURL = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self

        return URL(string: ajustURL)
    }
    
    public func toFileURL() -> URL {
        let ajustURL = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
        
        return URL(fileURLWithPath: ajustURL)
    }
    
    public mutating func replace(_ target: String, withString: String) {
        var tempText = self
        
        let mentionPattern = "\(target)\\b"
        let regex = try! NSRegularExpression(pattern: mentionPattern)
            
        tempText = regex.stringByReplacingMatches(in: tempText,
                                                  options: [],
                                                  range: NSRange(location: 0, length: tempText.utf16.count),
                                                  withTemplate: "\(withString)")
        
        self = tempText
    }
}

extension String {
    public func isValidEmail() -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        
        if let regex = try? NSRegularExpression(pattern: emailRegex, options: .caseInsensitive) {
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
            
            if let firstMatch = matches.first, NSRange(location: 0, length: self.utf16.count) == firstMatch.range {
                return true
            }
        }
        
        return false
    }
}

extension String {
    public func addHyberLink() -> NSAttributedString? {
        let attr = NSMutableAttributedString(string: self)
        attr.addAttributes([.font: UIFont.f17, .foregroundColor: UIColor.c0C1C33], range: NSMakeRange(0, attr.length))
        let regex = try! NSRegularExpression(pattern: "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)", options: [])

        let matches = regex.matches(in: attr.string, options: [], range: NSRange(location: 0, length: attr.length))
        
        if matches.isEmpty {
            return nil
        }
        
        for match in matches {
            let matchRange = match.range
            let urlString = (attr.string as NSString).substring(with: matchRange)
            attr.addAttribute(.link, value: urlString, range: matchRange)
            attr.addAttribute(.foregroundColor, value: UIColor.c0089FF, range: matchRange)
            attr.addAttribute(.underlineStyle, value: 0, range: matchRange)
        }
        
        return attr
    }
}

