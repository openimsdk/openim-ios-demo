
import OUICore

class MultipleTextLineCell: UITableViewCell {
    
    lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.f17
        v.textColor = UIColor.c0C1C33
        
        return v
    }()
    
    lazy var colum: UIStackView = {
        let v = UIStackView(arrangedSubviews: [titleLabel])
        v.axis = .vertical
        v.spacing = 6
        v.alignment = .leading
        
        return v
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        contentView.addSubview(colum)
        colum.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(title: String?, value: String?) {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.c8E9AB0
        titleLabel.text = title
        
        let valueLabel = UILabel()
        valueLabel.textColor = UIColor.c0C1C33
        valueLabel.text = value
        
        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.spacing = 8
        row.alignment = .leading
        
        colum.addArrangedSubview(row)
    }
    
    func reset() {
        let views = colum.arrangedSubviews
        for (_, item) in views.enumerated() {
            
            if item != titleLabel {
                colum.removeArrangedSubview(item)
            }
        }
        
        let subviews = colum.subviews
        
        for (_, item) in subviews.enumerated() {
            
            if item != titleLabel {
                item.removeFromSuperview()
            }
        }
    }
}
