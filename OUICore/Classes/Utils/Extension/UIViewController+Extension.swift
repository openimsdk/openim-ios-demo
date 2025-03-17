import ProgressHUD

extension UIViewController {
    public func presentAlert(useRoot: Bool = true,
                             title: String? = nil,
                             confirmTitle: String? = "determine".innerLocalized(),
                             cancelTitle: String? = "cancel".innerLocalized(),
                             confirmHandler: (() -> Void)? = nil) {
        let alertController = AlertViewController(message: title, preferredStyle: .alert)
        
        if let cancelTitle {
            let cancelAction = AlertAction(title: cancelTitle, style: .cancel)
            
            alertController.addAction(cancelAction)
        }
        
        if let confirmHandler {
            alertController.addAction(AlertAction(title: confirmTitle, style: .default, handler: { [weak self] _ in
                confirmHandler()
            }))
        }
        
        if useRoot, let root = Self.getRootController() {
            root.present(alertController, animated: true)
        } else {
            currentViewController()!.present(alertController, animated: true)
        }
    }
    
    public func presentActionSheet(useRoot: Bool = true,
                                   title: String? = nil,
                                   action1Title: String,
                                   action1Handler: (() -> Void)?,
                                   action2Title: String? = nil,
                                   action2Handler: (() -> Void)? = nil) {
        let alertController = AlertViewController(message: title, preferredStyle: .actionSheet)
        
        let action1 = AlertAction(title: action1Title, style: .default, handler: { _ in
            action1Handler?()
        })
        
        alertController.addAction(action1)
        
        if let action2Title {
            let action2 = AlertAction(title: action2Title, style: .default, handler: { _ in
                action2Handler?()
            })
            
            alertController.addAction(action2)
        }
        
        let cancelAction = AlertAction(title: "cancel".innerLocalized(), style: .cancel)
        
        alertController.addAction(cancelAction)
        
        if useRoot, let root = Self.getRootController() {
            root.present(alertController, animated: true)
        } else {
            topMostViewController().present(alertController, animated: true)
        }
    }
    
    public func presentMediaActionSheet(audioHandler: (() -> Void)?,
                                   videoHandler: (() -> Void)? = nil) {
        let alertController = AlertViewController(message: title, preferredStyle: .actionSheet)
        
        let action1 = AlertAction(title: "callVoice".innerLocalized(), image: UIImage(nameInBundle: "actionsheet_media_audio_icon"), style: .default, alignment: .left, handler: { [self] _ in
            audioHandler?()
        })
        
        alertController.addAction(action1)
        
        let action2 = AlertAction(title: "callVideo".innerLocalized(), image: UIImage(nameInBundle: "actionsheet_media_video_icon"), style: .default, alignment: .left, handler: { [self] _ in
            videoHandler?()
        })
        
        alertController.addAction(action2)
        
        let cancelAction = AlertAction(title: "cancel".innerLocalized(), style: .cancel)
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    public func presentSelectedPictureActionSheet(albumHandler: @escaping (() -> Void), cameraHandler: @escaping (() -> Void)) {
        presentActionSheet(useRoot: false, action1Title: "selectAssetsFromAlbum".innerLocalized(), action1Handler: albumHandler, action2Title: "selectAssetsFromCamera".innerLocalized(), action2Handler: cameraHandler)
    }
    
    public func currentViewController() -> (UIViewController?) {
        var window = UIApplication.shared.keyWindow
        if window?.windowLevel != UIWindow.Level.normal{
            let windows = UIApplication.shared.windows
            for  windowTemp in windows{
                if windowTemp.windowLevel == UIWindow.Level.normal{
                    window = windowTemp
                    break
                }
            }
        }
        let vc = window?.rootViewController
        return currentViewController(vc)
    }
    
    
    private func currentViewController(_ vc :UIViewController?) -> UIViewController? {
        if vc == nil {
            return nil
        }
        if let presentVC = vc?.presentedViewController {
            return currentViewController(presentVC)
        }
        else if let tabVC = vc as? UITabBarController {
            if let selectVC = tabVC.selectedViewController {
                return currentViewController(selectVC)
            }
            return nil
        }
        else if let naiVC = vc as? UINavigationController {
            return currentViewController(naiVC.visibleViewController)
        }
        else {
            return vc
        }
    }
    
    public static func getRootController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first
        let topController = keyWindow?.rootViewController
        return topController
    }
    
    public func findViewController<T: UIViewController>(ofType type: T.Type) -> T? {
        for viewController in children {
            if let matchedViewController = viewController.findViewController(ofType: type) {
                return matchedViewController
            }
        }
        
        if let navigationController = self as? UINavigationController {
            for viewController in navigationController.viewControllers {
                if let matchedViewController = viewController.findViewController(ofType: type) {
                    return matchedViewController
                }
            }
        }
        
        if let tabBarController = self as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                if let matchedViewController = selectedViewController.findViewController(ofType: type) {
                    return matchedViewController
                }
            }
        }
        
        if let matchedViewController = self as? T {
            return matchedViewController
        }
        
        if let presentedViewController = presentedViewController {
            if let matchedViewController = presentedViewController.findViewController(ofType: type) {
                return matchedViewController
            }
        }
        
        return nil
    }
}

extension UIView {
    public func addRoundedCorners(corners: UIRectCorner, radius: CGFloat) {
        layer.masksToBounds = true
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
}

extension UIView {
    public var isHiddenSafe: Bool {
        get {
            isHidden
        }
        set {
            guard isHidden != newValue else {
                return
            }
            isHidden = newValue
        }
    }
    
}

extension UIViewController {

    public func topMostViewController() -> UIViewController {
        if presentedViewController == nil {
            return self
        }
        if let navigationViewController = presentedViewController as? UINavigationController {
            if let visibleViewController = navigationViewController.visibleViewController {
                return visibleViewController.topMostViewController()
            } else {
                return navigationViewController
            }
        }
        if let tabBarViewController = presentedViewController as? UITabBarController {
            if let selectedViewController = tabBarViewController.selectedViewController {
                return selectedViewController.topMostViewController()
            }
            return tabBarViewController.topMostViewController()
        }
        return presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    public func topMostViewController() -> UIViewController? {
        UIApplication.shared.windows.filter(\.isKeyWindow).first?.rootViewController?.topMostViewController()
    }
    
    public func keyWindow() -> UIWindow? {

        return self.connectedScenes

            .filter { $0.activationState == .foregroundActive }

            .first(where: { $0 is UIWindowScene })

            .flatMap({ $0 as? UIWindowScene })?.windows

            .first(where: \.isKeyWindow)
    }
    
    static public var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
    }
    
    static public var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            guard let statusBarHeight = UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.size.height else { return 0 }
            
            return statusBarHeight
        } else {
            return UIApplication.shared.statusBarFrame.size.height
        }
    }
}
