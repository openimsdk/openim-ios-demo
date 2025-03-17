import Foundation
import UIKit
import OUICore

public struct ChatViewControllerBuilder {

    public func build(_ conversation: ConversationInfo, anchorMessage: MessageInfo? = nil, hiddenInputBar: Bool = false) -> UIViewController {
        let dataProvider = DefaultDataProvider(conversation: conversation, anchorMessage: anchorMessage)
        let messageController = DefaultChatController(dataProvider: dataProvider,
                                                      senderID: IMController.shared.uid,
                                                      conversation: conversation)
        dataProvider.delegate = messageController
        
        let editNotifier = EditNotifier()
        let swipeNotifier = SwipeNotifier()
        let extractedExpr = DefaultChatCollectionDataSource(editNotifier: editNotifier,
                                                            swipeNotifier: swipeNotifier,
                                                            reloadDelegate: messageController,
                                                            editingDelegate: messageController)
        let dataSource = extractedExpr

        
        let messageViewController = ChatViewController(chatController: messageController,
                                                       dataSource: dataSource,
                                                       editNotifier: editNotifier,
                                                       swipeNotifier: swipeNotifier,
                                                       hiddenInputBar: hiddenInputBar,
                                                       scrollToTop: anchorMessage != nil)
        messageController.delegate = messageViewController
        dataSource.gestureDelegate = messageViewController
        
        return messageViewController
    }
    
    public init() {
    }
}
