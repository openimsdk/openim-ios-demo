
import OUICore

class SelectUserTableViewCell: FriendListUserTableViewCell {
    var canBeSelected = true {
        didSet {
            stateImageView.image = canBeSelected ? UIImage(nameInBundle: "common_checkbox_unselected") : UIImage(nameInBundle: "common_checkbox_disable_selected")
        }
    }
    
    var showSelectedIcon = true {
        didSet {
            stateImageView.isHidden = !showSelectedIcon
        }
    }

    let stateImageView: UIImageView = {
        let v = UIImageView()
        v.image = UIImage(nameInBundle: "common_checkbox_unselected")
        v.highlightedImage = UIImage(nameInBundle: "common_checkbox_selected")

        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .tertiarySystemBackground
        rowStack.insertArrangedSubview(stateImageView, at: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if !canBeSelected { return }
        super.setSelected(selected, animated: animated)
        stateImageView.isHighlighted = selected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        canBeSelected = true
    }
}
