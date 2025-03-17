
import ChatLayout
import Foundation
import UIKit

final class EditingAccessoryView: UIView, StaticViewFactory {

    private lazy var button: UIButton = {
        let v = UIButton(type: .custom)
        v.setImage(UIImage(systemName: "circle"), for: .normal)
        v.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    private var controller: EditingAccessoryController?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        insetsLayoutMarginsFromSafeArea = false
        addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            button.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            button.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    func setup(with controller: EditingAccessoryController, isSelected: Bool, enableSelected: Bool = true) {
        self.controller = controller
        button.isSelected = isSelected
        button.isHidden = !enableSelected
    }
    
    func toggleState() {
        button.isSelected = !button.isSelected
    }

    @objc private func buttonTapped() {
        button.isSelected = !button.isSelected
        controller?.selectedMessageAction()
    }
}

extension EditingAccessoryView: EditNotifierDelegate {

    var isEditing: Bool {
        get {
            !isHidden
        }
        set {
            guard isHidden == newValue else {
                return
            }
            isHidden = !newValue
            alpha = newValue ? 1 : 0
        }
    }

    public func setIsEditing(_ isEditing: Bool = false, duration: ActionDuration = .notAnimated) {
        guard case let .animated(duration) = duration else {
            self.isEditing = isEditing
            return
        }

        UIView.animate(withDuration: duration) {
            self.isEditing = isEditing
            self.setNeedsLayout()
        }
    }

}
