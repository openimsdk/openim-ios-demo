
import OUICore
import RxSwift

class GroupChatMemberTableViewCell: UITableViewCell {
        
    func reloadData() {
        let count = memberCollectionView.numberOfItems(inSection: 0)
        let totalAvatar = CGFloat(count) * StandardUI.avatarWidth
        let totalSpace = (count - 1) * 16
        
        if count > 3, totalAvatar + CGFloat(totalSpace) > memberCollectionView.bounds.width {
            memberCollectionView.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(150.h)
            }
        } else {
            memberCollectionView.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(70.h)
            }
        }
        memberCollectionView.reloadData()
    }
    
    var disposeBag = DisposeBag()
    let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = .c0C1C33
        
        return v
    }()

    let countLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = .c0C1C33
        
        return v
    }()

    lazy var memberCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: ImageCollectionViewCell.className)
        v.delegate = self
        v.backgroundColor = .clear
        
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    
        contentView.addSubview(memberCollectionView)
        memberCollectionView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(70.h)
        }
        
        let line = UIView()
        line.backgroundColor = .secondarySystemBackground
        
        contentView.addSubview(line)
        line.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.trailing.equalTo(memberCollectionView)
            make.top.equalTo(memberCollectionView.snp.bottom).offset(8)
        }
        
        let arrowImageView = UIImageView(image: UIImage(nameInBundle: "common_arrow_right"))

        let hStack = UIStackView(arrangedSubviews: [titleLabel, countLabel, UIView(), arrowImageView])
        hStack.alignment = .center
        
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(memberCollectionView)
            make.top.equalTo(line.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class ImageCollectionViewCell: UICollectionViewCell {
        
        let avatarView = AvatarView()
        
        let nameLabel: UILabel = {
            let v = UILabel()
            v.font = .f12
            v.textColor = .c8E9AB0
            
            return v
        }()
        
        let levelLabel: UILabel = {
            let v = UILabel()
            v.backgroundColor = .cE8EAEF
            v.textColor = .c6085B1
            v.font = .f12
            v.textAlignment = .center
            
            return v
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            
            let vStack = UIStackView(arrangedSubviews: [avatarView, nameLabel])
            vStack.axis = .vertical
            vStack.spacing = 4
            vStack.alignment = .center
            
            contentView.addSubview(vStack)
            vStack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            avatarView.addSubview(levelLabel)
            levelLabel.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalTo(avatarView)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            nameLabel.text = nil
            levelLabel.text = nil
            avatarView.reset()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
}

extension GroupChatMemberTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView.numberOfItems(inSection: section) == 1 {
            let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

            return UIEdgeInsets(top: 0, left: 8, bottom: 0, right: collectionView.frame.width - 150.w)
        }

        return UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.numberOfItems(inSection: 0) == 1 ? CGSize(width: 150.w, height: 70.h) : CGSize(width: StandardUI.avatarWidth, height: 70.h)
    }
}
