
import RxSwift
import SnapKit
import UIKit

open class OptionTableViewCell: UITableViewCell {
    public var disposeBag = DisposeBag()

    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        
        return v
    }()

    public let subtitleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        v.textAlignment = .right
        
        return v
    }()
    
    public let switcher: UISwitch = {
        let v = UISwitch()
        v.isOn = false
        v.isHidden = true
        
        return v
    }()
    
    public let spacer = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        selectionStyle = .none
        
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let row = UIStackView(arrangedSubviews: [titleLabel, spacer, subtitleLabel, switcher])
        row.spacing = 8
        row.alignment = .center
        contentView.addSubview(row)
            
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        row.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    @available(*, unavailable)
    required public init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        accessoryType = .disclosureIndicator
        subtitleLabel.text = nil
        titleLabel.text = nil
        titleLabel.isHidden = false
        titleLabel.textColor = UIColor.c0C1C33
        disposeBag = DisposeBag()
        switcher.isHidden = true
    }
}
