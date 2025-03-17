
import ChatLayout
import Foundation
import UIKit
import OUICore

final class MainContainerView<LeadingAccessory: StaticViewFactory, CustomView: UIView, TrailingAccessory: StaticViewFactory>: UIView, SwipeNotifierDelegate  {

    var swipeCompletionRate: CGFloat = 0 {
        didSet {
            updateOffsets()
        }
    }
    
    var avatarView: LeadingAccessory.View? {
        containerView.leadingView
    }

    var maskedView: BezierMaskedView<CustomView> {
        containerView.customView.contentView
    }



    
    var rightAvatarView: TrailingAccessory.View? {
        containerView.trailingView
    }
    
    var contentContainer: ContentContainerView<BezierMaskedView<CustomView>> {
        containerView.customView
    }

    weak var accessoryConnectingView: UIView? {
        didSet {
            guard accessoryConnectingView != oldValue else {
                return
            }
            updateAccessoryView()
        }
    }

    var accessoryView = DateAccessoryView()

    var accessorySafeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            guard accessorySafeAreaInsets != oldValue else {
                return
            }
            accessoryOffsetConstraint?.constant = accessorySafeAreaInsets.right
            setNeedsLayout()
            updateOffsets()
        }
    }

    private(set) lazy var containerView = CellLayoutContainerView<LeadingAccessory, ContentContainerView<BezierMaskedView<CustomView>>, TrailingAccessory>()

    private weak var accessoryOffsetConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        layoutMargins = .zero
        clipsToBounds = false
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
        
        accessoryView.translatesAutoresizingMaskIntoConstraints = false

        updateOffsets()
    }

    private func updateAccessoryView() {
        accessoryView.removeFromSuperview()
        guard let avatarConnectingView = accessoryConnectingView,
              let avatarConnectingSuperview = avatarConnectingView.superview else {
            return
        }
        avatarConnectingSuperview.addSubview(accessoryView)
        accessoryOffsetConstraint = accessoryView.leadingAnchor.constraint(equalTo: avatarConnectingView.trailingAnchor, constant: accessorySafeAreaInsets.right)
        accessoryOffsetConstraint?.isActive = true
        accessoryView.centerYAnchor.constraint(equalTo: avatarConnectingView.centerYAnchor).isActive = true
    }

    private func updateOffsets() {
        if let avatarView,
           !avatarView.isHidden {
            avatarView.transform = CGAffineTransform(translationX: -((avatarView.bounds.width + accessorySafeAreaInsets.left) * swipeCompletionRate), y: 0)
        }
        switch containerView.customView.contentView.messageType {
        case .incoming:
            maskedView.transform = .identity
            maskedView.transform = CGAffineTransform(translationX: -(maskedView.frame.origin.x * swipeCompletionRate), y: 0)
        case .outgoing:
            let maxOffset = min(frame.origin.x, accessoryView.frame.width)
            maskedView.transform = .identity
            maskedView.transform = CGAffineTransform(translationX: -(maxOffset * swipeCompletionRate), y: 0)
            
            if let rightAvatarView,
               !rightAvatarView.isHidden {
                rightAvatarView.transform = CGAffineTransform(translationX: -(maxOffset * swipeCompletionRate), y: 0)
            }
        }

        accessoryView.transform = CGAffineTransform(translationX: -((accessoryView.bounds.width + accessorySafeAreaInsets.right) * swipeCompletionRate), y: 0)
    }
}
