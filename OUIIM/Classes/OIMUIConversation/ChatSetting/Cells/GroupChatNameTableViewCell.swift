
import RxSwift
import OUICore

class GroupChatNameTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()
    
    let avatarImageView = AvatarView()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        
        return v
    }()
    
    lazy var nameTextFiled: UITextField = {
        let v = UITextField()
        v.placeholder = "plsEnterGroupNameHint".innerLocalized()
        v.rx.text.map({ [weak self] text in
            guard let self, let text else { return "" }
            
            return String(text.prefix(16))
        }).bind(to: v.rx.text).disposed(by: disposeBag)
        
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.left.equalToSuperview().offset(StandardUI.margin_22)
            make.top.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20).priority(.low)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarImageView.snp.right).offset(20)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        
        contentView.insertSubview(nameTextFiled, belowSubview: titleLabel)
        nameTextFiled.snp.makeConstraints { make in
            make.edges.equalTo(titleLabel)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        nameTextFiled.isHidden = true
    }
    
    var enableInput: Bool = false {
        didSet {
            titleLabel.isHidden = enableInput
            nameTextFiled.isHidden = !enableInput
        }
    }
}
