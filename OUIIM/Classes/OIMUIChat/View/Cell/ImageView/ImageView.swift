
import ChatLayout
import Foundation
import UIKit
import OUICore
import Kingfisher

final class ImageView: UIView, ContainerCollectionViewCellDelegate {

    private lazy var stackView = UIStackView(frame: bounds)

    private lazy var imageView = UIImageView(frame: bounds)
    
    var controller: ImageController!

    private var imageWidthConstraint: NSLayoutConstraint?

    private var imageHeightConstraint: NSLayoutConstraint?

    private var viewPortWidth: CGFloat = 300.w
    
    private var imageMaxWidth = 120.0.w
    
    private static var tagBase = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func prepareForReuse() {
        imageView.image = nil
        imageView.cancelDownload()
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    func setup(with controller: ImageController) {
        self.controller = controller
        imageView.tag = controller.messageID.hash
    }

    func reloadData() {
        if controller.image != nil {
            imageView.image = controller.image
        } else {
            imageView.setImage(url: controller.source.source.url, thumbURL: controller.source.thumb?.url)
        }
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        stackView.addArrangedSubview(imageView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
        
        stackView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        stackView.addGestureRecognizer(tap)

        imageWidthConstraint = stackView.widthAnchor.constraint(equalToConstant: imageMaxWidth)
        imageWidthConstraint?.priority = UILayoutPriority(999)

        imageHeightConstraint = stackView.heightAnchor.constraint(equalToConstant: imageMaxWidth)
        imageHeightConstraint?.priority = UILayoutPriority(999)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        stackView.addGestureRecognizer(longPressGesture)
    }
    
    @objc
    private func tap() {
        controller?.action()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            controller?.longPress?(gesture.view!, gesture.location(in: gesture.view))
        }
    }

    private func setupSize() {
        var width = 0.0
        var height = 0.0
        
        if (imageMaxWidth > controller.size.width) {
            width = controller.size.width
            height = controller.size.height
        } else {
            width = imageMaxWidth;
            height = width * controller.size.height / controller.size.width;
        }
        
        imageWidthConstraint?.constant = width
        imageHeightConstraint?.constant = height
        imageWidthConstraint?.isActive = true
        imageHeightConstraint?.isActive = true

        setNeedsLayout()
    }
}
