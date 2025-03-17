
import OUICore

open class FriendListUserTableViewCell: UITableViewCell {
    public let avatarImageView: AvatarView = {
        let v = AvatarView()
        return v
    }()

    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        
        return v
    }()

    public let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        v.textColor = .c8E9AB0
        return v
    }()
    
    public let trainingLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = .c0C1C33
        v.layer.masksToBounds = true
        return v
    }()
    
    public let rowStack: UIStackView = {
        let v = UIStackView();
        v.spacing = 8
        v.alignment = .center
        v.distribution = .fill
        
        return v
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .cellBackgroundColor
        
        let textStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            v.axis = .vertical
            v.spacing = 4
            v.alignment = .leading
            return v
        }()
        
        trainingLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        rowStack.addArrangedSubview(avatarImageView)
        rowStack.addArrangedSubview(textStack)
        rowStack.addArrangedSubview(trainingLabel)
        rowStack.alignment = .center
        
        contentView.addSubview(rowStack)
        
        rowStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8.h)
            make.leading.trailing.equalToSuperview().inset(16)
        }
    }

    @available(*, unavailable)
    required public init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
    
    private func reset() {
        titleLabel.text = nil
        titleLabel.attributedText = nil
        subtitleLabel.text = nil
        trainingLabel.text = nil
        trainingLabel.attributedText = nil
        avatarImageView.setAvatar(url: nil, text: nil, onTap: nil)
        
        titleLabel.textColor = .c0C1C33
        subtitleLabel.textColor = .c0C1C33
        trainingLabel.textColor = .c0C1C33
    }
}
