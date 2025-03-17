


























import UIKit

/**
 A InputItem that inherits from UIButton
 
 ## Important Notes ##
 1. Intended to be used in an `InputStackView`
 */
open class InputBarButtonItem: UIButton, InputItem {





    public enum Spacing {
        case fixed(CGFloat)
        case flexible
        case none
    }
    
    public typealias InputBarButtonItemAction = ((InputBarButtonItem) -> Void)


    open weak var inputBarAccessoryView: InputBarAccessoryView?


    open var spacing: Spacing = .none {
        didSet {
            switch spacing {
            case .flexible:
                setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
            case .fixed:
                setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
            case .none:
                setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
            }
        }
    }

    private var size: CGSize? = CGSize(width: 20, height: 20) {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        var contentSize = size ?? super.intrinsicContentSize
        switch spacing {
        case .fixed(let width):
            contentSize.width += width
        case .flexible, .none:
            break
        }
        return contentSize
    }

    open var parentStackViewPosition: InputStackView.Position?

    open var title: String? {
        get {
            return title(for: .normal)
        }
        set {
            setTitle(newValue, for: .normal)
        }
    }

    open var image: UIImage? {
        get {
            return image(for: .normal)
        }
        set {
            setImage(newValue, for: .normal)
        }
    }

    open override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            guard newValue != isHighlighted else { return }
            super.isHighlighted = newValue
            if newValue {
                onSelectedAction?(self)
            } else {
                onDeselectedAction?(self)
            }

        }
    }

    open override var isEnabled: Bool {
        didSet {
            if isEnabled {
                onEnabledAction?(self)
            } else {
                onDisabledAction?(self)
            }
        }
    }

    
    private var onTouchUpInsideAction: InputBarButtonItemAction?
    private var onKeyboardEditingBeginsAction: InputBarButtonItemAction?
    private var onKeyboardEditingEndsAction: InputBarButtonItemAction?
    private var onKeyboardSwipeGestureAction: ((InputBarButtonItem, UISwipeGestureRecognizer) -> Void)?
    private var onTextViewDidChangeAction: ((InputBarButtonItem, InputTextView) -> Void)?
    private var onSelectedAction: InputBarButtonItemAction?
    private var onDeselectedAction: InputBarButtonItemAction?
    private var onEnabledAction: InputBarButtonItemAction?
    private var onDisabledAction: InputBarButtonItemAction?

    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }


    open func setup() {
        contentVerticalAlignment = .center
        contentHorizontalAlignment = .center
        imageView?.contentMode = .scaleAspectFit
        setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .vertical)
        setTitleColor(.systemBlue, for: .normal)
        setTitleColor(UIColor.systemBlue.withAlphaComponent(0.3), for: .highlighted)
        if #available(iOS 13, *) {
            setTitleColor(.systemGray2, for: .disabled)
        } else {
            setTitleColor(.lightGray, for: .disabled)
        }
        adjustsImageWhenHighlighted = false
        addTarget(self, action: #selector(InputBarButtonItem.touchUpInsideAction), for: .touchUpInside)
    }








    open func setSize(_ newValue: CGSize?, animated: Bool) {
        size = newValue
        if animated, let position = parentStackViewPosition {
            inputBarAccessoryView?.performLayout(animated) { [weak self] in
                self?.inputBarAccessoryView?.layoutStackViews([position])
            }
        }
    }





    @discardableResult
    open func configure(_ item: InputBarButtonItemAction) -> Self {
        item(self)
        return self
    }




    @discardableResult
    open func onKeyboardEditingBegins(_ action: @escaping InputBarButtonItemAction) -> Self {
        onKeyboardEditingBeginsAction = action
        return self
    }




    @discardableResult
    open func onKeyboardEditingEnds(_ action: @escaping InputBarButtonItemAction) -> Self {
        onKeyboardEditingEndsAction = action
        return self
    }




    @discardableResult
    open func onKeyboardSwipeGesture(_ action: @escaping (_ item: InputBarButtonItem, _ gesture: UISwipeGestureRecognizer) -> Void) -> Self {
        onKeyboardSwipeGestureAction = action
        return self
    }




    @discardableResult
    open func onTextViewDidChange(_ action: @escaping (_ item: InputBarButtonItem, _ textView: InputTextView) -> Void) -> Self {
        onTextViewDidChangeAction = action
        return self
    }




    @discardableResult
    open func onTouchUpInside(_ action: @escaping InputBarButtonItemAction) -> Self {
        onTouchUpInsideAction = action
        return self
    }




    @discardableResult
    open func onSelected(_ action: @escaping InputBarButtonItemAction) -> Self {
        onSelectedAction = action
        return self
    }




    @discardableResult
    open func onDeselected(_ action: @escaping InputBarButtonItemAction) -> Self {
        onDeselectedAction = action
        return self
    }




    @discardableResult
    open func onEnabled(_ action: @escaping InputBarButtonItemAction) -> Self {
        onEnabledAction = action
        return self
    }




    @discardableResult
    open func onDisabled(_ action: @escaping InputBarButtonItemAction) -> Self {
        onDisabledAction = action
        return self
    }




    open func textViewDidChangeAction(with textView: InputTextView) {
        onTextViewDidChangeAction?(self, textView)
    }



    open func keyboardSwipeGestureAction(with gesture: UISwipeGestureRecognizer) {
        onKeyboardSwipeGestureAction?(self, gesture)
    }

    open func keyboardEditingEndsAction() {
        onKeyboardEditingEndsAction?(self)
    }

    open func keyboardEditingBeginsAction() {
        onKeyboardEditingBeginsAction?(self)
    }

    @objc
    open func touchUpInsideAction() {
        onTouchUpInsideAction?(self)
    }


    public static var flexibleSpace: InputBarButtonItem {
        let item = InputBarButtonItem()
        item.setSize(.zero, animated: false)
        item.spacing = .flexible
        return item
    }

    public static func fixedSpace(_ width: CGFloat) -> InputBarButtonItem {
        let item = InputBarButtonItem()
        item.setSize(.zero, animated: false)
        item.spacing = .fixed(width)
        return item
    }
}
