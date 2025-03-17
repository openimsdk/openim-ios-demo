import Foundation
import UIKit

final class ImageController: CellBaseController {

    weak var view: ImageView? {
        didSet {
            view?.reloadData()
        }
    }

    var size: CGSize = CGSize(width: 120, height: 120)
    var image: UIImage?
    var source: MediaMessageSource! = nil

    init(source: MediaMessageSource, messageID: String, bubbleController: BubbleController) {
        super.init(messageID: messageID, bubbleController: bubbleController)
        
        self.source = source
        
        if let size = source.thumb?.size {
            self.size = size
        }
        
        loadImage()
    }
    
    private func loadImage() {
        if let image = source.image {
            self.image = image
            view?.reloadData()
        }
    }

    func action() {
        onTap?(.image(source, isLocallyStored: true))
    }
}
