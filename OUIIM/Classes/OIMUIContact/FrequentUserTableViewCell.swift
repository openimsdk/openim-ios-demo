
import OUICore
import SnapKit

class FrequentUserTableViewCell: UITableViewCell {
    let avatarView = AvatarView()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        return v
    }()

    let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = .c8E9AB0
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .cellBackgroundColor
        
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(CGFloat.margin16)
            make.centerY.equalToSuperview()
        }

        let textStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            v.axis = .vertical
            v.spacing = 4
            v.alignment = .leading
            return v
        }()

        contentView.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(CGFloat.margin8)
            make.centerY.equalTo(avatarView)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
