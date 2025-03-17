
import Foundation

final class SystemTipsViewController: CellBaseController {
    
    var text: String?
    
    var attributedString: NSAttributedString?
    
    var enableBackgroundColor: Bool = false

    init(text: String? = nil, attributedString: NSAttributedString? = nil, enableBackgroundColor: Bool = false) {
        super.init(messageID: "")
        
        self.text = text
        self.attributedString = attributedString
        self.enableBackgroundColor = enableBackgroundColor
    }
    
    func action(url: URL) {
        onTap?(.url(url, isLocallyStored: false))
    }
}
