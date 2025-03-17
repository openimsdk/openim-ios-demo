
import Foundation
import UIKit

private extension Int {
    public func duplicate4bits() -> Int {
        return (self << 4) + self
    }
}

extension UIColor {
    public convenience init?(hex: Int, alpha: Float = 1.0) {
        if (0x000000 ... 0xFFFFFF) ~= hex {
            self.init(hex6: Int(hex), alpha: alpha)
        } else {
            return nil
        }
    }

    public convenience init?(hexString: String, alpha: Float? = nil) {
        var hex = hexString

        if hex.hasPrefix("#") {
            hex = String(hex[hex.index(after: hex.startIndex)...])
        }

        guard let hexVal = Int(hex, radix: 16) else {
            return nil
        }

        switch hex.count {
        case 3:
            self.init(hex3: hexVal, alpha: alpha ?? 1.0)
        case 4:
            self.init(hex4: hexVal, alpha: alpha)
        case 6:
            self.init(hex6: hexVal, alpha: alpha ?? 1.0)
        case 8:
            self.init(hex8: hexVal, alpha: alpha)
        default:
            return nil
        }
    }

    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private convenience init?(hex3: Int, alpha: Float) {
        self.init(red: CGFloat(((hex3 & 0xF00) >> 8).duplicate4bits()) / 255.0,
                  green: CGFloat(((hex3 & 0x0F0) >> 4).duplicate4bits()) / 255.0,
                  blue: CGFloat(((hex3 & 0x00F) >> 0).duplicate4bits()) / 255.0,
                  alpha: CGFloat(alpha))
    }

    private convenience init?(hex4: Int, alpha: Float?) {
        self.init(red: CGFloat(((hex4 & 0xF000) >> 12).duplicate4bits()) / 255.0,
                  green: CGFloat(((hex4 & 0x0F00) >> 8).duplicate4bits()) / 255.0,
                  blue: CGFloat(((hex4 & 0x00F0) >> 4).duplicate4bits()) / 255.0,
                  alpha: alpha.map(CGFloat.init(_:)) ?? CGFloat(((hex4 & 0x000F) >> 0).duplicate4bits()) / 255.0)
    }

    private convenience init?(hex6: Int, alpha: Float) {
        self.init(red: CGFloat((hex6 & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((hex6 & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat((hex6 & 0x0000FF) >> 0) / 255.0, alpha: CGFloat(alpha))
    }

    private convenience init?(hex8: Int, alpha: Float?) {
        self.init(red: CGFloat((hex8 & 0xFF00_0000) >> 24) / 255.0,
                  green: CGFloat((hex8 & 0x00FF_0000) >> 16) / 255.0,
                  blue: CGFloat((hex8 & 0x0000_FF00) >> 8) / 255.0,
                  alpha: alpha.map(CGFloat.init(_:)) ?? CGFloat((hex8 & 0x0000_00FF) >> 0) / 255.0)
    }
}
