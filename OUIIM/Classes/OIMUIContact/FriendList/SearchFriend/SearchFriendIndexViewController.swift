
import OUICore
import RxSwift
import SnapKit
import ProgressHUD

class SearchFriendIndexViewController: UIViewController {
        
    var didSelectedItem: ((_ ID: String) -> Void)?
    
    private let disposeBag = DisposeBag()
    
    private lazy var searchBar: UISearchBar = {
        let v = UISearchBar()
        v.rx.textDidBeginEditing.subscribe(onNext: { [weak self] _ in
            v.searchTextField.resignFirstResponder()
            
            let vc = SearchFriendViewController()
            vc.didSelectedItem = self?.didSelectedItem
            
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    private lazy var myQrcodeView: ListTileView = {
        let v = ListTileView()
        v.imageView.image = UIImage(nameInBundle: "common_qrcode_icon_blue")
        v.titleLabel.text = "myQrcode".innerLocalized()
        v.subTitleLabel.text = "myQrcodeHint".innerLocalized()
        
        v.onTap = { [weak self] in
            guard let user = IMController.shared.currentUserRelay.value else { return }
            
            let vc = QRCodeViewController(idString: IMController.addFriendPrefix.append(string: user.userID))
            vc.nameLabel.text = user.nickname
            vc.avatarView.setAvatar(url: user.faceURL, text: user.nickname)
            vc.tipLabel.text = "qrcodeHint".innerLocalized()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupSubviews()
    }
    
    private func setupSubviews() {
        let vStack = UIStackView(arrangedSubviews: [searchBar, myQrcodeView])
        vStack.axis = .vertical
        vStack.spacing = 8
        
        view.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
    }
}

class ListTileView: UIView {

    var onTap: (() -> Void)?
    
    lazy var imageView: UIImageView = {
        let v = UIImageView()
        
        return v
    }()
    
    lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)
        
        return v
    }()
    
    lazy var subTitleLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = .c8E9AB0
        v.setContentCompressionResistancePriority(UILayoutPriority(999), for: .vertical)

        return v
    }()
    
    private lazy var indicatorImageView: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "chevron.right"))
        v.tintColor = .c707070
        
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let disposeBag = DisposeBag()
    
    private func setupSubviews() {
        let vStack = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        
        let hStack = UIStackView(arrangedSubviews: [imageView, vStack, UIView(), indicatorImageView])
        hStack.spacing = 18.w
        hStack.alignment = .center
        
        addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            self?.onTap?()
        }).disposed(by: disposeBag)
    }
}

