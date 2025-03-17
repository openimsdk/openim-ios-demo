
import OUICore
import RxSwift

public class ShowSelectedTableViewCell: UITableViewCell {
    let disposeBag = DisposeBag()

    var onTap: (() -> Void)?
    
    public let avatarView: AvatarView = {
        let v = AvatarView()
        return v
    }()

    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        return v
    }()

    let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = .f12
        v.textColor = .c0C1C33
        return v
    }()
    
    lazy var trainingButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle(" \("remove".innerLocalized()) ", for: .normal)
        v.layer.borderColor = UIColor.systemBlue.cgColor
        v.layer.borderWidth = 1
        v.layer.cornerRadius = 2
        v.layer.masksToBounds = true
        v.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            
            onTap?()
        }).disposed(by: disposeBag)
        return v
    }()
    
    let rowStack: UIStackView = {
        let v = UIStackView.init(arrangedSubviews: [SizeBox(width: 8)]);
        v.spacing = 8
        v.alignment = .center
        
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        let textStack: UIStackView = {
            let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
            v.axis = .vertical
            v.spacing = 4
            v.alignment = .leading
            return v
        }()

        trainingButton.snp.makeConstraints { make in
            make.width.equalTo(44)
        }
        
        rowStack.addArrangedSubview(avatarView)
        rowStack.addArrangedSubview(textStack)
        rowStack.addArrangedSubview(trainingButton)
        rowStack.addArrangedSubview(SizeBox(width: 16))
        contentView.addSubview(rowStack)
        
        rowStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
    
    private func reset() {
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
}
