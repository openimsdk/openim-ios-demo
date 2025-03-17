


























import UIKit

public struct KeyboardNotification {


    public let event: KeyboardEvent

    public let timeInterval: TimeInterval

    public let animationOptions: UIView.AnimationOptions

    public let isForCurrentApp: Bool

    public var startFrame: CGRect

    public var endFrame: CGRect



    public init?(from notification: NSNotification) {
        guard notification.event != .unknown else { return nil }
        self.event = notification.event
        self.timeInterval = notification.timeInterval ?? 0.25
        self.animationOptions = notification.animationOptions
        self.isForCurrentApp = notification.isForCurrentApp ?? true
        self.startFrame = notification.startFrame ?? .zero
        self.endFrame = notification.endFrame ?? .zero
    }
    
}
