
import OUICore

public class PopoverCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    public struct MenuItem {
        let title: String
        let image: UIImage?
        let action: () -> Void
        
        public init(title: String, image: UIImage?, action: @escaping () -> Void) {
            self.title = title
            self.image = image
            self.action = action
        }
    }
    
    public var onDismiss: (() -> Void)?
    
    public func show<T>(in baseController: T, sender: UIView? = nil, point: CGPoint = .zero, itemSender: UIBarButtonItem? = nil, passthroughViews: [UIView]? = nil) where T: UIViewController {
        assert(sender != nil || itemSender != nil)
        DispatchQueue.main.async { [self] in
            self.baseController = baseController.navigationController ?? baseController
            
            dismiss()
            
            self.modalPresentationStyle = .popover
            let popoverPresentationController = self.popoverPresentationController
            popoverPresentationController?.delegate = self
            popoverPresentationController?.backgroundColor = .c0C1C33.withAlphaComponent(0.85)
            popoverPresentationController?.passthroughViews = passthroughViews

            
            if let sender {
                let senderRect = sender.convert(sender.frame, to: baseController.view)
                let senderMaxY = senderRect.maxY
                let senderMinY = senderRect.minY
                let viewBottom = baseController.view.frame.maxY
                let distanceToBottom = viewBottom - senderMaxY
                let useSenderBounds = distanceToBottom > 100 || (senderMinY < viewBottom && senderMinY > 100)
                
                if useSenderBounds {
                    popoverPresentationController?.permittedArrowDirections = senderMinY < baseController.view.frame.midY ? [.up] : [.down]
                } else {
                    popoverPresentationController?.permittedArrowDirections = [.up, .down]
                }

                if UIScreen.main.bounds.height < sender.frame.height {
                    popoverPresentationController?.sourceRect = useSenderBounds ? sender.bounds : CGRect(origin: point, size: CGSize(width: 1, height: 1))
                } else {
                    popoverPresentationController?.sourceRect = sender.bounds
                }
                popoverPresentationController?.sourceView = sender
                popoverPresentationController?.canOverlapSourceViewRect = true
            } else {
                popoverPresentationController?.permittedArrowDirections = [.up, .down]
                popoverPresentationController?.barButtonItem = itemSender
            }
            view.backgroundColor = .c0C1C33.withAlphaComponent(0.85)
            
            self.baseController?.present(self, animated: true, completion: nil)
        }
    }
    
    public func dismiss() -> Bool {
        if self.baseController?.presentedViewController != nil {
            self.baseController?.dismiss(animated: false)
            
            return true
        }
        
        return false
    }
    
    public init(items: [MenuItem] = []) {
        super.init(nibName: nil, bundle: nil)
        self.items = items
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var items: [MenuItem] = [] {
        didSet {
            let width = min(items.count, 5) * Int(itemSize.width)
            let height = max(items.count / 5, 1) * Int(itemSize.height + itemSpacing)
            
            preferredContentSize = CGSize(width: width, height: height)
            collectionView.reloadData()
        }
    }
    
    private let itemSize = CGSize(width: 35, height: 42)
    private let itemSpacing = 8.0
    private let elementsPerRow = 5
    private var baseController: UIViewController?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.dataSource = self
        v.delegate = self
        v.register(PopoverCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(PopoverCollectionViewCell.self))
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isScrollEnabled = false
        v.backgroundColor = .clear
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        
        return v
    }()
        
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.layer.masksToBounds = true
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: itemSpacing),
            collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: itemSpacing),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -itemSpacing),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -itemSpacing)
        ])
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let width = min(items.count, elementsPerRow) * Int(itemSize.width + 2 * itemSpacing)
        
        let numberOfRows = (items.count + elementsPerRow - 1) / elementsPerRow
        let height = numberOfRows * Int(itemSize.height + 2 * itemSpacing)

        preferredContentSize = CGSize(width: width, height: height)
    }

    public func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(PopoverCollectionViewCell.self), for: indexPath) as! PopoverCollectionViewCell
        
        let item = items[indexPath.item]
        cell.imageView.image = item.image
        cell.titleLabel.text = item.title
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        
        dismiss(animated: true) { [self] in
            item.action()
            onDismiss?()
        }
    }
}

private class PopoverCollectionViewCell: UICollectionViewCell {
    let imageView: UIImageView = {
        let v = UIImageView()
        
        return v
    }()

    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .systemFont(ofSize: 10)
        v.textColor = .white
        
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let vStack = UIStackView(arrangedSubviews: [imageView, titleLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.alignment = .center
        
        contentView.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PopoverCollectionViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
    
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        onDismiss?()

        return true
    }
}
