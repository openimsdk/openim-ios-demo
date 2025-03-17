

























import UIKit

public class ZLEnlargeButton: UIButton {

    public var enlargeInsets: UIEdgeInsets = .zero

    public var enlargeInset: CGFloat = 0 {
        didSet {
            let inset = max(0, enlargeInset)
            enlargeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        }
    }
    
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden, alpha != 0 else {
            return false
        }
        
        let rect = enlargeRect()
        if rect.equalTo(bounds) {
            return super.point(inside: point, with: event)
        }
        return rect.contains(point) ? true : false
    }
    
    private func enlargeRect() -> CGRect {
        guard enlargeInsets != .zero else {
            return bounds
        }
        
        let rect = CGRect(
            x: bounds.minX - enlargeInsets.left,
            y: bounds.minY - enlargeInsets.top,
            width: bounds.width + enlargeInsets.left + enlargeInsets.right,
            height: bounds.height + enlargeInsets.top + enlargeInsets.bottom
        )
        return rect
    }
}
