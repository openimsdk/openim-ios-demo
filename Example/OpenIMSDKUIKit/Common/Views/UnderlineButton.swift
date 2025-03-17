
import UIKit

class UnderlineButton: UIButton {
    
    let underline: UIView = {
        let v = UIView()
        v.backgroundColor = DemoUI.color_1B72EC
        return v
    }()
    
    var underLineWidth: CGFloat? {
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(underline)
        underline.snp.makeConstraints { make in
            make.bottom.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(3)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            underline.isHidden = !isSelected
        }
    }
}
