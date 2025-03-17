

























import UIKit

extension ZLPhotoBrowserWrapper where Base: UIView {
    var top: CGFloat {
        base.frame.minY
    }
    
    var bottom: CGFloat {
        base.frame.maxY
    }
    
    var left: CGFloat {
        base.frame.minX
    }
    
    var right: CGFloat {
        base.frame.maxX
    }
    
    var width: CGFloat {
        base.frame.width
    }
    
    var height: CGFloat {
        base.frame.height
    }
    
    var size: CGSize {
        base.frame.size
    }
    
    var center: CGPoint {
        base.center
    }
    
    var centerX: CGFloat {
        base.center.x
    }
    
    var centerY: CGFloat {
        base.center.y
    }
    
    var snapshotImage: UIImage {
        return UIGraphicsImageRenderer.zl.renderImage(size: base.zl.size) { format in
            format.opaque = base.isOpaque
        } imageActions: { context in
            base.layer.render(in: context)
        }
    }
    
    func setCornerRadius(_ radius: CGFloat) {
        base.layer.cornerRadius = radius
        base.layer.masksToBounds = true
    }
    
    func addBorder(color: UIColor, width: CGFloat) {
        base.layer.borderColor = color.cgColor
        base.layer.borderWidth = width
    }
    
    func addShadow(color: UIColor, radius: CGFloat, opacity: Float = 1, offset: CGSize = .zero) {
        base.layer.shadowColor = color.cgColor
        base.layer.shadowRadius = radius
        base.layer.shadowOpacity = opacity
        base.layer.shadowOffset = offset
    }
}
