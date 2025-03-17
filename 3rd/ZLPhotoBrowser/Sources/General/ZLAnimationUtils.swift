

























import UIKit

class ZLAnimationUtils: NSObject {
    enum AnimationType: String {
        case fade = "opacity"
        case scale = "transform.scale"
        case rotate = "transform.rotation"
    }
    
    class func animation(
        type: ZLAnimationUtils.AnimationType,
        fromValue: CGFloat,
        toValue: CGFloat,
        duration: TimeInterval
    ) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: type.rawValue)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }
    
    class func springAnimation() -> CAKeyframeAnimation {
        let animate = CAKeyframeAnimation(keyPath: "transform")
        animate.duration = ZLPhotoUIConfiguration.default().selectBtnAnimationDuration
        animate.isRemovedOnCompletion = true
        animate.fillMode = .forwards
        
        animate.values = [
            CATransform3DMakeScale(0.7, 0.7, 1),
            CATransform3DMakeScale(1.15, 1.15, 1),
            CATransform3DMakeScale(0.9, 0.9, 1),
            CATransform3DMakeScale(1, 1, 1)
        ]
        return animate
    }
}
