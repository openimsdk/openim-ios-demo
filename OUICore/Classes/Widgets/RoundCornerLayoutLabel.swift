
import SnapKit
import UIKit

public class RoundCornerLayoutLabel: UIView {

    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            _hStack.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(contentInset)
            }
        }
    }

    public var paddingOfIconAndText: CGFloat = 0 {
        didSet {
            _hStack.spacing = paddingOfIconAndText
        }
    }

    public var imageSize: CGSize? {
        didSet {
            if let size = imageSize {
                iconImageView.snp.remakeConstraints { make in
                    make.size.equalTo(size)
                }
            } else {
                iconImageView.snp_removeConstraints()
            }
            checkValue()
        }
    }

    public var text: String? {
        didSet {
            _label.text = text
            checkValue()
        }
    }

    public var textColor: UIColor = .black {
        didSet {
            _label.textColor = textColor
        }
    }

    public var font: UIFont = UIFont.systemFont(ofSize: 14) {
        didSet {
            _label.font = font
        }
    }

    public var textAlignment: NSTextAlignment = .left {
        didSet {
            _label.textAlignment = textAlignment
        }
    }

    private lazy var _label: UILabel = {
        let v = UILabel()
        return v
    }()

    private lazy var iconImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        return v
    }()

    private var radius_: CGFloat?
    private var corners_: UIRectCorner
    private var shapeLayer_: CAShapeLayer = .init()
    private var _iconImage: UIImage?
    private lazy var _hStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [iconImageView, _label])
        v.axis = .horizontal
        v.distribution = .equalSpacing
        v.alignment = .center
        return v
    }()




    public init(roundCorners: UIRectCorner, radius: CGFloat?) {
        corners_ = roundCorners
        radius_ = radius
        super.init(frame: .zero)
        addSubview(_hStack)
        _hStack.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        checkValue()
    }





    init(icon: UIImage?, roundCorners: UIRectCorner, radius: CGFloat?) {
        _iconImage = icon
        corners_ = roundCorners
        radius_ = radius
        super.init(frame: .zero)
        iconImageView.image = icon
        addSubview(_hStack)
        _hStack.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        checkValue()
    }

    private func checkValue() {
        iconImageView.isHidden = _iconImage == nil
        _label.isHidden = text == nil
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let radius = radius_ ?? bounds.size.height / 2
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners_, cornerRadii: CGSize(width: radius, height: radius)).cgPath
        shapeLayer_.frame = bounds
        shapeLayer_.path = path
        layer.mask = shapeLayer_
    }
}
