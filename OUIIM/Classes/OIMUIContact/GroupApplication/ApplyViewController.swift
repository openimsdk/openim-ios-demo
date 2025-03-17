import UIKit
import OUICore
import RxSwift
import RxCocoa
import ProgressHUD

class ApplyViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private let viewModel = GroupApplicationViewModel()
    
    private var groupID: String?
    
    private var userID: String?
    
    private var maxCount = 20
    
    init(groupID: String? = nil, userID: String? = nil) {
        self.groupID = groupID
        self.userID = userID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor
        
        let label = UILabel()
        label.text = groupID != nil ? "sendEnterGroupApplication".innerLocalized() : "sendToBeFriendApplication".innerLocalized()
        label.textColor = .c8E9AB0
        label.font = .f14
        
        let inputTextView = UITextView()
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.font = .f17
        inputTextView.textColor = .c0C1C33
        inputTextView.layer.cornerRadius = 5
        
        let vStack = UIStackView(arrangedSubviews: [label, inputTextView])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        let countLabel = UILabel()
        countLabel.textColor = .c8E9AB0
        countLabel.font = .f14
        countLabel.text = "0/\(maxCount)"
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(vStack)
        vStack.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.trailingAnchor.constraint(equalTo: vStack.trailingAnchor, constant: -8),
            countLabel.bottomAnchor.constraint(equalTo: vStack.bottomAnchor, constant: -8),
            
            vStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            vStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            vStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            
            inputTextView.heightAnchor.constraint(equalToConstant: 122)
        ])
        
        let rightButton = UIBarButtonItem(title: "send".innerLocalized(), image: UIImage()) { [weak self] in
            guard let self else { return }
            self.viewModel.apply(grouID: self.groupID, userID: userID, reqMsg: inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines), onSuccess: { [weak self] r in
                ProgressHUD.success("sendSuccessfully".innerLocalized())
                self?.navigationController?.popViewController(animated: true)
            })
        }
        
        navigationItem.rightBarButtonItem = rightButton


        inputTextView.rx.text.map({ [weak self] text in
            guard let self, let text else { return nil }
            return String(text.prefix(self.maxCount))
        }).bind(to: inputTextView.rx.text).disposed(by: disposeBag)
        
        inputTextView.rx.text.orEmpty.subscribe(onNext: { [weak self] text in
            guard let self else { return }
            countLabel.text = "\(text.count)/\(self.maxCount)"
        }).disposed(by: disposeBag)
    }
}
