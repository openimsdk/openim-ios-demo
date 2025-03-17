import UIKit
import OUICore
import ProgressHUD
import SnapKit
import RxSwift

class AboutUsViewController: UIViewController {
    
    public static var version: String {
        let infoDictionary = Bundle.main.infoDictionary
        let displayName = infoDictionary!["CFBundleDisplayName"] as! String
        let majorVersion = infoDictionary!["CFBundleShortVersionString"] as! String
        let minorVersion = infoDictionary!["CFBundleVersion"] as! String
        
        let SDKVersion = "3.8.3+3"
        let info = "\(displayName):\(majorVersion)+\(minorVersion) SDK \(SDKVersion)"
        
        return info
    }
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo_image")
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    private lazy var aboutLabel: UILabel = {
        let label = UILabel()
        label.text = Self.version
        label.textAlignment = .center
        label.numberOfLines = 0
        
        return label
    }()
    
    private let disposeBag = DisposeBag()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "关于我们".localized()
        view.backgroundColor = .viewBackgroundColor
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(logoImageView)
        containerView.addSubview(aboutLabel)
    }
    
    private func setupConstraints() {
        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(16)
            make.centerX.equalTo(containerView)
            make.width.height.equalTo(100)
        }
        
        aboutLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(16)
            make.centerX.equalTo(containerView)
        }
        
        let line = UIView()
        line.backgroundColor = .sepratorColor
        
        containerView.addSubview(line)
        line.snp.makeConstraints { make in
            make.top.equalTo(aboutLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        
        let uploadAllItem = buildItem(title: "uploadErrorLog".localized()) { [weak self] in
            self?.handleUploadLogsAction()
        }
        
        let uploadPartItem = buildItem(title: "uploadLogWithLine".localized()) { [weak self] in
            self?.handleUploadPartLogsAction()
        }
        
        containerView.addSubview(uploadAllItem)
        uploadAllItem.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(line.snp.bottom)
        }
        
        containerView.addSubview(uploadPartItem)
        uploadPartItem.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(uploadAllItem.snp.bottom)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(uploadPartItem).offset(8)
        }
    }
    
    private func buildItem(title: String, onTap: @escaping () -> Void) -> UIView {
        let button = UIButton(type: .system)
        button.tintColor = .black
        button.setTitle(title, for: .normal)
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.rx.tap.subscribe(onNext: { _ in
            onTap()
        }).disposed(by: disposeBag)
        
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        arrowImageView.tintColor = .black
        arrowImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let v = UIView()
        
        let hStack = UIStackView(arrangedSubviews: [button, arrowImageView])
        hStack.alignment = .center
        
        v.addSubview(hStack)
        
        v.snp.makeConstraints { make in
            make.height.equalTo(60)
        }
        
        hStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
        
        return v
    }
    
    @objc
    private func handleUploadLogsAction() {
        ProgressHUD.animate()
        
        IMController.shared.uploadLogs(onProgress: { p in
            ProgressHUD.progress(p)
        }, onSuccess: { _ in
            ProgressHUD.success()
        }, onFailure: { errCode, errMsg in
            ProgressHUD.error()
        })
    }
    
    @objc
    private func handleUploadPartLogsAction() {
        
        showInputAlert { line in
            ProgressHUD.animate()
            
            IMController.shared.uploadLogs(line: line, onProgress: { p in
                ProgressHUD.progress(p)
            }, onSuccess: { _ in
                ProgressHUD.success()
            }, onFailure: { errCode, errMsg in
                ProgressHUD.error()
            })
        }
    }
    
    private func showInputAlert(completion: @escaping (Int) -> Void) {
        let alertController = UIAlertController(title: "uploadLogWithLine".localized(), message: nil, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.text = "1000"
            textField.keyboardType = .numberPad
        }
        
        let confirmAction = UIAlertAction(title: "uploaded".localized(), style: .default) { (_) in
            if let textField = alertController.textFields?.first, 
                let inputText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                let num = Int(inputText) {
                completion(num)
            }
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localized(), style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
