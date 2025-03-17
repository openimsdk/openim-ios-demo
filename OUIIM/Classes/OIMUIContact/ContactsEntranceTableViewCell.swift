
import OUICore

class ContactsEntranceTableViewCell: UITableViewCell {
    let avatarImageView: UIImageView = {
        let v = UIImageView()
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        
        return v
    }()

    let badgeLabel: RoundCornerLayoutLabel = {
        let v = RoundCornerLayoutLabel(roundCorners: UIRectCorner.allCorners, radius: nil)
        v.textColor = .white
        v.font = .systemFont(ofSize: 12)
        v.backgroundColor = .cFF381F
        v.text = "0"
        v.textAlignment = .center
        return v
    }()

    let arrowImageView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(nameInBundle: "contact_more_arrow")
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .tertiarySystemBackground
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.width.equalTo(avatarImageView.snp.height)
            make.left.equalTo(StandardUI.margin_22)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(avatarImageView)
            make.left.equalTo(avatarImageView.snp.right).offset(18)
        }

        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-18)
            make.centerY.equalTo(avatarImageView)
        }

        contentView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImageView.snp.left).offset(-5)
            make.centerY.equalTo(avatarImageView)
            make.width.greaterThanOrEqualTo(badgeLabel.snp.height)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
