
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import SnapKit
import ProgressHUD
import Localize_Swift
import OUICore

public class InputPasswordViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    lazy var basicInfo: [String: String] = [:]
    private var usedFor: UsedFor = .register
    private var operateType: LoginType!

    init(usedFor: UsedFor = .register, operateType: LoginType) {
        super.init(nibName: nil, bundle: nil)
        self.usedFor = usedFor
        self.operateType = operateType
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.text = "nickname".localized()
        v.textColor = DemoUI.color_8E9AB0
        
        return v
    }()
    
    private lazy var nameTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "plsEnterYourX".localizedFormat("nickname".localized())
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
    
    private lazy var pswLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = DemoUI.color_8E9AB0
        v.text = "password".localized()
        
        return v
    }()
    
    private lazy var eyesButton: UIButton = {
        let t = UIButton(type: .custom)
        t.snp.makeConstraints { make in
            make.size.equalTo(20)
        }
        t.setImage(UIImage(named: "ic_eyes_close"), for: .normal)
        t.setImage(UIImage(named: "ic_eyes_open"), for: .selected)
        t.isSelected = false
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            t.isSelected = !t.isSelected
            guard let `self` = self else { return }
            self.pswTextField.isSecureTextEntry = !self.pswTextField.isSecureTextEntry
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    private lazy var pswTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "plsEnterPassword".localized()
        v.isSecureTextEntry = true
        v.rightViewMode = .always
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
    
    private lazy var againPswLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = DemoUI.color_8E9AB0
        v.text = "confirmPassword".localized()
        
        return v
    }()
    
    private lazy var againPswTextField: UITextField = {
        let v = UITextField()
        v.placeholder = "plsConfirmPasswordAgain".localized()
        v.isSecureTextEntry = true
        v.rightViewMode = .always
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
    
    lazy var nextStepBtn: UIButton = {
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
            sself.toComplate()
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
        
        bgImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer()
        bgImageView.addGestureRecognizer(tap)
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: _disposeBag)
        
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "common_back_icon"), for: .normal)
        backButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: _disposeBag)

        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(28)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10.h)
        }
        let label = UILabel()
        label.text = "set".localized() + (usedFor == .forgotPassword ? "password".localized() : "info".localized())
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .systemBlue

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(32)
            make.top.equalTo(backButton.snp.bottom).offset(38.h)
        }

        let pswTipsLabel = UILabel()
        pswTipsLabel.textColor = DemoUI.color_8E9AB0
        pswTipsLabel.font = .f12
        pswTipsLabel.text = "loginPwdFormat".localized()
        
        let nameStack = UIStackView(arrangedSubviews: [nameLabel, nameTextField])
        nameStack.axis = .vertical
        nameStack.spacing = 6
        
        nameTextField.snp.makeConstraints { make in
            make.height.equalTo(42.h)
        }
        
        let pswStack = UIStackView(arrangedSubviews: [pswLabel, pswTextField, pswTipsLabel])
        pswStack.axis = .vertical
        pswStack.spacing = 6
        
        pswTextField.snp.makeConstraints { make in
            make.height.equalTo(42.h)
        }
        
        let againStack = UIStackView(arrangedSubviews: [againPswLabel, againPswTextField])
        againStack.axis = .vertical
        againStack.spacing = 6
        
        againPswTextField.snp.makeConstraints { make in
            make.height.equalTo(42.h)
        }

        let verSV = UIStackView(arrangedSubviews:
                                    usedFor == .forgotPassword ?
                                [pswStack, againStack] : [nameStack, pswStack, againStack])
        verSV.spacing = 17.h
        verSV.axis = .vertical

        view.addSubview(verSV)

        verSV.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(label.snp.bottom).offset(29.h)
        }

        view.addSubview(nextStepBtn)
        nextStepBtn.snp.makeConstraints { make in
            make.top.equalTo(verSV.snp.bottom).offset(47.h)
            make.leading.trailing.equalTo(verSV)
            make.height.equalTo(42.h)
        }
        
        bindData()
    }
    
    private func bindData() {
        let textField1Observable = nameTextField.rx.text.orEmpty.asObservable()
        let textField2Observable = pswTextField.rx.text.orEmpty.asObservable()
        let textField3Observable = againPswTextField.rx.text.orEmpty.asObservable()

        if usedFor == .forgotPassword {
            let isButtonEnabledObservable = Observable.combineLatest(textField2Observable, textField3Observable)
            { (text1, text2) -> Bool in
                return !text1.isEmpty && !text2.isEmpty
            }
            
            isButtonEnabledObservable.bind(to: nextStepBtn.rx.isEnabled).disposed(by: _disposeBag)
        } else {
            let isButtonEnabledObservable = Observable.combineLatest(textField1Observable, textField2Observable, textField3Observable)
            { (text1, text2, text3) -> Bool in
                return !text1.isEmpty && !text2.isEmpty && !text3.isEmpty
            }
            
            isButtonEnabledObservable.bind(to: nextStepBtn.rx.isEnabled).disposed(by: _disposeBag)
        }
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
    
    private func validatePassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*()_+\\-=[\\]{};':\"\\\\|,.<>\\/?]).{6,20}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        return passwordPredicate.evaluate(with: password)
    }
    
    func toComplate() {
        view.endEditing(true)
        if let psw = againPswTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), psw.validatePassword() {
            
            let p1 = pswTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let p2 = againPswTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if p1 != p2 {
                ProgressHUD.error("twicePwdNoSame".localized())
                return
            }
            
            if usedFor == .register {
                guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
                    ProgressHUD.error( "plsEnterYourX".localizedFormat("nickname".localized()))
                    return
                }
                ProgressHUD.animate()
                let account = operateType == .phone ? basicInfo["accout"]! : nil
                let preAccount = AccountViewModel.perLoginAccount
                
                let tabController = UIApplication.shared.keyWindow?.rootViewController as? MainTabViewController
                
                if account != preAccount {
                    tabController?.clearConversation()
                }

                AccountViewModel.registerAccount(phone: account,
                                                 areaCode: basicInfo["areaCode"]!,
                                                 verificationCode: basicInfo["verCode"]!,
                                                 password: psw,
                                                 faceURL: "",
                                                 nickName: name,
                                                 email: operateType == .email ? basicInfo["accout"]! : nil,
                                                 invitationCode: basicInfo["invitationCode"]) { (errCode, errMsg) in
                    if errMsg != nil {
                        ProgressHUD.error(String(errCode).localized())
                    } else {
                        AccountViewModel.loginIM(uid: AccountViewModel.baseUser.userID,
                                                 imToken: AccountViewModel.baseUser.imToken,
                                                 chatToken: AccountViewModel.baseUser.chatToken) { [weak self] errCode, errMsg in
                            
                            if let userID = AccountViewModel.userID {
//                                GeTuiSdk.bindAlias(userID, andSequenceNum: "im")
                            }
                            UserDefaults.standard.setValue(self?.operateType.rawValue, forKey: loginTypeKey)
                            UserDefaults.standard.synchronize()
                            AccountViewModel.savePreLoginAccount(account)
                            AccountViewModel.updateUserInfo(userID: AccountViewModel.userID!) { (errCode, errMsg) in
                                tabController?.loginSuccess(dismiss: true)
                            }
                        }
                    }
                }
            } else {
                ProgressHUD.animate()
                AccountViewModel.resetPassword(phone: operateType == .phone ? basicInfo["accout"]! : nil,
                                               areaCode: basicInfo["areaCode"]!,
                                               email: operateType == .email ? basicInfo["accout"]! : nil,
                                               verificationCode: basicInfo["verCode"]!,
                                               password: psw) { [weak self] (errCode, errMsg) in
                    
                    if errCode == 0, let `self` = self {
                        ProgressHUD.success("changed".localized() + "success".localized())
                        self.navigationController?.popToRootViewController(animated: true)
                    } else {
                        ProgressHUD.error(String(errCode).localized())
                    }
                }
            }
        } else {
            ProgressHUD.error("plsEnterRightX".localizedFormat("password".localized()))
        }
    }
}
