
import UIKit
import OUICore
import RxSwift

fileprivate enum CellType {
    case horizontal
    case vertical
}

fileprivate class UserCell: UICollectionViewCell {
    
    lazy var avatarView = AvatarView()

    lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        
        return v
    }()
    
    private lazy var stack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [avatarView, titleLabel])
        v.spacing = 8
        v.alignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    var type: CellType = .horizontal {
        didSet {
            if type == .horizontal {
                stack.axis = .horizontal
            } else {
                stack.axis = .vertical
            }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ForwardCard: UIView {
    private let disposeBag = DisposeBag()
    
    var numberOfItems: (() -> Int)!
    var itemForIndex:((Int) -> User)!
    var confirmHandler:((String?) -> Void)?
    var cancelHandler: (() -> Void)?
    
    func reloadData() {
        let count = numberOfItems()
        collectionViewHeight?.constant = count == 1 ? 50 : (count <= 5 ? 70 : 120)
        collectionViewHeight!.isActive = true
        collectionView.reloadData()
    }
    
    private lazy var titleLable: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        v.text = " " + "发送给：".innerLocalized()
        
        return v
    }()
    
    lazy var contentLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c8E9AB0
        v.text = "chatRecord".innerLocalized()
        
        return v
    }()
    
    private lazy var cancelButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("cancel".innerLocalized(), for: .normal)
        v.setTitleColor(.black, for: .normal)
        
        v.rx.tap.subscribe { [weak self] _ in
            self?.cancelHandler?()
        }.disposed(by: disposeBag)
        return v
    }()
    
    private lazy var confirmButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("determine".innerLocalized(), for: .normal)
        v.setTitleColor(UIColor.c0089FF, for: .normal)
        v.rx.tap.subscribe { [weak self] _ in
            self?.confirmHandler?(nil)
        }.disposed(by: disposeBag)
        
        return v
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.register(UserCell.self, forCellWithReuseIdentifier: NSStringFromClass(UserCell.self))
        v.delegate = self
        v.dataSource = self
        
        return v
    }()
    
    lazy var contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .tertiarySystemBackground
        v.layer.masksToBounds = true
        v.layer.cornerRadius = StandardUI.cornerRadius
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    private var collectionViewHeight: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black.withAlphaComponent(0.6)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        let contentView = UIView()
        contentView.backgroundColor = .tertiarySystemBackground
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = StandardUI.cornerRadius
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(contentView)
        
        let buttonStack = UIStackView(arrangedSubviews: [UIView(), cancelButton, confirmButton])
        buttonStack.alignment = .center
        buttonStack.spacing = 24
        
        let HStack = UIStackView(arrangedSubviews: [titleLable, collectionView, contentLabel, buttonStack])
        HStack.axis = .vertical
        HStack.spacing = 8
        HStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(HStack)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor, constant: 38),
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -80),
            
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            confirmButton.heightAnchor.constraint(equalToConstant: 44),
            
            HStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            HStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            HStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            HStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
        
        collectionViewHeight = collectionView.heightAnchor.constraint(equalToConstant: 150)
        collectionViewHeight!.priority = .defaultHigh
        
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    
    @objc
    private func handleTap(_ sender: UITapGestureRecognizer) {
        removeFromSuperview()
    }
}

extension ForwardCard: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = numberOfItems()
        return numberOfItems()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UserCell.self), for: indexPath) as! UserCell
        
        let item = itemForIndex(indexPath.item)
        
        cell.titleLabel.text = item.name
        cell.avatarView.setAvatar(url: item.faceURL, text: item.name)
        cell.type = numberOfItems() > 1 ? .vertical : .horizontal
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView.numberOfItems(inSection: section) == 1 {
            let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: collectionView.frame.width - 150)
        }

        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return numberOfItems() == 1 ? CGSize(width: 150, height: 50) : CGSize(width: 42, height: 70)
    }
}

