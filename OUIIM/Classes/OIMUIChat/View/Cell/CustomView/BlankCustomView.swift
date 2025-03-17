
import ChatLayout
import Foundation
import UIKit
import OUICore
import YYText

final class BlankCustomView: UIView, ContainerCollectionViewCellDelegate {

    private var viewPortWidth: CGFloat = 260.w

    private lazy var textView: YYLabel = {
        let v = YYLabel()
        
        v.translatesAutoresizingMaskIntoConstraints = false
        v.numberOfLines = 0
        v.backgroundColor = .clear
        v.font = .f17
        v.textColor = .c0C1C33
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        v.textContainerInset = UIEdgeInsets(top: 8, left: 13, bottom: 8, right: 13)
        v.preferredMaxLayoutWidth = viewPortWidth * StandardUI.maxWidthRate
        v.isUserInteractionEnabled = true
        v.textLongPressAction = { [weak self] view, text, subRange, rect in
            self?.controller?.longPress?(view, rect.origin)
        }
        
        return v
    }()
    
    private lazy var contentView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = StandardUI.cornerRadius
        v.layer.borderColor = UIColor.cE8EAEF.cgColor
        v.layer.borderWidth = 1
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .cellBackgroundColor
        v.addSubview(textView)
        v.isUserInteractionEnabled = true
        
        return v
    }()
    
    var controller: CustomViewController?

    private var textViewWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func prepareForReuse() {
        textView.resignFirstResponder()
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        setupSize()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
    }

    func setup(with controller: CustomViewController) {
        self.controller = controller
        reloadData()
    }

    func reloadData() {
        guard let controller else {
            return
        }
        if controller.text != nil {
            textView.text = controller.text
        } else {
            textView.attributedText = controller.attributedString
        }
        
        if controller.highlight {
            UIView.animate(withDuration: 1, animations: { [self] in
                self.textView.backgroundColor = .systemRed
            }) { _ in
                UIView.animate(withDuration: 1) { [self] in
                    self.textView.backgroundColor = .clear
                }
            }
        }
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textView.topAnchor.constraint(equalTo: contentView.topAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        textViewWidthConstraint = textView.widthAnchor.constraint(equalToConstant: viewPortWidth)
        textViewWidthConstraint?.isActive = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        contentView.addGestureRecognizer(tap)




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
        UIView.performWithoutAnimation {
            self.textViewWidthConstraint?.constant = viewPortWidth * StandardUI.maxWidthRate
            setNeedsLayout()
        }
    }

}

extension BlankCustomView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) ||
            NSStringFromClass(type(of: otherGestureRecognizer)) == "UITextTapRecognizer" {
            
            return false
        }
        
        return true
    }
}
