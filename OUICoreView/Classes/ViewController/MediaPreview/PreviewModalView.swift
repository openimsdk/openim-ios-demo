import OUICore
import SnapKit

public class PreviewModalView: UIView {
    public enum ActionType {
        case forward
        case save
    }
    
    var onButtonAction: ((ActionType) -> Void)?
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .cellBackgroundColor
        view.layer.cornerRadius = 5
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        return view
    }()
    
    private let forwardButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .viewBackgroundColor
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.setImage(UIImage(nameInBundle: "forward_button_icon"), for: .normal)
        button.addTarget(self, action: #selector(forwardButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .viewBackgroundColor
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.setImage(UIImage(nameInBundle: "save_button_icon"), for: .normal)
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 48).isActive = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        return button
    }()
    
    @objc func forwardButtonTapped() {
        onButtonAction?(.forward)
        dismiss()
    }

    @objc func saveButtonTapped() {
        onButtonAction?(.save)
        dismiss()
    }
    
    private let forwardLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.text = "转发".innerLocalized()
        
        return label
    }()
    
    private let saveLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.text = "保存".innerLocalized()
        
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消".innerLocalized(), for: .normal)
        button.addTarget(self, action: #selector(handleCancelAction), for: .touchUpInside)
        
        return button
    }()
    
    @objc private func handleCancelAction() {
        dismiss()
    }
    
    private var isShowing = false

    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .black.withAlphaComponent(0.6)
        alpha = 0

        let buttonStackView1 = UIStackView(arrangedSubviews: [forwardButton, forwardLabel])
        buttonStackView1.axis = .vertical
        buttonStackView1.alignment = .center
        buttonStackView1.spacing = 4
        
        let buttonStackView2 = UIStackView(arrangedSubviews: [saveButton, saveLabel])
        buttonStackView2.axis = .vertical
        buttonStackView2.alignment = .center
        buttonStackView2.spacing = 4
        
        let mainStackView = UIStackView(arrangedSubviews: [UIView(), buttonStackView1, UIView(), buttonStackView2, UIView()])
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.distribution = .fillEqually
        
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            let bottom = UIApplication.safeAreaInsets.bottom
            make.bottom.equalToSuperview().offset(130 + bottom)
            make.height.equalTo(130 + bottom)
            make.leading.trailing.equalToSuperview()
        }
        
        let verStackView = UIStackView(arrangedSubviews: [mainStackView, separatorView, cancelButton])
        verStackView.axis = .vertical
        verStackView.spacing = 8
        
        contentView.addSubview(verStackView)
        verStackView.snp.makeConstraints { make in
            let bottom = UIApplication.safeAreaInsets.bottom
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(bottom)
        }
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    
    @objc
    private func handleTap(_ sender: UITapGestureRecognizer) {
        dismiss()
    }

    func show() {
        let keyWindow = UIApplication.shared.keyWindow()
        
        if keyWindow?.contains(self) == false {
            UIApplication.shared.keyWindow()?.addSubview(self)
            
            snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            layoutIfNeeded()
        }
        
        guard !isShowing else { return }
        isShowing = true
        
        UIView.animate(withDuration: 0.3) { [self] in
            contentView.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
            alpha = 1.0
            layoutIfNeeded()
        }
    }

    func dismiss() {
        guard isShowing else { return }
        isShowing = false
        
        contentView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(130 + safeAreaInsets.bottom)
        }

        UIView.animate(withDuration: 0.3) { [self] in
            alpha = 0.0
            layoutIfNeeded()
        } completion: { [self] finished in
            if finished {
                removeFromSuperview()
            }
        }
    }
}
