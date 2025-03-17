
import Foundation
import OUICore

class ChatTitleView: UIView {
    
    lazy var dotView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.layer.masksToBounds = true
        v.isHidden = true
        
        v.snp.makeConstraints { make in
            make.size.equalTo(8)
        }
        return v
    }()
    
    lazy var mainLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        v.textAlignment = .center

        return v
    }()
    
    lazy var mainTailLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        v.textAlignment = .center
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        
        return v
    }()
    
    lazy var subLabel: UILabel = {
        let v = UILabel()
        v.font = .f10
        v.textColor = .c8E9AB0
        v.textAlignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(UILayoutPriority(999), for: .horizontal)
        v.isHidden = true
        
        return v
    }()
    
    lazy var typingLabel: UILabel = {
        let v = UILabel()
        v.font = .f10
        v.textColor = .c8E9AB0
        v.textAlignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(UILayoutPriority(999), for: .horizontal)
        v.text = "typing".innerLocalized()
        v.isHidden = true
        
        return v
    }()
    
    lazy var subStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [dotView, subLabel, typingLabel])
        v.spacing = 4
        v.alignment = .center
        
        return v
    }()
    
    func setDotHighlight(highlight: Bool) {
        dotView.backgroundColor = highlight ? .systemGreen : .systemGray
    }
    
    func showSubArea(_ show: Bool = true) {
        dotView.isHidden = !show
        subLabel.isHidden = !show
        typingLabel.isHidden = show
    }
    
    func showTyping(_ show: Bool = false) {
        dotView.isHidden = show
        subLabel.isHidden = show
        typingLabel.isHidden = !show
    }
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        let hStack = UIStackView(arrangedSubviews: [mainLabel, mainTailLabel])
        hStack.spacing = 4
        hStack.alignment = .center
        
        let vStack = UIStackView(arrangedSubviews: [hStack, subStack])
        vStack.alignment = .center
        vStack.axis = .vertical
        vStack.spacing = 6
        
        addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(5)
        }
    }
}
