

























import UIKit

extension ZLPhotoBrowserWrapper where Base: UIFont {
    static func font(ofSize size: CGFloat, bold: Bool = false) -> UIFont {
        guard let name = ZLCustomFontDeploy.fontName else {
            return UIFont.systemFont(ofSize: size, weight: bold ? .medium : .regular)
        }
        
        return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size, weight: bold ? .medium : .regular)
    }
}
