


























import UIKit

open class InputBarSendButton: InputBarButtonItem {

    open private(set) var isAnimating: Bool = false

    open var activityViewColor: UIColor! {
        get {
            return activityView.color
        }
        set {
            activityView.color = newValue
        }
    }

    private let activityView: UIActivityIndicatorView = {
        let view: UIActivityIndicatorView
        
        if #available(iOS 13.0, *) {
            view = UIActivityIndicatorView(style: .medium)
        } else {
            view = UIActivityIndicatorView(style: .gray)
        }
        
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSendButton()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSendButton()
    }

    private func setupSendButton() {
        addSubview(activityView)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        activityView.frame = bounds
    }

    open func startAnimating() {
        guard !isAnimating else { return }
        defer { isAnimating = true }
        activityView.startAnimating()
        activityView.isHidden = false

        titleLabel?.alpha = 0
        imageView?.layer.transform = CATransform3DMakeScale(0.0, 0.0, 0.0)
    }

    open func stopAnimating() {
        guard isAnimating else { return }
        defer { isAnimating = false }
        activityView.stopAnimating()
        activityView.isHidden = true
        titleLabel?.alpha = 1
        imageView?.layer.transform = CATransform3DIdentity
    }

}
