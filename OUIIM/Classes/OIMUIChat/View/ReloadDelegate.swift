
import Foundation

protocol ReloadDelegate: AnyObject {

    func reloadMessage(with id: String)
    func resendMessage(messageID: String)
    func removeMessage(messageID: String, completion:(() -> Void)?)
}

extension ReloadDelegate {
    func resendMessage(_: String) {}
    func removeMessage(_: String) {}
}

protocol GestureDelegate: AnyObject {
    func onTapEdgeAligningView()

    func didTapAvatar(with user: User)
    func didTapContent(with id: String, data: Message.Data)
}

extension GestureDelegate {
    func onTapEdgeAligningView() {}

    func didTapAvatar(with _: User) {}
    func didTapContent(with _: String, _: Message.Data) {}
}
