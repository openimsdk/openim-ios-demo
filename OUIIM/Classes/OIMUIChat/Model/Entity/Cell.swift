
import ChatLayout
import DifferenceKit
import Foundation
import UIKit

enum Cell: Hashable {

    enum BubbleType {
        case normal
        case tailed
    }

    case message(Message, bubbleType: BubbleType)
    
    case systemMessage(SystemGroup)

    case typingIndicator

    case messageGroup(MessageGroup)

    case date(DateGroup)


    var alignment: ChatItemAlignment {
        switch self {
        case let .message(message, _):
            return message.type == .incoming ? .leading : .trailing


        case .typingIndicator:
            return .leading
        case let .messageGroup(group):
            return group.type == .incoming ? .leading : .trailing
        case .date:
            return .center
        case .systemMessage(_):
            return .center
        }
    }

}

extension Cell: Differentiable {

    public var differenceIdentifier: Int {
        switch self {
        case let .message(message, _):
            return message.differenceIdentifier


        case .typingIndicator:
            return hashValue
        case let .messageGroup(group):
            return group.differenceIdentifier
        case let .date(group):
            return group.differenceIdentifier
        case let .systemMessage(message):
            return message.differenceIdentifier
        }
    }

    public func isContentEqual(to source: Cell) -> Bool {
        if case .message(let msg, _) = self, case .message(let sourceMsg, _) = source {
            return msg.isContentEqual(to: sourceMsg)
        }
        
        return self == source
    }

}
