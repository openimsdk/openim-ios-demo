import InputBarAccessoryView
import OUICore

public enum PadItemType: CaseIterable {
    case album
    case media

    var name: String {
        switch self {
        case .album:
            return "toolboxAlbum".innerLocalized()
        case .media:
            return "toolboxCall".innerLocalized()
        }
    }

    var image: UIImage? {
        let imageName: String
        switch self {
        case .album:
            imageName = "inputbar_pad_album_icon"
        case .media:
            imageName = "inputbar_pad_voip_icon"
        }
        return UIImage(nameInBundle: imageName)
    }
}

public protocol InputPadViewDelegate: AnyObject {
    func didSelect(type: PadItemType)
}

class InputPadView: UIView {

    private var size: CGSize? = CGSize(width: UIScreen.main.bounds.width, height: 220) {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        size ?? super.intrinsicContentSize
    }
    
    public weak var delegate: InputPadViewDelegate?

    private let itemsPerRow = 4
    private let items: [PadItemType] = PadItemType.allCases
    
    private lazy var collectionView: UICollectionView = {
        
        var layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 10.0
        
        layout.itemSize = CGSize(width: (intrinsicContentSize.width - layout.minimumInteritemSpacing * 3) / CGFloat(itemsPerRow), height: (intrinsicContentSize.height - layout.minimumLineSpacing) / 2.0)
        
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.register(ItemCell.self, forCellWithReuseIdentifier: ItemCell.className)
        v.backgroundColor = .clear
        v.isScrollEnabled = false
        v.dataSource = self
        v.delegate = self
        
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        translatesAutoresizingMaskIntoConstraints = false
        layoutMargins = .zero
        
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ItemCell: UICollectionViewCell {
    let imageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = .c0C1C33
        
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let vStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [imageView, titleLabel])
            v.axis = .vertical
            v.alignment = .center
            v.spacing = 8
            
            return v
        }()
        
        contentView.addSubview(vStack)
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            vStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension InputPadView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
    
        let count = items.count
        
        return count % itemsPerRow == 0 ? count / itemsPerRow : count / itemsPerRow + 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        let count = items.count - section * itemsPerRow

        return count / itemsPerRow == 0 ? count % itemsPerRow : itemsPerRow
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemCell.className, for: indexPath) as! ItemCell
        
        let index = indexPath.section * itemsPerRow + indexPath.row
        let item = items[index]

        cell.imageView.image = item.image
        cell.titleLabel.text = item.name
        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.section * itemsPerRow + indexPath.row
        let item = items[index]
        delegate?.didSelect(type: item)
    }
}
