
import UIKit

public let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width
public let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
public let kStatusBarHeight: CGFloat = {
    if #available(iOS 13.0, *) {
        guard let statusBarHeight = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.size.height, statusBarHeight != 0 else { return 0 }
        return statusBarHeight
    } else {
        return UIApplication.shared.statusBarFrame.size.height
    }
}()

public let kSafeAreaBottomHeight: CGFloat = {
    guard let bottomHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom else { return 0 }
    return bottomHeight
}()

public let isIPhoneXSeries: Bool = {
    guard let bottomHeight = UIApplication.shared.windows.first?.safeAreaInsets.bottom, bottomHeight > 0 else { return false }
    return true
}()

extension UIFont {
    public static let f20 = UIFont.preferredFont(forTextStyle: .title3).withSize(20)
    public static let f17 = UIFont.preferredFont(forTextStyle: .body).withSize(17)
    public static let f16 = UIFont.preferredFont(forTextStyle: .body).withSize(16)
    public static let f14 = UIFont.preferredFont(forTextStyle: .footnote).withSize(14)
    public static let f12 = UIFont.preferredFont(forTextStyle: .caption1).withSize(12)
    public static let f10 = UIFont.preferredFont(forTextStyle: .caption2).withSize(10)
}

extension UIColor {
    public static let c0089FF = #colorLiteral(red: 0, green: 0.537254902, blue: 1, alpha: 1)
    public static let c0C1C33 = #colorLiteral(red: 0.04705882353, green: 0.1098039216, blue: 0.2, alpha: 1)
    public static let c333333 = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    public static let c8E9AB0 = #colorLiteral(red: 0.5568627451, green: 0.6039215686, blue: 0.6901960784, alpha: 1)
    public static let cE8EAEF = #colorLiteral(red: 0.9098039216, green: 0.9176470588, blue: 0.937254902, alpha: 1)
    public static let cFF381F = #colorLiteral(red: 1, green: 0.2196078431, blue: 0.1215686275, alpha: 1)
    public static let c6085B1 = #colorLiteral(red: 0.3764705882, green: 0.5215686275, blue: 0.6941176471, alpha: 1)
    public static let cCCE7FE = #colorLiteral(red: 0.8, green: 0.9058823529, blue: 0.9960784314, alpha: 1)
    public static let cF4F5F7 = #colorLiteral(red: 0.9589777589, green: 0.9590675235, blue: 0.9702622294, alpha: 1)
    public static let cF8F9FA = #colorLiteral(red: 0.9725490196, green: 0.9764705882, blue: 0.9803921569, alpha: 1)
    public static let cF0F2F6 = #colorLiteral(red: 0.9411764706, green: 0.9490196078, blue: 0.9647058824, alpha: 1)
    public static let cB3D7FF = #colorLiteral(red: 0.7019607843, green: 0.8431372549, blue: 1, alpha: 1)
    public static let cF2F8FF = #colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 1, alpha: 1)
    public static let cF0F0F0 = #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
    public static let c707070 = #colorLiteral(red: 0.4392156863, green: 0.4392156863, blue: 0.4392156863, alpha: 1)
    public static let cF1F1F1 = #colorLiteral(red: 0.9450980392, green: 0.9450980392, blue: 0.9450980392, alpha: 1)
    public static let c666666 = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
    public static let cE6F0FC = #colorLiteral(red: 0.9019607843, green: 0.9411764706, blue: 0.9882352941, alpha: 1)
    public static let c1B2236 = #colorLiteral(red: 0.1058823529, green: 0.1333333333, blue: 0.2117647059, alpha: 1)
    public static let c00D66A = #colorLiteral(red: 0, green: 0.8392156863, blue: 0.4156862745, alpha: 1)
    public static let viewBackgroundColor = UIColor.systemGroupedBackground
    public static let cellBackgroundColor = UIColor.tertiarySystemBackground
    public static let sepratorColor = UIColor.tertiarySystemGroupedBackground
}

extension CGFloat {
    public static let margin8 = 8.0
    public static let margin16 = 16.0
    public static let margin24 = 24.0
}

extension Int {
    public static let margin8 = 8
    public static let margin16 = 16
    public static let margin24 = 24
}

public struct StandardUI {
    public static let tailSize: CGFloat = 5
    public static let maxWidthRate: CGFloat = 0.85
    public static let cornerRadius = 5.0
    public static let margin_22: CGFloat = 22
    public static let avatarWidth: CGFloat = 44.w
}

public struct iLogger {
    static public func print(_ text: String,
                             fileName: String? = nil,
                             functionName: String? = nil,
                             line: Int = 0,
                             msgs: String? = nil,
                             err: String? = nil,
                             keyAndValues: [Any] = [],
                             onlyConsole: Bool = false) {
        Task {
            
            let t = "native/iOS/[\(functionName ?? "")]: \(text), \(!keyAndValues.isEmpty ? keyAndValues.map({ "\($0)" }).joined(separator: ", ") : "")"
            NSLog("[log] %@", t)
            
            if !onlyConsole {
                await IMController.shared.logs(fileName: fileName, line: line, msgs: t, err: err, keyAndValues: keyAndValues)
            }
        }
    }
}
