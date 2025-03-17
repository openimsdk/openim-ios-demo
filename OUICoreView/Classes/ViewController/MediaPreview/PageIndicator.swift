
import Lantern
import SnapKit

class PageIndicator: UIView, LanternPageIndicator {
    
    var onDelete: ((Int) -> Void)?
    
    private lazy var numberLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 17)
        v.textAlignment = .center
        v.textColor = UIColor.white
        v.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        v.layer.masksToBounds = true
        
        return v
    }()
    
    lazy var deleteButton: UIButton = {
        let v = UIButton(type: .system)
        v.tintColor = .white
        v.setTitle("删除".innerLocalized(), for: .normal)
        v.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
        v.isHidden = true
        
        return v
    }()
    
    @objc
    private func deleteButtonAction() {
        onDelete?(index)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupSubviews() {
        addSubview(numberLabel)
        numberLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
        }
        
        addSubview(deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
    }
    
    public func setup(with lantern: Lantern) {
        snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
    }
    
    private var total: Int = 0
    private var index: Int = 0
    
    public func reloadData(numberOfItems: Int, pageIndex: Int) {
        total = numberOfItems
        index = pageIndex
        
        numberLabel.text = "\(pageIndex + 1) / \(total)"
        isHidden = numberOfItems <= 1
    }
    
    public func didChanged(pageIndex: Int) {
        numberLabel.text = "\(pageIndex + 1) / \(total)"
    }
}
