import OUICore
import UIKit

class WatermarkCell: UICollectionViewCell {
    lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.textColor = .c707070.withAlphaComponent(0.25)
        v.font = .f17
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        titleLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-15 * Double.pi / 180))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WatermarkBackgroundView: UIView {
    
    let imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.masksToBounds = true
        
        return v
    }()
    
    var text: String? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    init(text: String? = nil) {
        super.init(frame: .zero)
        self.text = text
        
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        addSubview(imageView)
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 70
        layout.minimumInteritemSpacing = 60
        
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.register(WatermarkCell.self, forCellWithReuseIdentifier: WatermarkCell.className)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.delegate = self
        v.dataSource = self
        v.backgroundColor = .clear
        
        return v
    }()
}

extension WatermarkBackgroundView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 50
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WatermarkCell.className, for: indexPath) as! WatermarkCell
        
        cell.titleLabel.text = text
        
        return cell
    }
}
