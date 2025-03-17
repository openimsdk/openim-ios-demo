
import AVFoundation
import Foundation
import UIKit

extension UIViewController {
    public static var scale: ((_ scale: Bool) -> Void)?
    
    public func suspend(coverImageName: String, tips: String?) {
        Self.scale?(true)
        self.view.layer.masksToBounds = true
        UIView.animate(withDuration: 0.25, animations: {
            self.view.frame = CGRect(origin: SuspendTool.sharedInstance.origin, size: CGSize(width: minSize, height: minSize))
            self.view.layoutIfNeeded()
        }) { _ in
            UIViewController.currentViewController().dismiss(animated: false)
            
            SuspendTool.replaceSuspendWindow(rootViewController: self, coverImageName: coverImageName, tips: tips)
        }
    }
    
    public func updateSuspendTips(text: String) {
        SuspendTool.keySuspendWindow()?.tipsLabel.text = text
    }
    
    public func removeMiniWindow() {
        SuspendTool.removeKey()
    }
    
    func spread(from point: CGPoint) {
        if UIViewController.currentViewController().presentedViewController == self {
            return
        }
        
        Self.scale?(false)
        
        self.view.frame = CGRect(origin: point, size: CGSize(width: minSize, height: minSize))
        modalPresentationStyle = .overCurrentContext
        UIViewController.currentViewController().present(self, animated: false)
        
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layer.cornerRadius = 0
            self.view.frame = UIScreen.main.bounds
            self.view.layoutIfNeeded()
        })
    }
    
    public static func currentViewController() -> UIViewController {
        var rootViewController: UIViewController?
        var keyWindow = UIApplication.shared.windows.first
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            keyWindow = windowScene.windows.first(where: { !($0 is SuspendWindow) })
        }
        keyWindow?.becomeFirstResponder()
        rootViewController = keyWindow?.rootViewController
        
        var viewController = rootViewController
        if viewController?.presentedViewController != nil {
            viewController = viewController!.presentedViewController
        }
        return viewController!
    }
}
