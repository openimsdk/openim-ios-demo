
import UIKit

open class NavigationInteractiveTransition: NSObject {
    
    public private(set) weak var navigationController: UINavigationController?
    public let wrapped: UIGestureRecognizerDelegate?
    
    public init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.wrapped = navigationController.interactivePopGestureRecognizer?.delegate
    }
    
    open func navigationControllerShouldPop() -> Bool {
        guard let navigationController = self.navigationController else {
            return false
        }
        if navigationController.viewControllers.count <= 1 {
            return false
        }
        return true
    }
    
    open func isTouchViewInNavigationBar(_ view: UIView?) -> Bool {
        guard let navigationController = self.navigationController else {
            return false
        }
        var temp = view
        while temp != nil {
            if navigationController.navigationBar.isEqual(temp) {
                return true
            }else {
                temp = temp?.superview
            }
        }
        return false
    }
    
    open func navigationControllerShouldInterruptPopGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController = navigationController else {
            return true
        }
        guard let object = navigationController.topViewController as? InterruptNavigationControllerPopGesture else {
            return false
        }
        return object.interruptNavigationController(navigationController, PopGesture: gestureRecognizer)
    }
    
}

extension NavigationInteractiveTransition: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if navigationControllerShouldInterruptPopGesture(gestureRecognizer) {
            return false
        }
        if let result = wrapped?.gestureRecognizerShouldBegin?(gestureRecognizer) {
            return result
        }
        return true
    }
        
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if navigationControllerShouldPop() == false {
            return false
        }
        if isTouchViewInNavigationBar(touch.view) {
            return false
        }
        return true
    }
        
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let result = wrapped?.gestureRecognizer?(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) {
            return result
        }
        return true
    }
    
}
