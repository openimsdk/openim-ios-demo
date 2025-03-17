


























import UIKit

/**
 A UIView thats intrinsicContentSize is overrided so an exact height can be specified
 
 ## Important Notes ##
 1. Default height is 1 pixel
 2. Default backgroundColor is UIColor.lightGray
 3. Intended to be used in an `InputStackView`
 */
open class SeparatorLine: UIView {


  open var height: CGFloat = 1.0 / UIScreen.main.scale {
        didSet {
            constraints.filter { $0.identifier == "height" }.forEach { $0.constant = height } // Assumes constraint was given an identifier
            invalidateIntrinsicContentSize()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: super.intrinsicContentSize.width, height: height)
    }

    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    open func setup() {
        if #available(iOS 13, *) {
            backgroundColor = .systemGray2
        } else {
            backgroundColor = .lightGray
        }
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
}
