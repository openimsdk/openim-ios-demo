
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import SnapKit
import ProgressHUD
import Localize_Swift
import SGCodeTextField
import OUICore

class InputCodeViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    lazy var basicInfo: [String: String] = [:]
    private var usedFor: UsedFor!
    private var operateType: LoginType!

    init(usedFor: UsedFor = .register, operateType: LoginType) {
        super.init(nibName: nil, bundle: nil)
        self.usedFor = usedFor
        self.operateType = operateType
    }
    
    lazy var nextStep: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("nextStep".localized(), for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.titleLabel?.font = .f20
        v.layer.cornerRadius = DemoUI.cornerRadius
        v.layer.masksToBounds = true
        v.isEnabled = false
        v.setBackgroundColor(.c0089FF, for: .normal)
        v.setBackgroundColor(.c0089FF.withAlphaComponent(0.5), for: .disabled)
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.toVerifyCode()
        }).disposed(by: _disposeBag)
        
        return v
    }()
    
    let codeTextField = SGCodeTextField()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let bgImageView = UIImageView(image: UIImage(named: "login_bg"))
        bgImageView.frame = view.bounds
        view.addSubview(bgImageView)
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "common_back_icon"), for: .normal)
        backButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: _disposeBag)
        
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(32)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10.h)
        }
        let label = UILabel()
        label.text =  operateType == .phone ? "enterPhoneVerificationCode".localized() : "enterEmailVerificationCode".localized()
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .c0089FF
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(32)
            make.top.equalTo(backButton.snp.bottom).offset(38.h)
        }
        
        let phone = basicInfo["accout"]!
        let areaCode = basicInfo["areaCode"]
        
        let countDownButton = CountDownTimerButton()
        countDownButton.useLeftTitle = true
        countDownButton.formatPrefix = "verificationCodeTimingReminder".localized()
        countDownButton.useBorder = false
        countDownButton.isCounting = true
        countDownButton.titleLabel?.font = .f12
        countDownButton.setTitleColor(DemoUI.color_8E9AB0, for: .normal)

        countDownButton.clickedBlock = { [weak self] sender in
                        
            guard let `self` = self else { return }
            AccountViewModel.requestCode(phone: operateType == .phone ? phone : nil, areaCode: areaCode, email: operateType == .email ? phone : nil, useFor: self.usedFor) { (errCode, errMsg) in
                if errCode != 0 {
                    ProgressHUD.error(String(errCode).localized())
                } else {
                    ProgressHUD.success("sentSuccess".localized())
                    countDownButton.isCounting = true
                }
            }
        }
      
        let accountLabel = UILabel()
        accountLabel.textColor = DemoUI.color_8E9AB0
        accountLabel.font = .f12
        accountLabel.text = (operateType == .phone ? "\(areaCode ?? "") \(phone)" : phone) + "（默认验证码：666666）"
        
        codeTextField.count = 6
        codeTextField.digitBackgroundColorFocused = .clear
        codeTextField.digitBorderColorFocused = .c0089FF
        codeTextField.digitBorderColor = .c0089FF
        codeTextField.digitBorderColorEmpty = .cE8EAEF
        codeTextField.digitSpacing = 12.w
        codeTextField.placeholder = ""
        codeTextField.digitBorderWidth = 2.0
        codeTextField.refreshUI()
        codeTextField.becomeFirstResponder()
        
        codeTextField.textChangeHandler = { [weak self] text, completed in
            guard let self else { return }
            
            nextStep.isEnabled = text?.count == 6
            codeTextField.digitBorderColor = .c0089FF
            codeTextField.digitBorderColorFocused = .c0089FF

            if completed {
                toVerifyCode()
            }
        }
        
        let spacer = UIView()
        spacer.snp.makeConstraints { make in
            make.height.equalTo(7.h)
        }

        let verSV = UIStackView.init(arrangedSubviews: [accountLabel, spacer, codeTextField, countDownButton])
        verSV.spacing = 14.h
        verSV.axis = .vertical
        view.addSubview(verSV)
        
        let height = (UIScreen.main.bounds.width - 32 * 2 - codeTextField.digitSpacing * 5) / 6.0
        codeTextField.snp.makeConstraints { make in
            make.height.equalTo(height)
        }
        
        verSV.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(label.snp.bottom).offset(10.h)
        }
        
        view.addSubview(nextStep)
        
        nextStep.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(verSV.snp.bottom).offset(170.h)
            make.height.equalTo(42.h)
        }
        
        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            view.endEditing(true)
        }).disposed(by: _disposeBag)
     }
    
    private func toVerifyCode() {
        let phone = basicInfo["accout"]!
        let areaCode = basicInfo["areaCode"]
        
        guard let code = codeTextField.text else { return }
        
        AccountViewModel.verifyCode(phone: operateType == .phone ? phone : nil, areaCode: areaCode, email: operateType == .email ? phone : nil, useFor: self.usedFor, verificationCode: code) { [weak self] errCode, errMsg in
            
            guard let self else { return }
            
            if errCode != 0 {
                nextStep.isEnabled = false
                codeTextField.digitBorderColor = .red
                codeTextField.digitBorderColorFocused = .red
                ProgressHUD.error(String(errCode).localized())
            } else {
                basicInfo["verCode"] = code
                let vc = InputPasswordViewController(usedFor: usedFor, operateType: operateType)
                vc.basicInfo = basicInfo
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    deinit {
        #if DEBUG
        print("dealloc \(type(of: self))")
        #endif
    }
}
