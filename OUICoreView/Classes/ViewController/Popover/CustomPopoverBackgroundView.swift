
import Foundation
import UIKit

class CustomPopoverBackgroundView: UIPopoverBackgroundView {}

class CustomCollectionViewPopoverBackgroundView: CustomPopoverBackgroundView {
    private var _arrowOffSet: CGFloat = 0
    private var _arrowDirection: UIPopoverArrowDirection = [.up, .down]
    private let _arrowImageView: UIImageView = UIImageView(image: UIImage(nameInBundle: "popover_arrow_icon"))
    private let cornerRadius: CGFloat = 15

    private lazy var backgroundView: UIView = {
        let v = UIView()
        v.backgroundColor = .c0C1C33.withAlphaComponent(0.85)
        v.layer.cornerRadius = self.cornerRadius
        v.layer.shouldRasterize = true
        
        return v
    }()

    override class func arrowBase() -> CGFloat {
        14.0
    }

    override class func arrowHeight() -> CGFloat {
        9.0
    }

    override class func contentViewInsets() -> UIEdgeInsets {
        .zero
    }

    override var arrowOffset: CGFloat {
        
        set { 
            _arrowOffSet = newValue
            setNeedsLayout()
        }
        get { _arrowOffSet }
    }

    override var arrowDirection: UIPopoverArrowDirection {
        set { 
            _arrowDirection = newValue
            setNeedsLayout()}
        get { _arrowDirection }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backgroundView)
        addSubview(_arrowImageView)
        layer.shadowColor = UIColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var popoverImageOriginX: CGFloat = 0
        var popoverImageOriginY: CGFloat = 0

        var popoverImageWidth: CGFloat = bounds.size.width
        var popoverImageHeight: CGFloat = bounds.size.height

        var arrowImageOriginX: CGFloat = 0
        var arrowImageOriginY: CGFloat = 0

        var arrowImageWidth = Self.arrowBase()
        var arrowImageHeight = Self.arrowHeight()
        let cornerRadius: CGFloat = self.cornerRadius
        let arrowHeight = Self.arrowHeight()
        let arrowWidth = Self.arrowBase()

        switch arrowDirection {
        case .up:
            popoverImageOriginY = arrowHeight
            popoverImageHeight = bounds.size.height - arrowHeight

            arrowImageOriginX = round((bounds.size.width - arrowWidth) / 2.0 + arrowOffset)

            arrowImageOriginX = min(arrowImageOriginX, bounds.size.width - arrowWidth - cornerRadius)
            arrowImageOriginX = max(arrowImageOriginX, cornerRadius)
            _arrowImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        case .down:

            popoverImageHeight = bounds.size.height - arrowHeight

            arrowImageOriginX = round((bounds.size.width - arrowWidth) / 2 + arrowOffset)

            arrowImageOriginX = min(arrowImageOriginX, bounds.size.width - arrowWidth - cornerRadius)
            arrowImageOriginX = max(arrowImageOriginX, cornerRadius)

            arrowImageOriginY = popoverImageHeight
        case .left:

            popoverImageOriginX = arrowHeight - 2
            popoverImageWidth = bounds.size.width - arrowHeight

            arrowImageOriginY = round((bounds.size.height - arrowWidth) / 2 + arrowOffset)

            arrowImageOriginY = min(arrowImageOriginY, bounds.size.height - arrowWidth - cornerRadius)
            arrowImageOriginY = max(arrowImageOriginY, cornerRadius)

            arrowImageWidth = arrowHeight
            arrowImageHeight = arrowWidth
            _arrowImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        case .right:

            popoverImageWidth = bounds.size.width - arrowHeight + 2

            arrowImageOriginX = popoverImageWidth - 2
            arrowImageOriginY = round((bounds.size.height - arrowWidth) / 2 + arrowOffset)

            arrowImageOriginY = min(arrowImageOriginY, bounds.size.height - arrowWidth - cornerRadius)
            arrowImageOriginY = max(arrowImageOriginY, cornerRadius)

            arrowImageWidth = arrowHeight
            arrowImageHeight = arrowWidth
            _arrowImageView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        default:
            popoverImageHeight = bounds.size.height - arrowHeight + 2
        }

        backgroundView.frame = CGRect(x: popoverImageOriginX, y: popoverImageOriginY, width: popoverImageWidth, height: popoverImageHeight)
        _arrowImageView.frame = CGRect(x: arrowImageOriginX, y: arrowImageOriginY, width: arrowImageWidth, height: arrowImageHeight)
    }
}

