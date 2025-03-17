
import Foundation
import UIKit

final class AvatarViewController {
    var name: String?
    var faceURL: String?
    var isGif: Bool = false
        
    var onTap: ((_ userID: String) -> Void)?
    
    private let user: User

    private let bubble: Cell.BubbleType

    weak var view: ChatAvatarView? {
        didSet {
            view?.reloadData()
        }
    }

    init(user: User, bubble: Cell.BubbleType) {
        self.user = user
        self.bubble = bubble
        self.name = user.name
        self.isGif = user.faceURL?.split(separator: ".").last?.lowercased() == "gif"
        self.faceURL = isGif ? user.faceURL : user.faceURL?.customThumbnailURLString()
    }
    
    func action() {
        onTap?(user.id)
    }
}
