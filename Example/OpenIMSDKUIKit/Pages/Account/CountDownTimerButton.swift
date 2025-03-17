import UIKit
import Localize_Swift

class CountDownTimerButton: UIButton {

    typealias ClickedClosure = (_ sender: UIButton) -> Void

    var clickedBlock: ClickedClosure?

    private var countdownTimer: Timer?

    var isCounting = false {
        willSet {
            if newValue {
                countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime(_:)), userInfo: nil, repeats: true)
            } else {
                countdownTimer?.invalidate()
                countdownTimer = nil
            }
            
            self.isEnabled = !newValue
        }
    }
    
    var useLeftTitle = false {
        willSet {
            contentHorizontalAlignment = newValue ? .left : .center
        }
    }
    
    var useBorder = true {
        willSet {
            self.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    var tipsPrefix: String = "s"
    
    var formatPrefix: String?
    
    var remainingSeconds: Int = 300 {
        
        willSet {
            self.setTitle(formatPrefix != nil ? formatPrefix!.localizedFormat("\(newValue)") : "\(newValue)s", for: .normal)
            if newValue <= 0 {
                self.setTitle("resendVerificationCode".localized(), for: .normal)
                isCounting = false
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() -> Void {
        self.setTitle("sendVerificationCode".localized(), for:.normal)
        self.setTitleColor(.systemBlue, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        self.addTarget(self, action: #selector(sendButtonClick(_:)), for: .touchUpInside)
    }
    
    @objc func sendButtonClick(_ btn:UIButton) {
        
        self.isCounting = true

        self.remainingSeconds = 300
        
        if clickedBlock != nil {
            self.clickedBlock!(btn)
        }
        
    }
    
    @objc func updateTime(_ btn:UIButton) {
        remainingSeconds -= 1
    }
}
