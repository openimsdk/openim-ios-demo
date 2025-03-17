import ChatLayout
import Foundation
import UIKit

final class TypingIndicator: UIView, StaticViewFactory {

    private lazy var imageView: UIImageView = {
        let v = UIImageView()
        v.loadGif(name: "chat_msg_typing")
        v.contentMode = .scaleAspectFit
        
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }
    
    private var controller: TypingIndicatorController!
    
    func reloadData() {
        imageView.loadGif(name: "chat_msg_typing")
    }
    
    func setup(with controller: TypingIndicatorController) {
        self.controller = controller
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
        let widthConstraint = imageView.widthAnchor.constraint(equalToConstant: 60)
        widthConstraint.priority = UILayoutPriority(rawValue: 999)
        widthConstraint.isActive = true
        
        let heightConstraint = imageView.heightAnchor.constraint(equalToConstant: 35)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true
    }
}
