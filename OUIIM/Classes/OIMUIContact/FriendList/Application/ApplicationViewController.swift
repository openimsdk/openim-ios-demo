
import OUICore
import ProgressHUD

class ApplicationViewController: UIViewController {
    
    lazy var avatarView = AvatarView()
    
    lazy var nickNameLabel: UILabel = {
        let v = UILabel()
        v.font = .f20
        
        return v
    }()
    
    lazy var companyLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        
        return v
    }()
    
    lazy var descTextView: UITextView = {
        let v = UITextView()
        v.font = .f17
        v.textColor = .c0C1C33
        v.backgroundColor = .cE8EAEF
        v.layer.cornerRadius = 5
        v.isEditable = false
        v.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        return v
    }()
    
    lazy var joinSourceLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        v.textColor = .c8E9AB0
        v.textAlignment = .right
        
        return v
    }()
    
    lazy var acceptButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("同意".innerLocalized(), for: .normal)
        v.backgroundColor = .c0089FF
        v.tintColor = .white
        v.layer.cornerRadius = 5
        
        v.rx.tap.subscribe { [weak self] _ in
            self?.accept()
        }
        
        return v
    }()
    
    lazy var refuseButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("拒绝".innerLocalized(), for: .normal)
        v.setTitleColor(.c0C1C33, for: .normal)
        v.backgroundColor = .white
        v.layer.borderColor = UIColor.cE8EAEF.cgColor
        v.layer.borderWidth = 1
        v.layer.cornerRadius = 5
        
        v.rx.tap.subscribe { [weak self] _ in
            self?.refuse()
        }
        
        return v
    }()
    
    var viewModel: ApplicationViewModel!
    
    init(groupApplication: GroupApplicationInfo? = nil, friendApplication: FriendApplication? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = ApplicationViewModel(groupApplication: groupApplication, friendApplication: friendApplication)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor

        let bStack = UIStackView(arrangedSubviews: [nickNameLabel, companyLabel])
        bStack.axis = .vertical
        bStack.spacing = 4
        
        let pStack = UIStackView(arrangedSubviews: [avatarView, bStack])
        pStack.spacing = 8
        pStack.alignment = .center
        
        let btnStack = UIStackView(arrangedSubviews: [refuseButton, acceptButton])
        btnStack.alignment = .center
        btnStack.spacing = 8
        btnStack.distribution = .fillEqually
        
        let vStack = UIStackView(arrangedSubviews: [pStack, descTextView, joinSourceLabel, btnStack])
        vStack.spacing = 16
        vStack.axis = .vertical
        
        let bgView = UIView()
        bgView.backgroundColor = .cellBackgroundColor
        view.addSubview(bgView)
        
        bgView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Int.margin8)
        }
        
        bgView.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Int.margin16)
        }
        
        descTextView.snp.makeConstraints { make in
            make.height.equalTo(80.h)
        }
        
        refuseButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        acceptButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        var faceURL: String?
        var nickName: String?
        
        if let friendApplication = viewModel.friendApplication {
            faceURL = friendApplication.fromFaceURL
            nickName = friendApplication.fromNickname
        } else if let groupApplication = viewModel.groupApplication {
            faceURL = groupApplication.userFaceURL
            nickName = groupApplication.nickname
        }
        
        avatarView.setAvatar(url: faceURL, text: nickName, onTap: nil)
        nickNameLabel.text = nickName
        descTextView.text = viewModel.requestDescString
        descTextView.isHidden = viewModel.requestDescString.isEmpty
        
        if viewModel.groupApplication != nil {
            companyLabel.attributedText = viewModel.companyString
            joinSourceLabel.text = viewModel.joinSourceString
        }
    }
    
    func accept() {
        ProgressHUD.animate()
        viewModel.accept { [weak self] r in
            if r == nil {
                ProgressHUD.dismiss()
                self?.navigationController?.popViewController(animated: true)
            } else {
                ProgressHUD.error(r)
            }
        }
    }
    
    func refuse() {
        ProgressHUD.animate()
        viewModel.refuse { [weak self] r in
            if r == nil {
                ProgressHUD.dismiss()
                self?.navigationController?.popViewController(animated: true)
            } else {
                ProgressHUD.error(r)
            }
        }
    }
}
