

























import UIKit
import Photos

class ZLImageNavController: UINavigationController {
    var isSelectedOriginal = false
    
    var arrSelectedModels: [ZLPhotoModel] = []
    
    var selectImageBlock: (() -> Void)?
    
    var cancelBlock: (() -> Void)?
    
    deinit {
        zl_debugPrint("ZLImageNavController deinit")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ZLPhotoUIConfiguration.default().statusBarStyle
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        navigationBar.barStyle = .black
        navigationBar.isTranslucent = true
        modalPresentationStyle = .fullScreen
        isNavigationBarHidden = true
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}
