


























import UIKit

public protocol AttachmentManagerDelegate: AnyObject {





    func attachmentManager(_ manager: AttachmentManager, shouldBecomeVisible: Bool)






    func attachmentManager(_ manager: AttachmentManager, didInsert attachment: AttachmentManager.Attachment, at index: Int)






    func attachmentManager(_ manager: AttachmentManager, didRemove attachment: AttachmentManager.Attachment, at index: Int)





    func attachmentManager(_ manager: AttachmentManager, didReloadTo attachments: [AttachmentManager.Attachment])





    func attachmentManager(_ manager: AttachmentManager, didSelectAddAttachmentAt index: Int)
}

public extension AttachmentManagerDelegate {
    
    func attachmentManager(_ manager: AttachmentManager, didInsert attachment: AttachmentManager.Attachment, at index: Int) {}
    
    func attachmentManager(_ manager: AttachmentManager, didRemove attachment: AttachmentManager.Attachment, at index: Int) {}
    
    func attachmentManager(_ manager: AttachmentManager, didReloadTo attachments: [AttachmentManager.Attachment]) {}
    
    func attachmentManager(_ manager: AttachmentManager, didSelectAddAttachmentAt index: Int) {}
}
