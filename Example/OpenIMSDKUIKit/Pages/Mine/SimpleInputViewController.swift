
import Foundation
import RxSwift
import RxCocoa
import SnapKit
import Localize_Swift

final class SimpleInputViewController: UIViewController {
    var maxLength = 16
    public var onComplete: ((String) -> Void)?
    
    private let disposeBag = DisposeBag()
    
    lazy var textField: UITextField = {
        let v = UITextField()
        v.clearButtonMode = .always
        v.textColor = .c0C1C33
        v.font = .f17
        v.borderStyle = .none
        
        v.rx.text.map({ [weak self] text in
            guard let self, let text else { return "" }
            
            return String(text.prefix(maxLength))
        }).bind(to: v.rx.text).disposed(by: disposeBag)
        
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let saveButton = UIBarButtonItem(title: "save".localized(), style: .done, target: nil, action: nil)
        saveButton.rx.tap.subscribe { [weak self] _ in
            self?.onComplete?(self?.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        }.disposed(by: disposeBag)
        
        navigationItem.rightBarButtonItem = saveButton
        
        let bgContainer = UIView()
        bgContainer.backgroundColor = .systemGray5
        bgContainer.layer.cornerRadius = 4
        
        view.addSubview(bgContainer)
        bgContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(60.h)
        }
        
        bgContainer.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
    }
}
