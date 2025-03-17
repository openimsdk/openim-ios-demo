


























import Foundation
import UIKit

public protocol AttachmentManagerDataSource: AnyObject {







    func attachmentManager(_ manager: AttachmentManager, cellFor attachment: AttachmentManager.Attachment, at index: Int) -> AttachmentCell







    func attachmentManager(_ manager: AttachmentManager, sizeFor attachment: AttachmentManager.Attachment, at index: Int) -> CGSize?
}

public extension AttachmentManagerDataSource{

    func attachmentManager(_ manager: AttachmentManager, sizeFor attachment: AttachmentManager.Attachment, at index: Int) -> CGSize? {
        return nil
    }
}
