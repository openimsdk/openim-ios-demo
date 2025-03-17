
import RxSwift
import UIKit

public class SwitchTableViewCell: UITableViewCell {
    public var disposeBag = DisposeBag()
    
    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        
        return v
    }()
    
    public let subTitleLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        v.textColor = .c8E9AB0
        
        return v
    }()

    public let switcher: UISwitch = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        
        contentView.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }

        contentView.addSubview(switcher)
        switcher.snp.makeConstraints { make in
            make.leading.equalTo(vStack.snp.trailing)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        subTitleLabel.text = nil
        titleLabel.textColor = .c0C1C33
        disposeBag = DisposeBag()
    }
}
