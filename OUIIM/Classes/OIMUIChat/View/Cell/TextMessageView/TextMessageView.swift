
import ChatLayout
import Foundation
import UIKit
import OUICore
import YYText

class TextMessageView: UIView, ContainerCollectionViewCellDelegate {

    private lazy var textView: YYLabel = {
        let v = YYLabel()
        
        v.translatesAutoresizingMaskIntoConstraints = false
        v.numberOfLines = 0
        v.backgroundColor = .clear
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        v.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        v.textContainerInset = UIEdgeInsets(top: 8, left: 13, bottom: 8, right: 13)
        v.preferredMaxLayoutWidth = viewPortWidth * StandardUI.maxWidthRate

        v.textTapAction = { [weak self] view, text, subRange, rect in
            self?.controller?.action(url: nil)
        }
        return v
    }()

    var controller: TextMessageController?

    private var textViewWidthConstraint: NSLayoutConstraint?
    private var textViewHeightConstraint: NSLayoutConstraint?
    
    internal var viewPortWidth: CGFloat = 300.w

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    func setup(with controller: TextMessageController) {
        self.controller = controller
        reloadData()
    }
    
    func prepareForReuse() {
        textView.attributedText = nil
        textView.text = nil
        controller?.highlight = false
        textView.backgroundColor = .clear
    }
    
    func reloadData() {
        guard let controller else {
            return
        }
                
        var attr: NSMutableAttributedString!
        
        if let attributedString = controller.attributedString {
            attr = NSMutableAttributedString(attributedString: attributedString)
        } else {
            attr = NSMutableAttributedString(string: controller.text!)
        }
        
        attr.addAttributes([.font: UIFont.f17, .foregroundColor: UIColor.c0C1C33], range: NSMakeRange(0, attr.length))

        let pattern = #"https?://(\d{1,3}\.){3}\d{1,3}"#

        do {
            let text = attr.string
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            for match in matches {
                let range = match.range
                let value = (text as NSString).substring(with: range)
                
                attr.yy_setTextHighlight(range, color: UIColor.c0089FF, backgroundColor: nil) { view, text, subRange, rect in
                    
                    if let url = URL(string: value) {
                        controller.action(url: url)
                    }
                }
            }
        } catch {
            print("Invalid regex pattern: \(error.localizedDescription)")
        }

        attr.enumerateAttribute(.link,
                                in: NSRange(location: 0, length: attr.length),
                                options: []) { value, range, _ in
            guard let value = value as? String else { return }
            
            attr.yy_setTextHighlight(range, color: UIColor.c0089FF, backgroundColor: nil) { view, text, subRange, rect in
                
                if let url = URL(string: value) {
                    controller.action(url: url)
                }
            }
        }
        
        textView.attributedText = attr
        
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
        
        let hStack = UIStackView(arrangedSubviews: [textView])
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            hStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor)
        ])
        textViewWidthConstraint = textView.widthAnchor.constraint(lessThanOrEqualToConstant: viewPortWidth)
        textViewWidthConstraint?.isActive = true
        textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true








        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        textView.addGestureRecognizer(longPressGesture)
        
        if let gestureRecognizers = textView.gestureRecognizers {
            for gesture in gestureRecognizers {
                gesture.require(toFail: longPressGesture)
            }
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            controller?.longPress?(self, gesture.location(in: self))
        }
    }

    private func setupSize() {
        UIView.performWithoutAnimation { [self] in
            self.textViewWidthConstraint?.constant = viewPortWidth * StandardUI.maxWidthRate
            setNeedsLayout()
        }
    }
}
