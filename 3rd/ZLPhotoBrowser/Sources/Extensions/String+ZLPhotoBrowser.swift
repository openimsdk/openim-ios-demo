

























import Foundation
import UIKit

extension ZLPhotoBrowserWrapper where Base == String {
    func boundingRect(font: UIFont, limitSize: CGSize) -> CGSize {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byCharWrapping
        
        let att = [NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: style]
        
        let attContent = NSMutableAttributedString(string: base, attributes: att)
        
        let size = attContent.boundingRect(with: limitSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
        
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
}
