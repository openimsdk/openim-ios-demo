
import Foundation
import UIKit

class SuspendTool: NSObject {
    static let sharedInstance = SuspendTool()
    private var suspendWindows: [SuspendWindow] = []
        
    var origin: CGPoint = .init(x: 10, y: 300)
    
    static func keySuspendWindow() -> SuspendWindow? {
        return SuspendTool.sharedInstance.suspendWindows.last
    }
    
    static func showSuspendWindow(rootViewController: UIViewController, coverImageName: String, tips: String?) {
        let tool = SuspendTool.sharedInstance
        let window = SuspendWindow(rootViewController: rootViewController, coverImageName: coverImageName, tips: tips, frame: CGRect(origin: tool.origin, size: CGSize(width: minSize, height: minSize)))
        tool.suspendWindows.append(window)
        window.show()
    }
    
    static func replaceSuspendWindow(rootViewController: UIViewController, coverImageName: String, tips: String?) {
        let tool = SuspendTool.sharedInstance
        tool.suspendWindows.removeAll()
        
        let window = SuspendWindow(rootViewController: rootViewController, coverImageName: coverImageName, tips: tips, frame: CGRect(origin: tool.origin, size: CGSize(width: minSize, height: minSize)))
        tool.suspendWindows.append(window)
        window.show()
    }
    
    static func remove(suspendWindow: SuspendWindow) {
        UIView.animate(withDuration: 0.25, animations: {
            suspendWindow.alpha = 0
        }) { _ in
            if let index = SuspendTool.sharedInstance.suspendWindows.firstIndex(of: suspendWindow) {
                SuspendTool.sharedInstance.suspendWindows.remove(at: index)
            }
        }
    }
    
    static func removeKey() {
        if let key = keySuspendWindow() {
            remove(suspendWindow: key)
        }
    }
    
    static func setLatestOrigin(origin: CGPoint) {
        SuspendTool.sharedInstance.origin = origin
    }
}
