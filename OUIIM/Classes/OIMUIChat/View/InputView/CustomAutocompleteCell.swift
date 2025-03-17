import InputBarAccessoryView
import OUICore

class CustomAutocompleteCell: UITableViewCell {
    
    public let avatarView: AvatarView = {
        let v = AvatarView()
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()

    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 16)

        return v
    }()
    
    class var reuseIdentifier: String {
        return "CustomAutocompleteCell"
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        
        let stack = UIStackView(arrangedSubviews: [avatarView, titleLabel])
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}
