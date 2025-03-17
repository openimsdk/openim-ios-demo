
import OUICore
import RxSwift
import SnapKit
import ProgressHUD
import OUICoreView

class SearchGroupIndexViewController: UIViewController {
        
    var didSelectedItem: ((_ ID: String) -> Void)?
    
    private let disposeBag = DisposeBag()
    
    private lazy var searchBar: UISearchBar = {
        let v = UISearchBar()
        v.rx.textDidBeginEditing.subscribe(onNext: { [weak self] _ in
            v.searchTextField.resignFirstResponder()
            
            let vc = SearchGroupViewController()
            vc.didSelectedItem = self?.didSelectedItem
            
            self?.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupSubviews()
    }
    
    private func setupSubviews() {
        let vStack = UIStackView(arrangedSubviews: [searchBar])
        vStack.axis = .vertical
        vStack.spacing = 8
        
        view.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
    }
}

