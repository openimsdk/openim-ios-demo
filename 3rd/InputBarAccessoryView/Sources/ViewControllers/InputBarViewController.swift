


























import UIKit


open class InputBarViewController: UIViewController, InputBarAccessoryViewDelegate {

    public let inputBar = InputBarAccessoryView()






    open var isInputBarHidden: Bool = false {
        didSet {
            isInputBarHiddenDidChange()
        }
    }

    open override var inputAccessoryView: UIView? {
        return isInputBarHidden ? nil : inputBar
    }

    open override var canBecomeFirstResponder: Bool {
        return !isInputBarHidden
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        inputBar.delegate = self
    }


    open func isInputBarHiddenDidChange() {
        if isInputBarHidden, isFirstResponder {
            resignFirstResponder()
        } else if !isFirstResponder {
            becomeFirstResponder()
        }
    }

    @discardableResult
    open override func resignFirstResponder() -> Bool {
        inputBar.inputTextView.resignFirstResponder()
        return super.resignFirstResponder()
    }


    open func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) { }

    open func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) { }

    open func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) { }

    open func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) { }
}

