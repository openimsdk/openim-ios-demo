
import Foundation

final class CustomViewController: CellBaseController {

    var text: String?
    var attributedString: NSAttributedString?
    var type: MessageType!
    var highlight: Bool = false
    var source: CustomMessageSource!

    init(source: CustomMessageSource, messageID: String, highlight: Bool = false, type: MessageType, bubbleController: BubbleController) {
        super.init(messageID: messageID, messageType: type, bubbleController: bubbleController)
        
        self.attributedString = source.attributedString
        self.highlight = highlight
        self.type = type
        self.source = source
        self.text = nil
    }
    
    func action() {
        onTap?(.custom(source))
    }
}
