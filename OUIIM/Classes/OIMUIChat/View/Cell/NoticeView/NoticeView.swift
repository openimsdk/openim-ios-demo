
import ChatLayout
import Foundation
import UIKit
import OUICore

final class NoticeView: UIView, ContainerCollectionViewCellDelegate {

    private var viewPortWidth: CGFloat = 300.w

    private lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 2
        v.font = .f17
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        
        let image = UIImage(nameInBundle: "chat_msg_notice_speaker_icon")
        let attachment = NSTextAttachment(image: image!)
        attachment.bounds = CGRect(x: 0, y: -6, width: 24, height: 24)
        let base = NSMutableAttributedString(attachment: attachment)
        base.append(NSAttributedString(string: " 群公告".innerLocalized(), attributes: [.foregroundColor: UIColor.systemBlue]))
        v.attributedText = base
        
        return v
    }()
    
    private lazy var textView = MessageTextView()

    private var controller: NoticeViewController?

    private var textViewWidthConstraint: NSLayoutConstraint?
    private var textViewHeightConstraint: NSLayoutConstraint?
    
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
        viewPortWidth = layoutAttributes.layoutFrame.width
        setupSize()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
    }

    func setup(with controller: NoticeViewController) {
        self.controller = controller
        reloadData()
    }

    func reloadData() {
        guard let controller else {
            return
        }

        textView.text = controller.text

        UIView.performWithoutAnimation {
            if #available(iOS 13.0, *) {
                textView.linkTextAttributes = [.foregroundColor: UIColor.systemBlue,
                                               .underlineStyle: 1]
            } else {
                textView.linkTextAttributes = [.foregroundColor: UIColor.systemBlue,
                                               .underlineStyle: 1]
            }
        }
    }

    private func setupSubviews() {
        layoutMargins = .zero
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false

        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.spellCheckingType = .no
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = .all
        textView.font = .f17
        textView.scrollsToTop = false
        textView.bounces = false
        textView.bouncesZoom = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isExclusiveTouch = true
        
        let contentView = UIView()
        contentView.layer.cornerRadius = StandardUI.cornerRadius
        contentView.layer.borderColor = UIColor.cE8EAEF.cgColor
        contentView.layer.borderWidth = 1
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .cellBackgroundColor
        
        addSubview(contentView)
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, textView])
        vStack.spacing = 8
        vStack.axis = .vertical
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.isUserInteractionEnabled = false
        
        contentView.addSubview(vStack)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            
            vStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            vStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
        textViewWidthConstraint = textView.widthAnchor.constraint(equalToConstant: viewPortWidth)
        textViewWidthConstraint?.priority = UILayoutPriority(999)
        
        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 50)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        contentView.isUserInteractionEnabled = true
        contentView.addGestureRecognizer(tap)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        contentView.addGestureRecognizer(longPressGesture)
    }

    private func setupSize() {
        UIView.performWithoutAnimation { [self] in
            self.textViewWidthConstraint?.constant = viewPortWidth * StandardUI.maxWidthRate
            self.textViewWidthConstraint?.isActive = true
            self.textViewHeightConstraint?.isActive = true
            setNeedsLayout()
        }
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
}

private final class MessageTextView: UITextView {

    override var isFocused: Bool {
        false
    }

    override var canBecomeFirstResponder: Bool {
        false
    }

    override var canBecomeFocused: Bool {
        false
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        false
    }

}
