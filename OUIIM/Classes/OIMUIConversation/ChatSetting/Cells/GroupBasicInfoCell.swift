
import OUICore
import ProgressHUD

class GroupBasicInfoCell: UITableViewCell {
        
    let avatarView = AvatarView()
    
    var enableInput: Bool = false {
        didSet {
            editButton.isHidden = !enableInput
            titleLabel.isUserInteractionEnabled = enableInput
        }
    }
    
    var inputHandler: (() -> Void)?
    
    lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        v.numberOfLines = 0
        v.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(titleLabelAction(_: )))
        v.addGestureRecognizer(tap)
        
        return v
    }()
    
    @objc
    private func titleLabelAction(_ sender: UILabel) {
        self.inputHandler?()
    }
    
    lazy var editButton: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        v.addTarget(self, action: #selector(editButtonAction(_:)), for: .touchUpInside)
        v.isHidden = true
        v.tintColor = .systemBlue
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        
        return v
    }()
    
    @objc
    private func editButtonAction(_ sender: UIButton) {
        self.inputHandler?()
    }
    
    lazy var subLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f14
        v.textColor = UIColor.c8E9AB0
        v.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCopyGesture(_:)))
        v.addGestureRecognizer(tapGesture)
        
        return v
    }()
    
    @objc
    private func handleCopyGesture(_ sender: UITapGestureRecognizer) {
        UIPasteboard.general.string = subLabel.text
        ProgressHUD.success("copySuccessfully".innerLocalized())
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
       
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, editButton])
        titleStack.alignment = .center
        titleStack.spacing = 8
        
        let infoStack = UIStackView(arrangedSubviews: [titleStack, subLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        
        let hStack = UIStackView(arrangedSubviews: [avatarView, infoStack, UIView()])
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: .margin16),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: .margin16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -.margin16),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -.margin16),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

