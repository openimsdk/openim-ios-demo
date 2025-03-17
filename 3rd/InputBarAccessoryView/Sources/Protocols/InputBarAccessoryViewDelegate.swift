


























import Foundation
import UIKit

public protocol InputBarAccessoryViewDelegate: AnyObject {





    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String)






    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize)






    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String)





    func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer)
}

public extension InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {}
    
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {}
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {}
    
    func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) {}
}
