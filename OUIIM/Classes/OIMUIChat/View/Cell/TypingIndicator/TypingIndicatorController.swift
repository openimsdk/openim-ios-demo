
import Foundation

final class TypingIndicatorController {
    
    private let bubbleController: BubbleController
    
    weak var view: TypingIndicator? {
        didSet {
            view?.reloadData()
        }
    }

    init(bubbleController: BubbleController) {
        self.bubbleController = bubbleController
    }
}
