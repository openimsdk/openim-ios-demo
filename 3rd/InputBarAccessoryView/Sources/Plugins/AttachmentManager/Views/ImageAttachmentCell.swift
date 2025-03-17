


























import UIKit

open class ImageAttachmentCell: AttachmentCell {

    
    override open class var reuseIdentifier: String {
        return "ImageAttachmentCell"
    }
    
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    
    private func setup() {
        containerView.addSubview(imageView)
        imageView.fillSuperview()
    }
}
