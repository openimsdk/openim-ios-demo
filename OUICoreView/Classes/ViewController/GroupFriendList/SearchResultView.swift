
import UIKit
import RxSwift
import SnapKit

public class SearchResultCell: UITableViewCell {
    public let titleLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0089FF
        
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .cellBackgroundColor
        
        let imageView: UIImageView = {
            let v = UIImageView(image: UIImage(nameInBundle: "contacts_search_result_icon"))
            v.setContentHuggingPriority(.required, for: .horizontal)
            v.setContentCompressionResistancePriority(.required, for: .horizontal)
            return v
        }()
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(6)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-18)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
