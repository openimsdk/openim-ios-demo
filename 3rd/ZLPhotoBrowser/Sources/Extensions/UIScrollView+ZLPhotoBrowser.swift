

























import UIKit

extension ZLPhotoBrowserWrapper where Base: UIScrollView {
    var contentInset: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return base.adjustedContentInset
        } else {
            return base.contentInset
        }
    }
    
    func scrollToTop(animated: Bool = true) {
        base.setContentOffset(CGPoint(x: 0, y: -contentInset.top), animated: animated)
    }
    
    func scrollToBottom(animated: Bool = true) {
        let contentSizeH = base.contentSize.height
        let insetBottom = contentInset.bottom
        let offsetY = contentSizeH + insetBottom - base.zl.height
        base.setContentOffset(CGPoint(x: 0, y: offsetY), animated: animated)
    }
}
