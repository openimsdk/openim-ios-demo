import UIKit
import Foundation

extension AlertAction {
    public enum Style : Int, @unchecked Sendable {
        case `default` = 0
        case cancel = 1
        case destructive = 2
    }
    
    public enum Alignment: Int {
        case center = 0
        case left = 1
    }
}

extension AlertViewController {
    public enum Style : Int, @unchecked Sendable {
        case actionSheet = 0
        case alert = 1
    }
}

@MainActor public class AlertAction : UIView {

    public init(title: String?, image: UIImage? = nil, style: AlertAction.Style = .default, alignment: AlertAction.Alignment = .center, handler: ((AlertAction) -> Void)? = nil) {
        super.init(frame: .zero)
        
        self.title = title
        self.image = image
        self.style = style
        self.alignment = alignment
        self.onAction = handler
        
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public private(set) var style: AlertAction.Style!
    
    fileprivate var onActionForController: ((AlertAction) -> Void)?
    private var alignment: AlertAction.Alignment = .center
    
    private var title: String?
    private var image: UIImage?
    private var onAction: ((AlertAction) -> Void)?
    
    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleButtonAction(_:)), for: .touchUpInside)
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        let spacing = 8.0
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)
        
        switch style {
        case .default:
            button.setTitleColor(.black, for: .normal)
            button.tintColor = .black
        case .cancel:
            button.setTitleColor(.black, for: .normal)
            button.tintColor = .black
        case .destructive:
            button.setTitleColor(.red, for: .normal)
            button.tintColor = .red
        default:
            break
        }
        
        if alignment == .left {
            button.contentHorizontalAlignment = .left
        }
        
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    @objc private func handleButtonAction(_ sender: UIButton) {
        onActionForController?(self)
        onAction?(self)
    }
}

@MainActor public class AlertViewController : UIViewController {
    
    public init(message: String? = nil, preferredStyle: AlertViewController.Style = .alert) {
        super.init(nibName: nil, bundle: nil)
        
        self.message = message
        self.preferredStyle = preferredStyle
        modalPresentationStyle = .overCurrentContext
        definesPresentationContext = true
        modalTransitionStyle = preferredStyle == .alert ? .crossDissolve : .coverVertical
    }
    
    public func addAction(_ action: AlertAction) {
        action.translatesAutoresizingMaskIntoConstraints = false
        action.heightAnchor.constraint(equalToConstant: preferredStyle == .actionSheet ? 56 : 48).isActive = true
       
        action.onActionForController = { [weak self] _ in
            self?.dismiss()
        }
        actions.append(action)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var message: String?
    private var preferredStyle: AlertViewController.Style!
    private var actions: [AlertAction] = []
    
    private let contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .tertiarySystemBackground
        v.layer.cornerRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private let actionsStack: UIStackView = {
        let v = UIStackView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.distribution = .fillProportionally
        
        return v
    }()
    
    private let messageLabel: UILabel = {
        let v = UILabel()
        v.textAlignment = .center
        v.numberOfLines = 0
        v.font = .systemFont(ofSize: 17)
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.6)

        view.addSubview(contentView)
        
        if preferredStyle == .alert {
            setupAlertStyle()
        } else {
            setupActionSheetStyle()
        }
        
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    private func setupAlertStyle() {
        contentView.backgroundColor = .tertiarySystemBackground
        
        messageLabel.text = message
        contentView.addSubview(messageLabel)
        
        let horLine = UIView()
        horLine.backgroundColor = .systemGray5
        horLine.translatesAutoresizingMaskIntoConstraints = false
        horLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentView.addSubview(horLine)
        
        contentView.addSubview(actionsStack)
        actionsStack.distribution = .fill
        
        let contentWidth = 280.0
        let itemWidth = (contentWidth - CGFloat(actions.count - 1) * 1.0) / CGFloat(actions.count)
        
        for (i, item) in actions.enumerated() {
            actionsStack.addArrangedSubview(item)
            item.widthAnchor.constraint(equalToConstant: itemWidth).isActive = true
            
            if i < actions.count - 1 {
                let line = UIView()
                line.backgroundColor = .systemGray5
                actionsStack.addArrangedSubview(line)
                line.widthAnchor.constraint(equalToConstant: 1).isActive = true
            }
        }
        
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: contentWidth),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 112),
            contentView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            messageLabel.bottomAnchor.constraint(equalTo: horLine.topAnchor, constant: -16),
            messageLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
            
            horLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            horLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            horLine.bottomAnchor.constraint(equalTo: actionsStack.topAnchor),

            actionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    private func setupActionSheetStyle() {
        contentView.backgroundColor = .clear
        actionsStack.axis = .vertical
        contentView.addSubview(actionsStack)
        actionsStack.backgroundColor = .clear

        if let index  = actions.firstIndex(where: { $0.style == .cancel }) {
            let action = actions[index]
            
            actions.remove(at: index)
            actions.append(action)
        }
        
        let defaultActionsStack = UIStackView()
        defaultActionsStack.backgroundColor = .tertiarySystemBackground
        defaultActionsStack.axis = .vertical
        defaultActionsStack.layer.cornerRadius = 6
        defaultActionsStack.layer.masksToBounds = true
        defaultActionsStack.translatesAutoresizingMaskIntoConstraints = false
        
        if let message {
            messageLabel.text = message
            defaultActionsStack.addArrangedSubview(messageLabel)
        }
        
        for (i, item) in actions.enumerated() {
            if item.style == .cancel {
                actionsStack.addArrangedSubview(defaultActionsStack)
                
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
                actionsStack.addArrangedSubview(spacer)
                
                item.backgroundColor = .tertiarySystemBackground
                item.layer.cornerRadius = 6
                actionsStack.addArrangedSubview(item)
            } else {
                if i < actions.count - 1 {
                    defaultActionsStack.addArrangedSubview(item)
                    
                    let line = UIView()
                    line.backgroundColor = .systemGray5
                    line.translatesAutoresizingMaskIntoConstraints = false
                    defaultActionsStack.addArrangedSubview(line)
                    line.heightAnchor.constraint(equalToConstant: 1).isActive = true
                }
            }
        }
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            actionsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionsStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            actionsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        dismiss()
    }
    
    private func dismiss() {
        dismiss(animated: true)
    }
    
    deinit {
        print("\(#function) - \(type(of: self))")
    }
}

