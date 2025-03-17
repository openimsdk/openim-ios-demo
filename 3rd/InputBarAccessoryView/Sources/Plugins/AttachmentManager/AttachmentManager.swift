


























import UIKit

open class AttachmentManager: NSObject, InputPlugin {
    
    public enum Attachment {
        case image(UIImage)
        case url(URL)
        case data(Data)
        
        @available(*, deprecated, message: ".other(AnyObject) has been depricated as of 2.0.0")
        case other(AnyObject)
    }


    open weak var delegate: AttachmentManagerDelegate?

    open weak var dataSource: AttachmentManagerDataSource?
    
    open lazy var attachmentView: AttachmentCollectionView = { [weak self] in
        let attachmentView = AttachmentCollectionView()
        attachmentView.dataSource = self
        attachmentView.delegate = self
        return attachmentView
    }()

    private(set) public var attachments = [Attachment]() { didSet { reloadData() } }

    open var isPersistent = false { didSet { attachmentView.reloadData() } }

    open var showAddAttachmentCell = true { didSet { attachmentView.reloadData() } }

    open var tintColor: UIColor {
        if #available(iOS 13, *) {
            return .link
        } else {
            return .systemBlue
        }
    }

    
    public override init() {
        super.init()
    }

    
    open func reloadData() {
        attachmentView.reloadData()
        delegate?.attachmentManager(self, didReloadTo: attachments)
        delegate?.attachmentManager(self, shouldBecomeVisible: attachments.count > 0 || isPersistent)
    }

    open func invalidate() {
        attachments = []
    }



    @discardableResult
    open func handleInput(of object: AnyObject) -> Bool {
        let attachment: Attachment
        if let image = object as? UIImage {
            attachment = .image(image)
        } else if let url = object as? URL {
            attachment = .url(url)
        } else if let data = object as? Data {
            attachment = .data(data)
        } else {
            return false
        }
        
        insertAttachment(attachment, at: attachments.count)
        return true
    }




    open func insertAttachment(_ attachment: Attachment, at index: Int) {
        
        attachmentView.performBatchUpdates({
            self.attachments.insert(attachment, at: index)
            self.attachmentView.insertItems(at: [IndexPath(row: index, section: 0)])
        }, completion: { success in
            self.attachmentView.reloadData()
            self.delegate?.attachmentManager(self, didInsert: attachment, at: index)
            self.delegate?.attachmentManager(self, shouldBecomeVisible: self.attachments.count > 0 || self.isPersistent)
        })
    }



    open func removeAttachment(at index: Int) {
        
        let attachment = attachments[index]
        attachmentView.performBatchUpdates({
            self.attachments.remove(at: index)
            self.attachmentView.deleteItems(at: [IndexPath(row: index, section: 0)])
        }, completion: { success in
            self.attachmentView.reloadData()
            self.delegate?.attachmentManager(self, didRemove: attachment, at: index)
            self.delegate?.attachmentManager(self, shouldBecomeVisible: self.attachments.count > 0 || self.isPersistent)
        })
    }
    
}

extension AttachmentManager: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    
    final public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == attachments.count {
            delegate?.attachmentManager(self, didSelectAddAttachmentAt: indexPath.row)
            delegate?.attachmentManager(self, shouldBecomeVisible: attachments.count > 0 || isPersistent)
        }
    }

    
    final public func numberOfItems(inSection section: Int) -> Int {
        return 1
    }
    
    final public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count + (showAddAttachmentCell ? 1 : 0)
    }
    
    final public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == attachments.count && showAddAttachmentCell {
            return createAttachmentCell(in: collectionView, at: indexPath)
        }
        
        let attachment = attachments[indexPath.row]
        
        if let cell = dataSource?.attachmentManager(self, cellFor: attachment, at: indexPath.row) {
            return cell
        } else {

            switch attachment {
            case .image(let image):
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageAttachmentCell.reuseIdentifier, for: indexPath) as? ImageAttachmentCell else {
                    fatalError()
                }
                cell.attachment = attachment
                cell.indexPath = indexPath
                cell.manager = self
                cell.imageView.image = image
                cell.imageView.tintColor = tintColor
                cell.deleteButton.backgroundColor = tintColor
                return cell
            default:
                return collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCell.reuseIdentifier, for: indexPath) as! AttachmentCell
            }
            
        }
    }

    
    final public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height = attachmentView.intrinsicContentHeight
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            height -= (layout.sectionInset.bottom + layout.sectionInset.top + collectionView.contentInset.top + collectionView.contentInset.bottom)
        }

        if indexPath.row == attachments.count && showAddAttachmentCell {
            return CGSize(width: height, height: height)
        }
        
        let attachment = self.attachments[indexPath.row]
        if let customSize = self.dataSource?.attachmentManager(self, sizeFor: attachment, at: indexPath.row){
            return customSize
        }
        
        return CGSize(width: height, height: height)
    }
    
    @objc open func createAttachmentCell(in collectionView: UICollectionView, at indexPath: IndexPath) -> AttachmentCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCell.reuseIdentifier, for: indexPath) as? AttachmentCell else {
            fatalError()
        }
        cell.deleteButton.isHidden = true

        let frame = CGRect(origin: CGPoint(x: cell.bounds.origin.x,
                                           y: cell.bounds.origin.y),
                           size: CGSize(width: cell.bounds.width - cell.padding.left - cell.padding.right,
                                        height: cell.bounds.height - cell.padding.top - cell.padding.bottom))
        let strokeWidth: CGFloat = 3
        let length: CGFloat = frame.width / 2
        let grayColor: UIColor
        if #available(iOS 13, *) {
            grayColor = .systemGray2
        } else {
            grayColor = .lightGray
        }
        let vLayer = CAShapeLayer()
        vLayer.path = UIBezierPath(roundedRect: CGRect(x: frame.midX - (strokeWidth / 2),
                                                       y: frame.midY - (length / 2),
                                                       width: strokeWidth,
                                                       height: length), cornerRadius: 5).cgPath
        vLayer.fillColor = grayColor.cgColor
        let hLayer = CAShapeLayer()
        hLayer.path = UIBezierPath(roundedRect: CGRect(x: frame.midX - (length / 2),
                                                       y: frame.midY - (strokeWidth / 2),
                                                       width: length,
                                                       height: strokeWidth), cornerRadius: 5).cgPath
        hLayer.fillColor = grayColor.cgColor
        cell.containerView.layer.addSublayer(vLayer)
        cell.containerView.layer.addSublayer(hLayer)
        return cell
    }
}
