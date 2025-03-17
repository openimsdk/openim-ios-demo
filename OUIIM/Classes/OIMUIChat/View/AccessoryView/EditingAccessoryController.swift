
import Foundation
import UIKit

final class EditingAccessoryController {

    weak var delegate: EditingAccessoryControllerDelegate?

    weak var view: EditingAccessoryView?

    private let messageId: String

    init(messageId: String) {
        self.messageId = messageId
    }

    func selectedMessageAction() {
        delegate?.selecteMessage(with: messageId)
    }
}
