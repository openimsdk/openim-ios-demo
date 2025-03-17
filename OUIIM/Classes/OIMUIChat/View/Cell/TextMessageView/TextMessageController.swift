
import Foundation

final class TextMessageController: CellBaseController {
    
    weak var view: TextMessageView? {
        didSet {
            view?.reloadData()
        }
    }
    
    var text: String?
    var attributedString: NSAttributedString?
    var highlight: Bool = false

    init(messageID: String, text: String? = nil, attributedString: NSAttributedString? = nil, highlight: Bool = false, type: MessageType, bubbleController: BubbleController) {
        super.init(messageID: messageID, messageType: type, bubbleController: bubbleController)
        
        self.text = text
        self.attributedString = attributedString
        self.highlight = highlight
    }
    
    func action(url: URL?) {
        if let url {
            onTap?(.url(url, isLocallyStored: false))
        } else {
            onTap?(.none)
        }
    }
}
