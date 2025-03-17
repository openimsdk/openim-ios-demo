import Foundation
import UIKit

public enum ActionDuration {

    case notAnimated
    case animated(duration: TimeInterval)

}

public protocol EditNotifierDelegate: AnyObject {

    func setIsEditing(_ isEditing: Bool, duration: ActionDuration)

}

public extension EditNotifierDelegate {

    func setIsEditing(_ isEditing: Bool, duration: ActionDuration) {}

}
