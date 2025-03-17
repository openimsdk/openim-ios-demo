
import UIKit

fileprivate var actionKey: Void?

extension UIBarButtonItem {
    
    var action: (() -> Void)? {
        get {
            return objc_getAssociatedObject(self, &actionKey) as? () -> Void
        }
        set {
            objc_setAssociatedObject(self, &actionKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    convenience init(title: String?, image: UIImage? = nil, action: @escaping () -> Void) {
        
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 40)
        button.setTitle(title, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)
        button.setImage(image ?? UIImage(systemName: "chevron.left"), for: .normal)
        
        self.init(customView: button)
        
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.action = action
    }
    
    @objc
    private func buttonAction() {
        self.action?()
    }
}
