
import Foundation

public class EventLoginSucceed: Event {
    public override init() {
        super.init()
    }
}

public class EventRecordClear: Event {
    public let conversationId: String
    public init(conversationId: String) {
        self.conversationId = conversationId
    }
}

public class EventGroupDismissed: Event {
    public let conversationId: String
    public init(conversationId: String) {
        self.conversationId = conversationId
    }
}
