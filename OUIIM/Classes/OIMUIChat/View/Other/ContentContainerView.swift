
import Foundation
import OUICore

final class ContentContainerView<ContentView: UIView>: UIView {
    
    public lazy var contentView = ContentView(frame: bounds)
    
    var onTap: (() -> Void)? {
        didSet {
            tapGestureRecognizer.isEnabled = onTap != nil
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.textColor = .systemGray2
        v.font = .f12
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        
        return v
    }()
    
    // Message sending status
    private lazy var statusIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private let blankView = UIView()
    
    private lazy var contentStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [statusIndicator, contentView])
        v.spacing = 8
        v.alignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapAction(_:)))
    
    @objc private func onTapAction(_ gesture: UIGestureRecognizer) {
        onTap?()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        
        addSubview(titleLabel)
        // WARNING: If they are added to the stackview, the name will not be fully displayed when the text is very short.
        addSubview(contentStack)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            
            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            contentStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 8),
            contentStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            contentStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        
        isUserInteractionEnabled = true
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ContentContainerView {
    
    public func showStutusIndicator(_ show: Bool = true) {
        if show {
            statusIndicator.isHiddenSafe = false
            statusIndicator.startAnimating()
        } else {
            statusIndicator.isHiddenSafe = true
        }
    }
    
    func setTitle(title: String?, messageType: MessageType) {
        titleLabel.text = title
        titleLabel.textAlignment = messageType == .outgoing ? .right : .left
        
        contentStack.removeArrangedSubview(blankView)
        
        if messageType == .outgoing {
            contentStack.insertArrangedSubview(blankView, at: 0)
        } else {
            contentStack.addArrangedSubview(blankView)
        }
    }
}
