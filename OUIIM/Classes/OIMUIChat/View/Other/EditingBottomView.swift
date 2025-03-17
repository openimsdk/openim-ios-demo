
import ChatLayout
import Foundation
import UIKit
import OUICore

final class EditingBottomTipsView: UIView, StaticViewFactory {
    public lazy var tipsLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f14
        v.textColor = UIColor.c8E9AB0
        v.text = "notSendMessageNotInGroup".innerLocalized()

        return v
    }()
    
    lazy var tipsIcon: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "exclamationmark.shield"))
        v.tintColor = UIColor.c8E9AB0
        
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        backgroundColor = UIColor.cE8EAEF
        translatesAutoresizingMaskIntoConstraints = false
        
        let hStack = UIStackView(arrangedSubviews: [tipsIcon, tipsLabel])
        hStack.alignment = .center
        hStack.spacing = 8
        hStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hStack)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 64),
            hStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
