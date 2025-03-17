


























import UIKit

@available(iOSApplicationExtension, unavailable)
open class KeyboardManager: NSObject, UIGestureRecognizerDelegate {

    public typealias EventCallback = (KeyboardNotification)->Void



    open weak var inputAccessoryView: UIView?

    private(set) public var isKeyboardHidden: Bool = true


    public var shouldApplyAdditionBottomSpaceToInteractiveDismissal: Bool = false

    public var additionalInputViewBottomConstraintConstant: () -> CGFloat = { 0 }



    private var additionalBottomSpace: (() -> CGFloat)?

    private var constraints: NSLayoutConstraintSet?

    private weak var scrollView: UIScrollView?

    private var callbacks: [KeyboardEvent: EventCallback] = [:]

    private var panGesture: UIPanGestureRecognizer?


    private var cachedNotification: KeyboardNotification?

    private var justDidWillHide = false




    public convenience init(inputAccessoryView: UIView) {
        self.init()
        self.bind(inputAccessoryView: inputAccessoryView)
    }

    public override init() {
        super.init()
        addObservers()
    }

    public required init?(coder: NSCoder) { nil }


    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow(notification:)),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide(notification:)),
                                               name: UIResponder.keyboardDidHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidChangeFrame(notification:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification,
                                               object: nil)
    }







    @discardableResult
    open func on(event: KeyboardEvent, do callback: EventCallback?) -> Self {
        callbacks[event] = callback
        return self
    }


    private var bottomGap: CGFloat {
        if let inputAccessoryView = inputAccessoryView, let window = inputAccessoryView.window, let superView = inputAccessoryView.superview {
            return window.frame.height - superView.convert(superView.frame, to: window).maxY
        }
        return 0
    }






@discardableResult
open func bind(inputAccessoryView: UIView, withAdditionalBottomSpace additionalBottomSpace: (() -> CGFloat)? = .none) -> Self {

    guard let superview = inputAccessoryView.superview else {
        fatalError("`inputAccessoryView` must have a superview")
    }
    self.inputAccessoryView = inputAccessoryView
    self.additionalBottomSpace = additionalBottomSpace
    inputAccessoryView.translatesAutoresizingMaskIntoConstraints = false
    constraints = NSLayoutConstraintSet(
        bottom: inputAccessoryView.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: additionalInputViewBottomConstraintConstant()),
        left: inputAccessoryView.leftAnchor.constraint(equalTo: superview.leftAnchor),
        right: inputAccessoryView.rightAnchor.constraint(equalTo: superview.rightAnchor)
    ).activate()

    callbacks[.willShow] = { [weak self] (notification) in
        guard
            self?.isKeyboardHidden == false,
            self?.constraints?.bottom?.constant == self?.additionalInputViewBottomConstraintConstant(),
            notification.isForCurrentApp
        else { return }

        let keyboardHeight = notification.endFrame.height
        let animateAlongside = {
            self?.animateAlongside(notification) {
                self?.constraints?.bottom?.constant = min(0, -keyboardHeight + (self?.bottomGap ?? 0)) - (additionalBottomSpace?() ?? 0)
                self?.inputAccessoryView?.superview?.layoutIfNeeded()
            }
        }
        animateAlongside()

        let initialBottomGap = self?.bottomGap ?? 0
        DispatchQueue.main.async {
            let newBottomGap = self?.bottomGap ?? 0
            if newBottomGap != 0 && newBottomGap != initialBottomGap {
                animateAlongside()
            }
        }
    }
    callbacks[.willChangeFrame] = { [weak self] (notification) in
        let keyboardHeight = notification.endFrame.height
        guard
            self?.isKeyboardHidden == false,
            notification.isForCurrentApp
        else {
            return
        }
        let animateAlongside = {
            self?.animateAlongside(notification) {
                self?.constraints?.bottom?.constant = min(0, -keyboardHeight + (self?.bottomGap ?? 0)) - (additionalBottomSpace?() ?? 0)
                self?.inputAccessoryView?.superview?.layoutIfNeeded()
            }
        }
        animateAlongside()

        let initialBottomGap = self?.bottomGap ?? 0
        DispatchQueue.main.async {
            let newBottomGap = self?.bottomGap ?? 0
            if newBottomGap != 0 && newBottomGap != initialBottomGap && !(self?.justDidWillHide ?? false) {
                animateAlongside()
            }
        }
    }
    callbacks[.willHide] = { [weak self] (notification) in
        guard notification.isForCurrentApp else { return }
        self?.justDidWillHide = true
        self?.animateAlongside(notification) { [weak self] in
            self?.constraints?.bottom?.constant = self?.additionalInputViewBottomConstraintConstant() ?? 0
            self?.inputAccessoryView?.superview?.layoutIfNeeded()
        }
        DispatchQueue.main.async {
            self?.justDidWillHide = false
        }
    }
    return self
}




    @discardableResult
    open func bind(to scrollView: UIScrollView) -> Self {
        self.scrollView = scrollView
        self.scrollView?.keyboardDismissMode = .interactive // allows dismissing keyboard interactively
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer))
        recognizer.delegate = self
        self.panGesture = recognizer
        self.scrollView?.addGestureRecognizer(recognizer)
        return self
    }




    @objc
    open func keyboardDidShow(notification: NSNotification) {
        guard let keyboardNotification = KeyboardNotification(from: notification) else { return }
        callbacks[.didShow]?(keyboardNotification)
    }



    @objc
    open func keyboardDidHide(notification: NSNotification) {
        isKeyboardHidden = true
        guard let keyboardNotification = KeyboardNotification(from: notification) else { return }
        callbacks[.didHide]?(keyboardNotification)
        cachedNotification = nil
    }



    @objc
    open func keyboardDidChangeFrame(notification: NSNotification) {
        guard let keyboardNotification = KeyboardNotification(from: notification) else { return }
        callbacks[.didChangeFrame]?(keyboardNotification)
        cachedNotification = keyboardNotification
    }



    @objc
    open func keyboardWillChangeFrame(notification: NSNotification) {
        guard let keyboardNotification = KeyboardNotification(from: notification) else { return }
        callbacks[.willChangeFrame]?(keyboardNotification)
        cachedNotification = keyboardNotification
    }



    @objc
    open func keyboardWillShow(notification: NSNotification) {
        isKeyboardHidden = false
        guard let keyboardNotification = KeyboardNotification(from: notification) else { return }
        callbacks[.willShow]?(keyboardNotification)
    }



    @objc
    open func keyboardWillHide(notification: NSNotification) {
        guard let keyboardNotification = KeyboardNotification(from: notification) else { return }
        callbacks[.willHide]?(keyboardNotification)
        cachedNotification = nil
    }


    private func animateAlongside(_ notification: KeyboardNotification, animations: @escaping ()->Void) {
        UIView.animate(withDuration: notification.timeInterval, delay: 0, options: [notification.animationOptions, .allowAnimatedContent, .beginFromCurrentState], animations: animations, completion: nil)
    }





    @objc
    open func handlePanGestureRecognizer(recognizer: UIPanGestureRecognizer) {
        guard
            var keyboardNotification = cachedNotification,
            case .changed = recognizer.state,
            let view = recognizer.view,
            let window = UIApplication.shared.windows.first
        else { return }

        guard


            keyboardNotification.startFrame != keyboardNotification.endFrame,


            keyboardNotification.endFrame.width >= view.frame.width
        else {
            return
        }

        let location = recognizer.location(in: view)
        let absoluteLocation = view.convert(location, to: window)
        var frame = keyboardNotification.endFrame
        frame.origin.y = max(absoluteLocation.y, window.bounds.height - frame.height)
        frame.size.height = window.bounds.height - frame.origin.y
        keyboardNotification.endFrame = frame

        var yCoordinateDirectlyAboveKeyboard = -frame.height + bottomGap
        if shouldApplyAdditionBottomSpaceToInteractiveDismissal, let additionalBottomSpace = additionalBottomSpace {
            yCoordinateDirectlyAboveKeyboard -= additionalBottomSpace()
        }

        let aboveKeyboardAndAboveTabBar = min(additionalInputViewBottomConstraintConstant(), yCoordinateDirectlyAboveKeyboard)
        self.constraints?.bottom?.constant = aboveKeyboardAndAboveTabBar
        self.inputAccessoryView?.superview?.layoutIfNeeded()
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return scrollView?.keyboardDismissMode == .interactive
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === panGesture
    }
}
