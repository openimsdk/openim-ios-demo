
import UIKit

class NavigationController: UINavigationController {
    
    var interactive: NavigationInteractiveTransition?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        interactive = NavigationInteractiveTransition(self)
        self.interactivePopGestureRecognizer?.delegate = interactive
    }
    
    override var childForStatusBarStyle: UIViewController? {
        topViewController?.presentedViewController ?? topViewController
    }
}

extension NavigationController: UINavigationBarDelegate {
    func navigationBar(_ navigationBar: UINavigationBar, shouldPush item: UINavigationItem) -> Bool {
        item.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        
        return true
    }
}
