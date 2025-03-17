
import Foundation

class CellBaseController: NSObject {
    weak var delegate: ReloadDelegate?
    
    let messageID: String
    let messageType: MessageType?
    
    var longPress: ((_ sourceView: UIView, _ point: CGPoint) -> Void)?
    var onTap: ((_ data: Message.Data) -> Bool?)?
    
    private let bubbleController: BubbleController?
    
    init(messageID: String, messageType: MessageType? = nil, bubbleController: BubbleController? = nil) {
        self.messageID = messageID
        self.messageType = messageType
        self.bubbleController = bubbleController
    }
}
