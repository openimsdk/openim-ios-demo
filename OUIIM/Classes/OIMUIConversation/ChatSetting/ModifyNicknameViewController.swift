
import OUICore
import RxSwift

open class ModifyNicknameViewController: UIViewController {
    
    public var maxLength = 16
    public var onComplete: (() -> Void)?
    
    public let disposeBag = DisposeBag()
    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .boldSystemFont(ofSize: 20)
        v.textColor = .c333333
        v.text = "nickname".innerLocalized()
        v.textAlignment = .center
        
        return v
    }()

    public let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        v.textColor = .c333333
        v.textAlignment = .center
        v.numberOfLines = 0
        
        return v
    }()

    public let avatarView = AvatarView()

    public lazy var nameTextField: UITextField = {
        let v = UITextField()
        v.clearButtonMode = .always
        v.textColor = .c0C1C33
        v.font = .f17

        v.rx.text.map({ [weak self] text in
            guard let self, let text else { return "" }
            
            return String(text.prefix(maxLength))
        }).bind(to: v.rx.text).disposed(by: disposeBag)
        
        v.rx.controlEvent(.editingChanged).withLatestFrom(v.rx.text.orEmpty).subscribe(onNext: { [weak self] text in
            
            self?.completeBtn.isEnabled = text.trimmingCharacters(in: .whitespacesAndNewlines).count > 0
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    public lazy var completeBtn: UIButton = {
        let v = UIButton(type: .custom)
        v.setTitle("完成".innerLocalized(), for: .normal)
        v.setTitleColor(.white, for: .normal)
        v.setBackgroundColor(.c0089FF, for: .normal)
        v.layer.cornerRadius = 4
        v.layer.masksToBounds = true
        v.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        v.isEnabled = false
        
        return v
    }()
    
    @objc private func handleTap() {
        onComplete?()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cellBackgroundColor
        
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 10.h
        
        view.addSubview(titleStack)
        titleStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(67.h)
            make.leading.equalToSuperview().offset(42.w)
            make.centerX.equalToSuperview()
        }
        
        let line1 = UIView()
        line1.backgroundColor = .sepratorColor
        
        let line2 = UIView()
        line2.backgroundColor = .sepratorColor
        
        let inputStack = UIStackView(arrangedSubviews: [avatarView, nameTextField])
        inputStack.alignment = .center
        inputStack.spacing = 10
        
        let subVerStack = UIStackView(arrangedSubviews: [line1, inputStack, line2])
        subVerStack.axis = .vertical
        subVerStack.spacing = 8.h
        
        line1.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        
        line2.snp.makeConstraints { make in
            make.height.equalTo(1)
        }
        
        view.addSubview(subVerStack)
        subVerStack.snp.makeConstraints { make in
            make.top.equalTo(titleStack.snp.bottom).offset(36.h)
            make.centerX.equalToSuperview()
            make.leading.equalTo(titleStack)
        }
        
        view.addSubview(completeBtn)
        completeBtn.snp.makeConstraints { make in
            make.top.equalTo(subVerStack.snp.bottom).offset(139.h)
            make.centerX.equalToSuperview()
            make.width.equalTo(149.w)
            make.height.equalTo(40.h)
        }
        
        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        
        tap.rx.event.subscribe(onNext: { [weak self] _ in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
    }
}
