
import Foundation

protocol EditingAccessoryControllerDelegate: AnyObject {

    func selecteMessage(with id: String)
}

extension EditingAccessoryControllerDelegate {
    func selecteMessage(with _: String) {}
}
