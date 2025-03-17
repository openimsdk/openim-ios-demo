
import UIKit

class UnderlineTextField: UITextField {
    let underline: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(underline)
        underline.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
