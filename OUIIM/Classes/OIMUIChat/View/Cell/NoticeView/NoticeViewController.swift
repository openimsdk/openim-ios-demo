
import Foundation

final class NoticeViewController: CellBaseController {

    weak var view: NoticeView? {
        didSet {
            view?.reloadData()
        }
    }
    
    var text: String?

    init(text: String? = nil, bubbleController: BubbleController) {
        super.init(messageID: "", bubbleController: bubbleController)
        
        self.text = text
    }
    
    func action() {
    }
}
