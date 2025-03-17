


























import UIKit

/**
 A UIStackView that's intended for holding `InputItem`s
 
 ## Important Notes ##
 1. Default alignment is .fill
 2. Default distribution is .fill
 3. The distribution property needs to be based on its arranged subviews intrinsicContentSize so it is not recommended to change it
 */
open class InputStackView: UIStackView {






    public enum Position {
        case left, right, bottom, top
    }

    
    convenience init(axis: NSLayoutConstraint.Axis, spacing: CGFloat) {
        self.init(frame: .zero)
        self.axis = axis
        self.spacing = spacing
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
    }


    open func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        distribution = .fill
        alignment = .bottom
    }
    
}
