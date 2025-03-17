
import Lantern

class ImageZoomCell: LanternImageCell {
    
    var frameChangedHandler: ((CGRect) -> Void)?
    var dismissHandler: (() -> Void)?
    
    lazy var closeButton: UIButton = {
        let v = UIButton(type: .system)
        v.setImage(UIImage(systemName: "xmark"), for: .normal)
        v.tintColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        v.addTarget(self, action: #selector(handleCloseAction(_:)), for: .touchUpInside)
        
        return v
    }()
    
    @objc
    private func handleCloseAction(_ sender: UIButton) {
        lantern?.dismiss()
        dismissHandler?()
    }
    
    required init(frame: CGRect) {
        super.init(frame: frame)
        
        scrollView.delaysContentTouches = false
        
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 64),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
        ])
    }
    
    private func hideWidgets(hidden: Bool = true) {
        UIView.animate(withDuration: 0.2) { [self] in
            closeButton.alpha = hidden ? 0.0 : 1.0
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func onSingleTap(_ tap: UITapGestureRecognizer) {
        super.onSingleTap(tap)
        dismissHandler?()
    }
    
    override func onPan(_ pan: UIPanGestureRecognizer) {
        super.onPan(pan)
        
        switch pan.state {
        case .changed:
            frameChangedHandler?(imageView.frame)
            
        case .ended, .cancelled:
            frameChangedHandler?(imageView.frame)
            let isDown = pan.velocity(in: self).y > 0
            if isDown {
                hideWidgets()
                dismissHandler?()
            }
        default:
            break
        }
    }
}
