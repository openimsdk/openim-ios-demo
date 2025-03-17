
import OUICore

public class QRCodeViewController: UIViewController {
    private lazy var shadowView: UIView = {
        let v = UIView()
        v.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.08).cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: 0)
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 7
        return v
    }()

    private let backgroundView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.backgroundColor = .white
        return v
    }()

    public let avatarView = AvatarView()

    public let nameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f20
        v.numberOfLines = 2
        v.textColor = UIColor.c0C1C33
        
        return v
    }()

    public let tipLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f14
        v.textColor = UIColor.c8E9AB0
        
        return v
    }()

    private lazy var codeBackgroundImageView: UIImageView = {
        let v = UIImageView()
        v.layer.borderColor = UIColor.cE8EAEF.cgColor
        v.layer.borderWidth = 4
        
        return v
    }()

    private let codeContentImageView: UIImageView = .init()

    public init(idString: String) {
        super.init(nibName: nil, bundle: nil)
        DispatchQueue.global().async {
            let image = CodeImageGenerator.createQRCodeImage(content: idString, size: CGSize(width: 140, height: 140), foregroundColor: UIColor.black, backgroundColor: UIColor.clear)
            DispatchQueue.main.async {
                self.codeContentImageView.image = image
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "qrcode".innerLocalized()
        initView()
        bindData()
    }

    private func initView() {
        shadowView.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backgroundView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().inset(30)
        }

        backgroundView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(13)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalTo(avatarView)
        }

        backgroundView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.bottom).offset(56)
            make.centerX.equalToSuperview()
        }

        backgroundView.addSubview(codeBackgroundImageView)
        codeBackgroundImageView.snp.makeConstraints { make in
            make.top.equalTo(tipLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.size.equalTo(180)
            make.bottom.equalToSuperview().offset(-80)
        }

        codeBackgroundImageView.addSubview(codeContentImageView)
        codeContentImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        view.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(58)
            make.left.right.equalToSuperview().inset(StandardUI.margin_22)
        }
    }

    private func bindData() {}
}
