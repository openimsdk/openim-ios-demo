
import RxSwift
import OUICore

class SingleChatMemberTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()

    lazy var memberCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 50, height: 80)
        layout.scrollDirection = .horizontal
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        v.register(MemberCell.self, forCellWithReuseIdentifier: MemberCell.className)
        v.backgroundColor = .clear
        
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .tertiarySystemBackground
        
        contentView.addSubview(memberCollectionView)
        memberCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(90)
            make.bottom.equalToSuperview().offset(-10).priority(.low)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    class MemberCell: UICollectionViewCell {
        let avatarView = AvatarView()

        let nameLabel: UILabel = {
            let v = UILabel()
            v.font = .f14
            v.textColor = .c8E9AB0
            v.textAlignment = .center
            
            return v
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            contentView.addSubview(avatarView)
            avatarView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
            }

            contentView.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                make.top.equalTo(avatarView.snp.bottom).offset(4)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().priority(.low)
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
