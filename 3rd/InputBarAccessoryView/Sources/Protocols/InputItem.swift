


























import UIKit

public protocol InputItem: AnyObject {

    var inputBarAccessoryView: InputBarAccessoryView? { get set }

    var parentStackViewPosition: InputStackView.Position? { get set }

    func textViewDidChangeAction(with textView: InputTextView)

    func keyboardSwipeGestureAction(with gesture: UISwipeGestureRecognizer)

    func keyboardEditingEndsAction()

    func keyboardEditingBeginsAction()
}
