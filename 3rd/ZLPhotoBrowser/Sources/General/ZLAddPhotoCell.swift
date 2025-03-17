

























import UIKit
import Foundation

class ZLAddPhotoCell: UICollectionViewCell {
    private lazy var imageView: UIImageView = {
        let view = UIImageView(image: .zl.getImage("zl_addPhoto"))
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    deinit {
        zl_debugPrint("ZLAddPhotoCell deinit")
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = CGRect(x: 0, y: 0, width: bounds.width / 3, height: bounds.width / 3)
        imageView.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func setupUI() {
        if ZLPhotoUIConfiguration.default().cellCornerRadio > 0 {
            layer.masksToBounds = true
            layer.cornerRadius = ZLPhotoUIConfiguration.default().cellCornerRadio
        }
        
        backgroundColor = .zl.cameraCellBgColor
        contentView.addSubview(imageView)
    }
}
