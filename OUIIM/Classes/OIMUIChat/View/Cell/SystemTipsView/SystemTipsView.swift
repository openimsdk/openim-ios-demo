
import ChatLayout
import Foundation
import UIKit
import OUICore
import YYText

class SystemTipsView: UIView, StaticViewFactory, ContainerCollectionViewCellDelegate {
    
    private lazy var textView: YYLabel = {
        let v = YYLabel()
        
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(UILayoutPriority(999), for: .horizontal)
        
        v.numberOfLines = 0
        v.backgroundColor = .clear
        v.textContainerInset = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        v.textAlignment = .center
        v.textColor = .c8E9AB0
        v.font = .f12
        v.layer.cornerRadius = 4
        v.preferredMaxLayoutWidth = viewPortWidth
        v.isUserInteractionEnabled = true
        
        return v
    }()
    
    private var controller: SystemTipsViewController?
    
    private var viewPortWidth: CGFloat = 300.w
    
    private var contentWidthConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }
    
    func apply(_ layoutAttributes: ChatLayoutAttributes) {
        setupSize()
    }
    
    func setup(with controller: SystemTipsViewController) {
        self.controller = controller
        reloadData()
    }
    
    func prepareForReuse() {
        textView.attributedText = nil
        textView.text = nil
    }
    
    func reloadData() {
        guard let controller else { return }
        
        textView.backgroundColor = controller.enableBackgroundColor ? .cF4F5F7 : .clear
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        if controller.text != nil {
            textView.textColor = .c8E9AB0
            textView.font = .f12
            textView.preferredMaxLayoutWidth = CGFloat((controller.text?.count ?? 0) * 10)
                                                       
            textView.text = controller.text
        } else {
            textView.preferredMaxLayoutWidth = viewPortWidth
            
            let attr = NSMutableAttributedString(attributedString: controller.attributedString!)
            attr.addAttributes([.font: UIFont.f12,
                                .paragraphStyle: paragraphStyle],
                               range: NSMakeRange(0, attr.length))
            
            attr.enumerateAttribute(.link,
                                    in: NSRange(location: 0, length: attr.length),
                                    options: []) { value, range, _ in
                guard let value = value as? String else { return }
                attr.yy_setTextHighlight(range, color: UIColor.c0089FF, backgroundColor: nil) { view, text, subRange, rect in
                    if (value.hasPrefix(linkSchme) ||
                        value.hasPrefix(sendFriendReqSchme)),
                        let url = URL(string: value) {
                        
                        controller.action(url: url)
                    }
                }
            }
            
            textView.attributedText = attr
        }
    }
    
    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        
        let spacer1 = UIView()
        spacer1.translatesAutoresizingMaskIntoConstraints = false
        
        let spacer2 = UIView()
        spacer2.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [spacer1, textView, spacer2])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        
        addSubview(stack)
        NSLayoutConstraint.activate([
            spacer1.widthAnchor.constraint(equalTo: spacer2.widthAnchor, multiplier: 1),
            stack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
        
        contentWidthConstraint = stack.widthAnchor.constraint(equalToConstant: viewPortWidth)
        contentWidthConstraint?.priority = UILayoutPriority(999)
    }
    
    private func setupSize() {
        UIView.performWithoutAnimation { [self] in
            self.contentWidthConstraint?.constant = self.viewPortWidth
            self.contentWidthConstraint?.isActive = true
        }
    }
}
