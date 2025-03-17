


























import Foundation
import UIKit

/**
 A UITextView that has a UILabel embedded for placeholder text
 
 ## Important Notes ##
 1. Changing the font, textAlignment or textContainerInset automatically performs the same modifications to the placeholderLabel
 2. Intended to be used in an `InputBarAccessoryView`
 3. Default placeholder text is "Aa"
 4. Will pass a pasted image it's `InputBarAccessoryView`'s `InputPlugin`s
 */
open class InputTextView: UITextView {

    
    open override var text: String! {
        didSet {
            postTextViewDidChangeNotification()
        }
    }
    
    open override var attributedText: NSAttributedString! {
        didSet {
            postTextViewDidChangeNotification()
        }
    }

    open var images: [UIImage] {
        return parseForAttachedImages()
    }
    
    open var components: [Any] {
        return parseForComponents()
    }
    
    open var isImagePasteEnabled: Bool = true

    public let placeholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        if #available(iOS 13, *) {
            label.textColor = .systemGray2
        } else {
            label.textColor = .lightGray
        }
        label.text = "Aa"
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    open var placeholder: String? = "Aa" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    open var placeholderTextColor: UIColor? = .lightGray {
        didSet {
            placeholderLabel.textColor = placeholderTextColor
        }
    }

    open var placeholderLabelInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4) {
        didSet {
            updateConstraintsForPlaceholderLabel()
        }
    }

    open override var font: UIFont! {
        didSet {
            placeholderLabel.font = font
        }
    }

    open override var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }

    open override var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderLabelInsets = textContainerInset
        }
    }
    
    open override var scrollIndicatorInsets: UIEdgeInsets {
        didSet {

            if scrollIndicatorInsets == .zero {
                scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                                     left: .leastNonzeroMagnitude,
                                                     bottom: .leastNonzeroMagnitude,
                                                     right: .leastNonzeroMagnitude)
            }
        }
    }

    open weak var inputBarAccessoryView: InputBarAccessoryView?

    private var placeholderLabelConstraintSet: NSLayoutConstraintSet?

    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    open func setup() {
        
        backgroundColor = .clear
        font = UIFont.preferredFont(forTextStyle: .body)
        isScrollEnabled = false
        scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                             left: .leastNonzeroMagnitude,
                                             bottom: .leastNonzeroMagnitude,
                                             right: .leastNonzeroMagnitude)
        setupPlaceholderLabel()
        setupObservers()
    }

    private func setupPlaceholderLabel() {

        addSubview(placeholderLabel)
        placeholderLabelConstraintSet = NSLayoutConstraintSet(
            top:     placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: placeholderLabelInsets.top),
            bottom:  placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -placeholderLabelInsets.bottom),
            left:    placeholderLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: placeholderLabelInsets.left),
            right:   placeholderLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -placeholderLabelInsets.right),
            centerX: placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerY: placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        )
        placeholderLabelConstraintSet?.centerX?.priority = .defaultLow
        placeholderLabelConstraintSet?.centerY?.priority = .defaultLow
        placeholderLabelConstraintSet?.activate()
    }


    private func setupObservers() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputTextView.redrawTextAttachments),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputTextView.textViewTextDidChange),
                                               name: UITextView.textDidChangeNotification, object: nil)
    }

    private func updateConstraintsForPlaceholderLabel() {

        placeholderLabelConstraintSet?.top?.constant = placeholderLabelInsets.top
        placeholderLabelConstraintSet?.bottom?.constant = -placeholderLabelInsets.bottom
        placeholderLabelConstraintSet?.left?.constant = placeholderLabelInsets.left
        placeholderLabelConstraintSet?.right?.constant = -placeholderLabelInsets.right
    }

    
    private func postTextViewDidChangeNotification() {
        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self)
    }
    
    @objc
    private func textViewTextDidChange() {
        let isPlaceholderHidden = !text.isEmpty
        placeholderLabel.isHidden = isPlaceholderHidden

        if isPlaceholderHidden {
            placeholderLabelConstraintSet?.deactivate()
        } else {
            placeholderLabelConstraintSet?.activate()
        }
    }

    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {

        if action == NSSelectorFromString("paste:") && UIPasteboard.general.hasImages {
            return isImagePasteEnabled
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    open override func paste(_ sender: Any?) {
        
        guard isImagePasteEnabled, let image = UIPasteboard.general.image else {
            return super.paste(sender)
        }
        for plugin in inputBarAccessoryView?.inputPlugins ?? [] {
            if plugin.handleInput(of: image) {
                return
            }
        }
        pasteImageInTextContainer(with: image)
    }



    private func pasteImageInTextContainer(with image: UIImage) {

        let attributedImageString = NSAttributedString(attachment: textAttachment(using: image))
        
        let isEmpty = attributedText.length == 0

        let newAttributedStingComponent = isEmpty ? NSMutableAttributedString(string: "") : NSMutableAttributedString(string: "\n")
        newAttributedStingComponent.append(attributedImageString)

        newAttributedStingComponent.append(NSAttributedString(string: "\n"))

        let defaultTextColor: UIColor
        if #available(iOS 13, *) {
            defaultTextColor = .label
        } else {
            defaultTextColor = .black
        }
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font ?? UIFont.preferredFont(forTextStyle: .body),
            NSAttributedString.Key.foregroundColor: textColor ?? defaultTextColor
        ]
        newAttributedStingComponent.addAttributes(attributes, range: NSRange(location: 0, length: newAttributedStingComponent.length))
        
        textStorage.beginEditing()

        textStorage.replaceCharacters(in: selectedRange, with: newAttributedStingComponent)
        textStorage.endEditing()

        let location = selectedRange.location + (isEmpty ? 2 : 3)
        selectedRange = NSRange(location: location, length: 0)

        postTextViewDidChangeNotification()
    }




    private func textAttachment(using image: UIImage) -> NSTextAttachment {
        
        guard let cgImage = image.cgImage else { return NSTextAttachment() }
        let scale = image.size.width / (frame.width - 2 * (textContainerInset.left + textContainerInset.right))
        let textAttachment = NSTextAttachment()
        textAttachment.image = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
        return textAttachment
    }



    private func parseForAttachedImages() -> [UIImage] {
        
        var images = [UIImage]()
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.attachment, in: range, options: [], using: { value, range, _ -> Void in
            
            if let attachment = value as? NSTextAttachment {
                if let image = attachment.image {
                    images.append(image)
                } else if let image = attachment.image(forBounds: attachment.bounds,
                                                       textContainer: nil,
                                                       characterIndex: range.location) {
                    images.append(image)
                }
            }
        })
        return images
    }




    private func parseForComponents() -> [Any] {
        
        var components = [Any]()
        var attachments = [(NSRange, UIImage)]()
        let length = attributedText.length
        let range = NSRange(location: 0, length: length)
        attributedText.enumerateAttribute(.attachment, in: range) { (object, range, _) in
            if let attachment = object as? NSTextAttachment {
                if let image = attachment.image {
                    attachments.append((range, image))
                } else if let image = attachment.image(forBounds: attachment.bounds,
                                                       textContainer: nil,
                                                       characterIndex: range.location) {
                    attachments.append((range,image))
                }
            }
        }
        
        var curLocation = 0
        if attachments.count == 0 {
            let text = attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                components.append(text)
            }
        }
        else {
            attachments.forEach { (attachment) in
                let (range, image) = attachment
                if curLocation < range.location {
                    let textRange = NSMakeRange(curLocation, range.location - curLocation)
                    let text = attributedText.attributedSubstring(from: textRange).string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        components.append(text)
                    }
                }
                
                curLocation = range.location + range.length
                components.append(image)
            }
            if curLocation < length - 1  {
                let text = attributedText.attributedSubstring(from: NSMakeRange(curLocation, length - curLocation)).string.trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    components.append(text)
                }
            }
        }
        
        return components
    }

    @objc
    private func redrawTextAttachments() {
        
        guard images.count > 0 else { return }
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.attachment, in: range, options: [], using: { value, _, _ -> Void in
            if let attachment = value as? NSTextAttachment, let image = attachment.image {

                let newWidth = frame.width - 2 * (textContainerInset.left + textContainerInset.right)
                let ratio = image.size.height / image.size.width
                attachment.bounds.size = CGSize(width: newWidth, height: ratio * newWidth)
            }
        })
        layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
    }
    
}

