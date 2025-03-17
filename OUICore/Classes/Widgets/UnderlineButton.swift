
import UIKit

public class UnderlineButton: UIButton {
    let underline: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue
        return v
    }()

    public var underLineWidth: CGFloat? {
        didSet {
            if let underLineWidth = underLineWidth {
                underline.snp.remakeConstraints { make in
                    make.bottom.centerX.equalToSuperview()
                    make.width.equalTo(underLineWidth)
                    make.height.equalTo(3)
                }
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(underline)
        underline.snp.makeConstraints { make in
            make.bottom.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(3)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var isSelected: Bool {
        didSet {
            underline.isHidden = !isSelected
        }
    }
}
