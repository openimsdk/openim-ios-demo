


























import Foundation

public struct AutocompleteCompletion {

    public let text: String

    public let context: [String: Any]?
    
    public init(text: String, context: [String: Any]? = nil) {
        self.text = text
        self.context = context
    }
    
    @available(*, deprecated, message: "`displayText` should no longer be used, use `context: [String: Any]` instead")
    public init(_ text: String, displayText: String) {
        self.text = text
        self.context = nil
    }
}
