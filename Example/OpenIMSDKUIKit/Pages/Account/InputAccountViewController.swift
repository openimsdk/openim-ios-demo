
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import MMBAlertsPickers
import SnapKit
import ProgressHUD
import OUICore

public class InputAccountViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    private var _areaCode = "+86"
    private var usedFor: UsedFor!
    private var operateType: LoginType!
    
    init(usedFor: UsedFor = .register, operateType: LoginType) {
        super.init(nibName: nil, bundle: nil)
        self.usedFor = usedFor
        self.operateType = operateType
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var phoneSegment: UILabel = {
        let v = UILabel()
        v.textColor = DemoUI.color_8E9AB0
        v.text = operateType == .phone ? "phoneNumber".localized() : "email".localized()
        v.font = .f12
        
        return v
    }()
    
    lazy var checkBoxButton: UIButton = {
        let t = UIButton(type: .custom)
        t.snp.makeConstraints { make in
            make.size.equalTo(20)
        }
        t.setImage(UIImage(named: "common_checkbox_unselected"), for: .normal)
        t.setImage(UIImage(named: "common_checkbox_selected"), for: .selected)
        t.isSelected = true
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.agreeProtocal()
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    public var phone: String? {
        return phoneTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    public var areaCode: String {
        return _areaCode
    }
    
    lazy var areaCodeButton: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("\(_areaCode)", for: .normal)
        t.setTitleColor(DemoUI.color_0C1C33, for: .normal)
        t.titleLabel?.font = .systemFont(ofSize: 17)
        t.isHidden = operateType != .phone
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            let alert = UIAlertController(style: .actionSheet, title: "Phone Codes")
            alert.addLocalePicker(type: .phoneCode) {[weak self] info in

                guard let phoneCode = info?.phoneCode else {return}
                self?._areaCode = phoneCode
                t.setTitle("\(phoneCode)", for: .normal)
            }
            
            alert.addAction(title: "cancel".localized(), style: .cancel)
            sself.present(alert, animated: true)
        }).disposed(by: _disposeBag)
        return t
    }()
        
    private lazy var phoneTextField: UITextField = {
        let v = UITextField()
        v.keyboardType = operateType == .phone ? .numberPad : .default
        v.borderStyle = .none
        v.textColor = DemoUI.color_0C1C33
        v.clearButtonMode = .whileEditing
        v.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        v.leftViewMode = .always
        v.placeholder = operateType == .phone ? "plsEnterPhoneNumber".localized() : "plsEnterEmail".localized()

        return v
    }()
    
    private let invitationCodeLabel: UILabel = {
        let v = UILabel()
        v.text = "invitationCode".localized()
        v.textColor = DemoUI.color_8E9AB0
        v.font = .f12
        
        return v
    }()
    
    private lazy var invitationCodeTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "请输入邀请码（选填）".localized()
        v.layer.cornerRadius = DemoUI.cornerRadius
        v.layer.borderColor = DemoUI.color_E8EAEF.cgColor
        v.layer.borderWidth = 1
        v.borderStyle = .none
        v.textColor = DemoUI.color_0C1C33
        v.clearButtonMode = .whileEditing
        v.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        v.leftViewMode = .always
        
        return v
    }()
    
    lazy var loginBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("registerNow".localized(), for: .normal)
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
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    public override func viewDidLoad() {
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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel()
        label.text = usedFor == .register ? "newUserRegister".localized() : "forgetPassword".localized()
        label.font = .systemFont(ofSize: 25, weight: .semibold)
        label.textColor = .c0089FF
        
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(backButton)
            make.top.equalTo(backButton.snp.bottom).offset(33.h)
        }
        
        let line = UIView()
        line.backgroundColor = DemoUI.color_E8EAEF
        
        let accountStack = UIStackView(arrangedSubviews: [areaCodeButton, line, phoneTextField])
        accountStack.spacing = 8
        accountStack.alignment = .center
        accountStack.layer.cornerRadius = DemoUI.cornerRadius
        accountStack.layer.borderColor = DemoUI.color_E8EAEF.cgColor
        accountStack.layer.borderWidth = 1
                
        areaCodeButton.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        
        phoneTextField.snp.makeConstraints { make in
            make.height.equalTo(42.h)
        }
        
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.top.bottom.equalToSuperview().inset(4)
        }
        
        invitationCodeTextField.snp.makeConstraints { make in
            make.height.equalTo(42.h)
        }
        
        let accountVerStack = UIStackView(arrangedSubviews: [phoneSegment, accountStack])
        accountVerStack.axis = .vertical
        accountVerStack.spacing = 7
        
        let invitationVerStack = UIStackView(arrangedSubviews: [invitationCodeLabel, invitationCodeTextField])
        invitationVerStack.axis = .vertical
        invitationVerStack.spacing = 7
        
        loginBtn.setTitle(usedFor == .register ? "registerNow".localized() : "sendVerificationCode".localized(), for: .normal)
        let verSV = UIStackView.init(arrangedSubviews: usedFor == .register ?
                                     ([accountVerStack, /*invitationVerStack*/]) :
                                        [accountVerStack])
        
        verSV.axis = .vertical
        verSV.spacing = 18.h
        verSV.alignment = .fill
        view.addSubview(verSV)
        
        verSV.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(label.snp.bottom).offset(32.h)
        }
        
        view.addSubview(loginBtn)
        loginBtn.snp.makeConstraints { make in
            make.top.equalTo(verSV.snp.bottom).offset(148.h)
            make.leading.trailing.equalTo(verSV)
            make.height.equalTo(42.h)
        }
        
        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            view.endEditing(true)
        }).disposed(by: _disposeBag)
        
        bindData()
        
        if usedFor == .forgotPassword {
            return
        }
        
        let protocalLabel = UILabel()
        protocalLabel.isUserInteractionEnabled = true
        protocalLabel.font = .systemFont(ofSize: 13)
        let text = NSMutableAttributedString.init(string: "我已阅读并同意:".localized())
        text.append(NSAttributedString(string: "《服务协议》《隐私权政策》".localized(), attributes: [NSAttributedString.Key.foregroundColor: DemoUI.color_1D6BED]))
        protocalLabel.attributedText = text
        
        protocalLabel.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in
                guard let sself = self else { return }
                sself.toPrivacyRule()
            }).disposed(by: _disposeBag)

        let horSV = UIStackView.init(arrangedSubviews: [checkBoxButton, protocalLabel])
        horSV.alignment = .center
        horSV.spacing = 8






    }
    
    private func bindData() {
        phoneTextField.rx.text.orEmpty
            .map({ $0.count > 0})
            .bind(to: loginBtn.rx.isEnabled)
            .disposed(by: _disposeBag)
    }
    
    deinit {
        #if DEBUG
        print("dealloc \(type(of: self))")
        #endif
    }
    
    func toVerifyCode() {
        view.endEditing(true)
        
        if let phone = phoneTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), phone.isEmpty  {
            if operateType == .phone {
                ProgressHUD.error("plsEnterRightX".localizedFormat("phoneNumber".localized()))
            } else {
                ProgressHUD.error("plsEnterRightX".localizedFormat("email".localized()))
            }
            return
        }
        
        let invaitationCode = invitationCodeTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        ProgressHUD.animate()
        
        AccountViewModel.requestCode(phone: operateType == .phone ? phone : nil, areaCode: areaCode, email: operateType == .email ? phone : nil, invaitationCode: invaitationCode, useFor: usedFor) { [weak self] errCode, errMsg in

            guard let sself = self else { return }
            
            if errCode != 0 {
                ProgressHUD.error(String(errCode).localized())
                
                if errCode == 20002 {
                    let vc = InputCodeViewController(usedFor: sself.usedFor, operateType: sself.operateType)
                    vc.basicInfo = ["accout": sself.phone!,
                                    "areaCode": sself.areaCode,
                                    "invitationCode": invaitationCode ?? ""]
                    sself.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                
                ProgressHUD.dismiss()
                let vc = InputCodeViewController(usedFor: sself.usedFor, operateType: sself.operateType)
                vc.basicInfo = ["accout": sself.phone!,
                                "areaCode": sself.areaCode,
                                "invitationCode": invaitationCode ?? ""]
                sself.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func agreeProtocal() {
        checkBoxButton.isSelected = !checkBoxButton.isSelected
    }
    
    func toPrivacyRule() {
        UIApplication.shared.openURL(NSURL.init(string:"https://www.openim.io/")! as URL);
    }
}
