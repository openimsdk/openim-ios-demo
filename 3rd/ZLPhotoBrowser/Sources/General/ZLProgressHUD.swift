

























import UIKit

public class ZLProgressHUD: UIView {
    private let style: ZLProgressHUD.Style
    
    private lazy var loadingView = UIImageView(image: style.icon)
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = style.textColor
        label.font = .zl.font(ofSize: 16)
        label.text = localLanguageTextValue(.hudLoading)
        label.lineBreakMode = .byWordWrapping
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private var timer: Timer?
    
    public var timeoutBlock: (() -> Void)?
    
    deinit {
        zl_debugPrint("ZLProgressHUD deinit")
        cleanTimer()
    }
    
    public init(style: ZLProgressHUD.Style) {
        self.style = style
        super.init(frame: UIScreen.main.bounds)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 135, height: 135))
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 12
        view.backgroundColor = style.bgColor
        view.clipsToBounds = true
        view.center = center
        
        if let effectStyle = style.blurEffectStyle {
            let effect = UIBlurEffect(style: effectStyle)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.bounds
            view.addSubview(effectView)
        }
        
        loadingView.frame = CGRect(x: 135 / 2 - 20, y: 27, width: 40, height: 40)
        view.addSubview(loadingView)
        
        titleLabel.frame = CGRect(x: 10, y: 70, width: view.bounds.width - 20, height: 60)
        view.addSubview(titleLabel)
        
        addSubview(view)
    }
    
    private func startAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = 0.8
        animation.repeatCount = .infinity
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        loadingView.layer.add(animation, forKey: nil)
    }
    
    public func show(
        toast: ZLProgressHUD.Toast = .loading,
        in view: UIView? = UIApplication.shared.keyWindow,
        timeout: TimeInterval = 100
    ) {
        ZLMainAsync {
            self.titleLabel.text = toast.value
            self.startAnimation()
            view?.addSubview(self)
        }
        
        if timeout > 0 {
            cleanTimer()
            timer = Timer.scheduledTimer(timeInterval: timeout, target: ZLWeakProxy(target: self), selector: #selector(timeout(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer!, forMode: .default)
        }
    }
    
    @objc public func hide() {
        cleanTimer()
        ZLMainAsync {
            self.loadingView.layer.removeAllAnimations()
            self.removeFromSuperview()
        }
    }
    
    @objc func timeout(_ timer: Timer) {
        timeoutBlock?()
        hide()
    }
    
    func cleanTimer() {
        timer?.invalidate()
        timer = nil
    }
}

public extension ZLProgressHUD {
    class func show(
        toast: ZLProgressHUD.Toast = .loading,
        in view: UIView? = UIApplication.shared.keyWindow,
        timeout: TimeInterval = 100
    ) -> ZLProgressHUD {
        let hud = ZLProgressHUD(style: ZLPhotoUIConfiguration.default().hudStyle)
        hud.show(toast: toast, in: view, timeout: timeout)
        return hud
    }
}

public extension ZLProgressHUD {
    @objc(ZLProgressHUDStyle)
    enum Style: Int {
        case light
        case lightBlur
        case dark
        case darkBlur
        
        var bgColor: UIColor {
            switch self {
            case .light:
                return .white
            case .dark:
                return .darkGray
            case .lightBlur:
                return UIColor.white.withAlphaComponent(0.8)
            case .darkBlur:
                return UIColor.darkGray.withAlphaComponent(0.8)
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .light, .lightBlur:
                return .zl.getImage("zl_loading_dark")
            case .dark, .darkBlur:
                return .zl.getImage("zl_loading_light")
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .light, .lightBlur:
                return .black
            case .dark, .darkBlur:
                return .white
            }
        }
        
        var blurEffectStyle: UIBlurEffect.Style? {
            switch self {
            case .light, .dark:
                return nil
            case .lightBlur:
                return .extraLight
            case .darkBlur:
                return .dark
            }
        }
    }
    
    enum Toast {
        case loading
        case processing
        case custome(String)
        
        var value: String {
            switch self {
            case .loading:
                return localLanguageTextValue(.hudLoading)
            case .processing:
                return localLanguageTextValue(.hudProcessing)
            case let .custome(text):
                return text
            }
        }
    }
}
