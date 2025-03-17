
import OUICore
import Alamofire

class ChatListHeaderView: UIView {
    
    private var preConnectionStatus = ConnectionStatus.connected
    private let reachabilityManager = NetworkReachabilityManager()
    
    let avatarImageView: AvatarView = {
        let v = AvatarView()
        return v
    }()

    let companyNameLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 12)
        v.textColor = .c0C1C33
        return v
    }()

    let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return v
    }()

    let addBtn: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(nameInBundle: "chat_add_btn_icon"), for: .normal)
        return v
    }()
    
    lazy var connectionIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.startAnimating()
        
        return v
    }()
    
    lazy var errorImageView: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        v.tintColor = .cFF381F
        v.isHidden = true
        
        return v
    }()
    
    lazy var connectionLabel: UILabel = {
        let t = UILabel()
        t.font = .f12
        t.text = "connecting".innerLocalized()
        t.textColor = .c0089FF
        
        return t
    }()

    lazy var connectionView: UIView = {
        let t = UIView()
        t.layer.masksToBounds = true
        t.layer.cornerRadius = StandardUI.cornerRadius

        t.backgroundColor = .c0089FF.withAlphaComponent(0.15)
        let horSV = UIStackView.init(arrangedSubviews: [errorImageView, connectionIndicator, connectionLabel])
        horSV.spacing = 4
        horSV.alignment = .center
        t.addSubview(horSV)
        
        horSV.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
        
        return t
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .tertiarySystemBackground
        
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
        }

        let hStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [nameLabel, connectionView, UIView()])
            v.axis = .horizontal
            v.spacing = 12
            v.alignment = .center
            return v
        }()

        addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.centerY.equalTo(avatarImageView)
        }
        
        connectionView.snp.makeConstraints { make in
            make.height.equalTo(25)
        }

        let btnStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [addBtn])
 
            addBtn.snp.makeConstraints { make in
                make.size.equalTo(28.w)
            }
            v.axis = .horizontal
            v.distribution = .equalSpacing
            v.spacing = 16
            return v
        }()
        addSubview(btnStack)
        btnStack.snp.makeConstraints { make in
            make.leading.equalTo(hStack.snp.trailing).offset(8)
            make.centerY.equalTo(avatarImageView)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().inset(16)
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(kStatusBarHeight + 60.h)
        }
        startListening()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func startListening() {

        reachabilityManager?.startListening()
        reachabilityManager?.listener = { [weak self] status in
            switch status {
            case .notReachable:
                self?.setConnectIndicator(status: .connectFailure, failure: true)
                self?.showConnectionView(true, showIndicator: false)
            default:
                break
            }
        }
    }
    
    private func showConnectionView(_ show: Bool, showIndicator: Bool = false) {
        showIndicator ? connectionIndicator.startAnimating() : connectionIndicator.stopAnimating()
        
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.connectionView.alpha = show ? 1.0 : 0
        }, completion: { [weak self] _ in
            self?.connectionView.isHidden = !show
        })
    }

    func updateConnectionStatus(status: ConnectionStatus) {
        guard reachabilityManager?.isReachable == true else { return }

        showConnectionView(status != .syncComplete && status != .connected, showIndicator: true)
        
        if preConnectionStatus != status {
            switch status {
            case .connectFailure, .syncFailure:
                setConnectIndicator(status: status, failure: true)
            case .connecting, .connected, .syncStart, .syncComplete, .syncProgress:
                setConnectIndicator(status: status, failure: false)
            case .kickedOffline:
                break
            }
        }
        preConnectionStatus = status
    }
    
    private func setConnectIndicator(status: ConnectionStatus, failure: Bool) {
        if failure {
            connectionLabel.text = status.title
            connectionLabel.textColor = .cFF381F
            connectionIndicator.isHidden = true
            errorImageView.isHidden = false
            connectionView.backgroundColor = .c0089FF.withAlphaComponent(0.15)
        } else {
            connectionLabel.text = status.title
            connectionLabel.textColor = .c0089FF
            errorImageView.isHidden = true
            connectionIndicator.isHidden = false
            connectionView.backgroundColor = .c0089FF.withAlphaComponent(0.15)
        }
    }
}
