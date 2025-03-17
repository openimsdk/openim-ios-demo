

























import UIKit

class ZLAlbumListCell: UITableViewCell {
    private lazy var coverImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        if ZLPhotoUIConfiguration.default().cellCornerRadio > 0 {
            view.layer.masksToBounds = true
            view.layer.cornerRadius = ZLPhotoUIConfiguration.default().cellCornerRadio
        }
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 17)
        label.textColor = .zl.albumListTitleColor
        return label
    }()
    
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = .zl.font(ofSize: 16)
        label.textColor = .zl.albumListCountColor
        return label
    }()
    
    private var imageIdentifier: String?
    
    private var model: ZLAlbumListModel!
    
    private var style: ZLPhotoBrowserStyle = .embedAlbumList
    
    private var indicator: UIImageView = {
        var image = UIImage.zl.getImage("zl_ablumList_arrow")
        if isRTL() {
            image = image?.imageFlippedForRightToLeftLayoutDirection()
        }
        
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var selectBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.isUserInteractionEnabled = false
        btn.isHidden = true
        btn.setImage(.zl.getImage("zl_albumSelect"), for: .selected)
        return btn
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = contentView.zl.width
        let height = contentView.zl.height
        
        let coverImageW = height - 4
        let maxTitleW = width - coverImageW - 80
        
        var titleW: CGFloat = 0
        var countW: CGFloat = 0
        if let model = model {
            titleW = min(
                bounds.width / 3 * 2,
                model.title.zl.boundingRect(
                    font: .zl.font(ofSize: 17),
                    limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)
                ).width
            )
            titleW = min(titleW, maxTitleW)
            
            countW = ("(" + String(model.count) + ")").zl
                .boundingRect(
                    font: .zl.font(ofSize: 16),
                    limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)
                ).width
        }
        
        if isRTL() {
            let imageViewX: CGFloat
            if style == .embedAlbumList {
                imageViewX = width - coverImageW
            } else {
                imageViewX = width - coverImageW - 12
            }
            
            coverImageView.frame = CGRect(x: imageViewX, y: 2, width: coverImageW, height: coverImageW)
            titleLabel.frame = CGRect(
                x: coverImageView.zl.left - titleW - 10,
                y: (height - 30) / 2,
                width: titleW,
                height: 30
            )
            
            countLabel.frame = CGRect(
                x: titleLabel.zl.left - countW - 10,
                y: (height - 30) / 2,
                width: countW,
                height: 30
            )
            selectBtn.frame = CGRect(x: 20, y: (height - 20) / 2, width: 20, height: 20)
            indicator.frame = CGRect(x: 20, y: (bounds.height - 15) / 2, width: 15, height: 15)
            return
        }
        
        let imageViewX: CGFloat
        if style == .embedAlbumList {
            imageViewX = 0
        } else {
            imageViewX = 12
        }
        
        coverImageView.frame = CGRect(x: imageViewX, y: 2, width: coverImageW, height: coverImageW)
        titleLabel.frame = CGRect(
            x: coverImageView.zl.right + 10,
            y: (bounds.height - 30) / 2,
            width: titleW,
            height: 30
        )
        countLabel.frame = CGRect(x: titleLabel.zl.right + 10, y: (height - 30) / 2, width: countW, height: 30)
        selectBtn.frame = CGRect(x: width - 20 - 20, y: (height - 20) / 2, width: 20, height: 20)
        indicator.frame = CGRect(x: width - 20 - 15, y: (height - 15) / 2, width: 15, height: 15)
    }
    
    func setupUI() {
        backgroundColor = .zl.albumListBgColor
        selectionStyle = .none
        accessoryType = .none
        
        contentView.addSubview(coverImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(selectBtn)
        contentView.addSubview(indicator)
    }
    
    func configureCell(model: ZLAlbumListModel, style: ZLPhotoBrowserStyle) {
        self.model = model
        self.style = style
        
        titleLabel.text = self.model.title
        countLabel.text = "(" + String(self.model.count) + ")"
        
        if style == .embedAlbumList {
            selectBtn.isHidden = false
            indicator.isHidden = true
        } else {
            indicator.isHidden = false
            selectBtn.isHidden = true
        }
        
        imageIdentifier = self.model.headImageAsset?.localIdentifier
        if let asset = self.model.headImageAsset {
            let w = bounds.height * 2.5
            ZLPhotoManager.fetchImage(for: asset, size: CGSize(width: w, height: w)) { [weak self] image, _ in
                if self?.imageIdentifier == self?.model.headImageAsset?.localIdentifier {
                    self?.coverImageView.image = image ?? .zl.getImage("zl_defaultphoto")
                }
            }
        }
    }
}
