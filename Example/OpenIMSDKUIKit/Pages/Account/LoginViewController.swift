
import UIKit
import RxSwift
import RxCocoa
import RxGesture
import MMBAlertsPickers
import SnapKit
import ProgressHUD
import OUICore
import JXSegmentedView

enum LoginType: Int {
    case phone = 0
    case email = 1
    case account = 2
    
    var name: String {
        switch (self) {
        case .phone:
            return "phoneNumber".localized()
        case .email:
            return "email".localized()
        case .account:
            return "account".localized()
        }
    }
    
    var hintText: String {
        switch (self) {
        case .phone:
            return "plsEnterPhoneNumber".localized();
        case .email:
            return "plsEnterEmail".localized();
        case .account:
            return "plsEnterAccount".localized();
        }
    }
}

let loginTypeKey = "com.oimuikit.login.type"

class LoginViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    
    private var _areaCode = "+86"
    
    public var loginType: LoginType = .phone {
        didSet {
            let isHidden = loginType == .account
            forgotButton.isHidden = isHidden
            codeLoginButton.isHidden = isHidden
            registerStackView?.isHidden = isHidden
        }
    }
        
    private let inputPhoneTag = 10000
    private let inputPhonePswTag = 10001
    private let inputPhonePswRightTag = 10002
    
    private let inputEmailTag = 10003
    private let inputEmailPswTag = 10004
    private let inputEmailPswRightTag = 10005
    
    private let inputAccountTag = 10006
    private let inputAccountPswTag = 10007

    let container = UIView()
    let tabBar = JXSegmentedView()
    let segmentedDataSource = JXSegmentedTitleDataSource()
    let scrollView = UIScrollView()

    let phoneLoginView = UIView()  // For phone login style 1
    let emailLoginView = UIView()  // For email login style 2
    let accountLoginView = UIView()  // For account login style 2
    
    private let logoImageView: UIImageView = {
        let v = UIImageView(image: UIImage(named: "logo_image"))
        v.isUserInteractionEnabled = true
        
        return v
    }()
    
    
    private let titleLabel: UILabel = {
        let v = UILabel()
        v.text = "welcome".localized()
        v.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        v.textColor = DemoUI.color_0089FF
        
        return v
    }()
    
    lazy var registerButton: UIButton = {
        let t = UIButton(type: .system)
        t.setTitle("registerNow".localized(), for: .normal)
        t.titleLabel?.font = .f12
        
        t.rx.tap.subscribe(onNext: { [unowned self] _ in
            showRegisterBottomSheet()
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    var registerStackView: UIStackView?
    
    lazy var forgotButton: UIButton = {
        let t = UIButton(type: .system)
        t.setTitle("forgetPassword".localized(), for: .normal)
        t.setTitleColor(DemoUI.color_8E9AB0, for: .normal)
        t.titleLabel?.font = .f12
        
        t.rx.tap.subscribe(onNext: { [unowned self] _ in
            toForgotPassword()
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    lazy var codeLoginButton: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("verificationCodeLogin".localized(), for: .normal)
        t.setTitle("passwordLogin".localized(), for: .selected)
        t.setTitleColor(DemoUI.color_0089FF, for: .selected)
        t.setTitleColor(DemoUI.color_0089FF, for: .normal)
        t.titleLabel?.font = .f12
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            t.isSelected = !t.isSelected
            sself.toCodeLogin()
        }).disposed(by: _disposeBag)
        return t
    }()
    
    lazy var checkBoxButton: UIButton = {
        let t = UIButton(type: .custom)
        t.setImage(UIImage(named: "common_checkbox_unselected"), for: .normal)
        t.setImage(UIImage(named: "common_checkbox_selected"), for: .selected)
        t.isSelected = true
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            sself.agreeProtocal()
        }).disposed(by: _disposeBag)
        
        return t
    }()
    
    var phone: String? {
        return getTextField().account.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var password: String? {
        return !codeLoginButton.isSelected ? getTextField().password.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) : nil
    }
    
    var areaCode: String {
        return _areaCode
    }
    
    var verificationCode: String? {
        return codeLoginButton.isSelected ? getTextField().password.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) : nil
    }
    
    lazy var loginBtn: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("login".localized(), for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.titleLabel?.font = .f20
        v.layer.cornerRadius = DemoUI.cornerRadius
        v.layer.masksToBounds = true
        v.setBackgroundColor(.c0089FF, for: .normal)
        v.setBackgroundColor(.c0089FF.withAlphaComponent(0.5), for: .disabled)
        
        v.isEnabled = false
        
        return v
    }()
    
    lazy var versionLabel: UILabel = {
        let v = UILabel()
        v.text = AboutUsViewController.version
        
        return v
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        let index = loginType.rawValue
        tabBar.defaultSelectedIndex = index
        loginType = LoginType(rawValue: UserDefaults.standard.integer(forKey: loginTypeKey)) ?? .phone
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let index = loginType.rawValue
        switchToTab(index: index, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    
        loginType = LoginType(rawValue: UserDefaults.standard.integer(forKey: loginTypeKey)) ?? .phone
        
        let bgImageView = UIImageView(image: UIImage(named: "login_bg"))
        bgImageView.frame = view.bounds
        view.addSubview(bgImageView)
        
        view.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(88.h)
            make.size.equalTo(64.w)
        }
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(8.h)
            make.centerX.equalToSuperview()
        }
        setupContainerView()
        
#if ENABLE_ORGANIZATION
#else
        view.addSubview(forgotButton)
        forgotButton.snp.makeConstraints { make in
            make.top.equalTo(container.snp.bottom).offset(6.h)
            make.leading.equalTo(container)
        }
        
        view.addSubview(codeLoginButton)
        codeLoginButton.snp.makeConstraints { make in
            make.top.equalTo(forgotButton)
            make.trailing.equalTo(container)
        }
#endif
        
        view.addSubview(loginBtn)
        loginBtn.snp.makeConstraints { make in
            make.height.equalTo(42.h)
            make.top.equalTo(forgotButton.snp.bottom).offset(40.h)
            make.leading.trailing.equalTo(container)
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





#if ENABLE_ORGANIZATION
#else

        let label = UILabel()
        label.textColor = DemoUI.color_8E9AB0
        label.font = .f12
        label.text = "noAccountYet".localized()
        registerStackView = UIStackView.init(arrangedSubviews: [UIView(), label, registerButton, UIView()])
        registerStackView!.alignment = .center
        view.addSubview(registerStackView!)
        
        registerStackView!.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(loginBtn.snp.bottom).offset(100.h)
        }
#endif
        
        view.addSubview(versionLabel)
        versionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(registerStackView!.snp.bottom).offset(32.h)
        }
        
        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            view.endEditing(true)
        }).disposed(by: _disposeBag)
        
        bindData()
    }
    
    private func bindData() {
        let t = getTextField()
        let accountTextField = t.account
        let pswTextField = t.password
        
        Observable.combineLatest(accountTextField.rx.text.orEmpty, pswTextField.rx.text.orEmpty) {
            $0.count > 0 && $1.count > 0
        }
        .bind(to: loginBtn.rx.isEnabled)
        .disposed(by: _disposeBag)
    }
    
    func getTextField() -> (account: UITextField, password: UITextField) {
        var accountTextField: UITextField
        var pswTextField: UITextField
        
        switch loginType {
        case .phone:
            accountTextField = phoneLoginView.viewWithTag(inputPhoneTag) as! UITextField
            pswTextField = phoneLoginView.viewWithTag(inputPhonePswTag) as! UITextField
        case .email:
            accountTextField = emailLoginView.viewWithTag(inputEmailTag) as! UITextField
            pswTextField = emailLoginView.viewWithTag(inputEmailPswTag) as! UITextField
        case .account:
            accountTextField = accountLoginView.viewWithTag(inputAccountTag) as! UITextField
            pswTextField = accountLoginView.viewWithTag(inputAccountPswTag) as! UITextField
        }
        
        return (account: accountTextField, password: pswTextField)
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
    
    func toRegister() {
        let vc = InputAccountViewController(operateType: loginType)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func toCodeLogin() {
        switch loginType {
        case .phone:
            guard let pswTextField = phoneLoginView.viewWithTag(inputPhonePswTag) as? UITextField else { return }
            
            if codeLoginButton.isSelected {
                pswTextField.rightView = setupCountdownButton()
            } else {
                pswTextField.rightView = setupPswRightView(pswTextField)
            }
        case .email:
            guard let pswTextField = emailLoginView.viewWithTag(inputEmailPswTag) as? UITextField else { return }
            
            if codeLoginButton.isSelected {
                pswTextField.rightView = setupCountdownButton()
            } else {
                pswTextField.rightView = setupPswRightView(pswTextField)
            }
        case .account:
            break
        }








    }
    
    private func setupCountdownButton() -> CountDownTimerButton {
        let v = CountDownTimerButton()
        
        v.clickedBlock = { [weak self] sender in
            guard let sself = self,
                  let phone = sself.getTextField().account.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            
            AccountViewModel.requestCode(phone: phone, areaCode: sself.areaCode, useFor: .login) { (errCode, errMsg) in
                if errMsg != nil {
                    ProgressHUD.error(errCode == -1 ? errMsg : String(errCode).localized())
                } else {
                    ProgressHUD.success("发送".localized() + "成功".localized())
                }
            }
        }
        
        return v
    }
    
    func toForgotPassword() {
        let vc = InputAccountViewController(usedFor: .forgotPassword, operateType: loginType)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func agreeProtocal() {
        checkBoxButton.isSelected = !checkBoxButton.isSelected
    }
    
    func toPrivacyRule() {
        UIApplication.shared.openURL(NSURL.init(string:"https://www.openim.io/")! as URL);
    }
    
    func showRegisterBottomSheet() {
        presentActionSheet(useRoot: false, action1Title: "email".localized() + "registerNow".localized(), action1Handler: { [weak self] in
            self?.loginType = .email
            self?.toRegister()
        }, action2Title: "phoneNumber".localized() + "registerNow".localized()) { [weak self] in
            self?.loginType = .phone
            self?.toRegister()
        }
    }
    
    private func setupContainerView() {

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32.w)
        }

        setupTabBar()

        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = false
        scrollView.bounces = false
        scrollView.bouncesZoom = false
        scrollView.delegate = self
        container.addSubview(scrollView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(tabBar.snp.bottom).offset(16.h)
            make.leading.trailing.bottom.equalTo(container)
        }

        setupTabViews()
    }
    
    private func setupTabBar() {
        tabBar.defaultSelectedIndex = loginType.rawValue
        tabBar.contentEdgeInsetLeft = 0
        container.addSubview(tabBar)
        tabBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(container)
            make.height.equalTo(50)
        }
        
        self.segmentedDataSource.titles = ["phoneNumber".localized(), "email".localized(), "account".localized()]
        self.segmentedDataSource.isItemSpacingAverageEnabled = false
        self.segmentedDataSource.titleSelectedColor = DemoUI.color_0089FF
        tabBar.dataSource = self.segmentedDataSource
        
        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorWidth = 20
        indicator.indicatorColor = DemoUI.color_0089FF
        tabBar.indicators = [indicator]
        
        tabBar.delegate = self
        tabBar.collectionView.isUserInteractionEnabled = true
        tabBar.collectionView.allowsSelection = true
        
        let tap = UITapGestureRecognizer()
        tap.rx.event.subscribe(onNext: { [weak self] sender in
            guard let self else { return }
            
            let location = sender.location(in: tabBar.collectionView)
            
            if let indexPath = tabBar.collectionView.indexPathForItem(at: location) {
                let index = indexPath.item
                print("Item \(index) selected")
                
                tabBar.selectItemAt(index: index)
                switchToTab(index: index, animated: true)
            }
        }).disposed(by: _disposeBag)
        
        tabBar.collectionView.addGestureRecognizer(tap)
    }
    
    private func setupTabViews() {

        scrollView.addSubview(phoneLoginView)
        scrollView.addSubview(emailLoginView)
        scrollView.addSubview(accountLoginView)

        let temp = setupLoginStyle1(in: phoneLoginView) // For phone login
        temp.account.tag = inputPhoneTag
        temp.password.tag = inputPhonePswTag
        temp.account.placeholder = LoginType.phone.hintText
        
        let temp2 = setupLoginStyle2(in: emailLoginView) // For email login
        temp2.account.tag = inputEmailTag
        temp2.password.tag = inputEmailPswTag
        temp2.account.placeholder = LoginType.email.hintText
        
        let temp3 = setupLoginStyle2(in: accountLoginView) // For account login
        temp3.account.tag = inputAccountTag
        temp3.password.tag = inputAccountPswTag
        temp3.account.placeholder = LoginType.account.hintText
        
        let preAccount = AccountViewModel.perLoginAccount
        
        switch loginType {
        case .phone:
            temp.account.text = preAccount
        case .email:
            temp2.account.text = preAccount
        case .account:
            temp3.account.text = preAccount
        }

        let tabViews = [phoneLoginView, emailLoginView, accountLoginView]
        for (index, view) in tabViews.enumerated() {
            view.snp.makeConstraints { make in
                make.top.bottom.equalTo(scrollView)
                make.width.height.equalTo(scrollView)  // Each tab view takes the width of the screen
                if index == 0 {
                    make.leading.equalTo(scrollView)
                } else if index == tabViews.count - 1 {
                    make.trailing.equalTo(scrollView)
                }
                if index > 0 {
                    make.leading.equalTo(tabViews[index - 1].snp.trailing)
                }
            }
        }
    }

    private func setupLoginStyle1(in view: UIView) -> (account: UITextField, password: UITextField) {
        let phoneTextField = setupAccountTextField()
        phoneTextField.keyboardType = .numberPad
        let passwordTextField = setupPasswordTextField()
        
        let verStack = UIStackView(arrangedSubviews: [phoneTextField, passwordTextField])
        verStack.axis = .vertical
        verStack.spacing = 16
        verStack.distribution = .fillEqually
        
        view.addSubview(verStack)
        verStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return (account: phoneTextField, password: passwordTextField)
    }

    private func setupLoginStyle2(in view: UIView) -> (account: UITextField, password: UITextField) {
        
        let accountTextField = setupAccountTextField()
        accountTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        let passwordTextField = setupPasswordTextField()
        
        let verStack = UIStackView(arrangedSubviews: [accountTextField, passwordTextField])
        verStack.axis = .vertical
        verStack.spacing = 16
        verStack.distribution = .fillEqually
        
        view.addSubview(verStack)
        verStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return (account: accountTextField, password: passwordTextField)
    }
    
    private func setupAccountTextField() -> UITextField {
        let v = UITextField()
        v.clearButtonMode = .whileEditing
        v.textColor = DemoUI.color_0C1C33
        v.layer.cornerRadius = DemoUI.cornerRadius
        v.layer.borderColor = DemoUI.color_E8EAEF.cgColor
        v.layer.borderWidth = 1
        
        let rightView = InputFiledRightView()
        rightView.eyesButton.isHidden = true
        v.rightView = rightView
        v.rightViewMode = .always
        
        rightView.onButtonClicked = { type in
            if type == .clear {
                v.text = nil
                v.sendActions(for: .allEditingEvents)
            }
        }
        
        let leftView = InputFiledLeftView()
        leftView.codeLabel.text = _areaCode
        
        v.leftView = leftView
        v.leftViewMode = .always
        
        leftView.onTap = { [weak self] in
            guard let self else { return }
            
            let alert = UIAlertController(style: .actionSheet, title: "Phone Codes")
            alert.addLocalePicker(type: .phoneCode) {[self] info in
                guard let phoneCode = info?.phoneCode else {return}
                
                self._areaCode = phoneCode
                leftView.codeLabel.text = phoneCode
            }
            
            alert.addAction(title: "cancel".localized(), style: .cancel)
            present(alert, animated: true)
        }
        
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 44).isActive = true
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        
        return v
    }
    
    private func setupPasswordTextField() -> UITextField {
        let v = UITextField()
        v.placeholder = "plsEnterPassword".localized()
        v.isSecureTextEntry = true
        v.layer.cornerRadius = DemoUI.cornerRadius
        v.layer.borderColor = DemoUI.color_E8EAEF.cgColor
        v.layer.borderWidth = 1
        v.borderStyle = .none
        v.textColor = DemoUI.color_0C1C33
        v.clearButtonMode = .whileEditing
        v.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        v.leftViewMode = .always
        
        v.rightView = setupPswRightView(v)
        v.rightViewMode = .always
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 44).isActive = true
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        
        return v
    }
    
    private func setupPswRightView(_ textFiled: UITextField) -> InputFiledRightView {
        let rightView = InputFiledRightView()
        
        rightView.onButtonClicked = { type in
            if type == .clear {
                textFiled.text = nil
                textFiled.sendActions(for: .allEditingEvents)
            } else {
                textFiled.isSecureTextEntry = !textFiled.isSecureTextEntry
            }
        }
        
        return rightView
    }

    private func switchToTab(index: Int, animated: Bool) {
        let offsetX = CGFloat(index) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
    }
}


extension LoginViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {

        loginType = LoginType(rawValue: index)!
        view.endEditing(true)
        bindData()
    }
}


extension LoginViewController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        tabBar.selectItemAt(index: pageIndex)
    }
}

class InputFiledRightView: UIView {
    
    public enum ButtonType {
        case clear
        case eye
    }
    
    public var onButtonClicked: ((ButtonType) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var eyesButton: UIButton = {
        let v = UIButton(type: .custom)
        
        v.setImage(UIImage(named: "ic_eyes_close"), for: .normal)
        v.setImage(UIImage(named: "ic_eyes_open"), for: .selected)
        v.isSelected = false
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            v.isSelected = !v.isSelected
            guard let self else { return }
            
            onButtonClicked?(.eye)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    lazy var clearButton: UIButton = {
        let v = UIButton(type: .custom)
        v.setImage(UIImage(named: "ic_clear"), for: .normal)
        
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            onButtonClicked?(.clear)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    private let disposeBag = DisposeBag()
    
    private func setupSubviews() {
        let hSV = UIStackView(arrangedSubviews: [clearButton, eyesButton])
        hSV.spacing = 8
        
        addSubview(hSV)
        hSV.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
        }
    }
}

class InputFiledLeftView: UIView {
    
    var onTap: (() -> Void)?
    
    var codeLabel: UILabel = {
        let v = UILabel()
        
        
        return v
    }()
    
    private var line: UIView = {
        let v = UIView()
        v.backgroundColor = DemoUI.color_E8EAEF
        
        return v
    }()
    
    private let _disposeBag = DisposeBag()
    
    init() {
        super.init(frame: .zero)
        
        addSubview(codeLabel)
        codeLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(8)
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
        addSubview(line)
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.leading.equalTo(codeLabel.snp.trailing).offset(4)
            make.top.trailing.bottom.equalToSuperview().inset(8)
        }
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            onTap?()
        }).disposed(by: _disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
