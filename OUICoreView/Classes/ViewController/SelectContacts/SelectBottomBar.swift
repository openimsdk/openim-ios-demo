import OUICore
import UIKit
import RxSwift

enum SelectBottomBarType {
    case selected
    case complete
}

public class SelectBottomBar: UIView {
    
    var maxCount: Int = 1000 {
        didSet {
            completeBtn.setTitle("confirmSelectedPeople".innerLocalizedFormat(arguments: "\(selectedCount)", "\(maxCount)"), for: .normal)
        }
    }
    
    var selectedCount: Int = 0 {
        didSet {
            completeBtn.isEnabled = selectedCount > 0
            completeBtn.setTitle("confirmSelectedPeople".innerLocalizedFormat(arguments: "\(selectedCount)", "\(maxCount)"), for: .normal)
            selectCountBtn.setTitle("selectedPeopleCount".innerLocalizedFormat(arguments: "\(selectedCount)"), for: .normal)
        }
    }
    
    var names: String = "" {
        didSet {
            namesLabel.text = names
        }
    }
    
    var onTap: ((SelectBottomBarType) -> Void)?
    
    private let disposeBag = DisposeBag()
    
    private lazy var completeBtn: UIButton = {
        let v = UIButton(type: .system)
        v.layer.cornerRadius = 4
        v.backgroundColor = .c0089FF
        v.setTitleColor(.white, for: .normal)
        v.titleLabel?.font = .f14
        v.contentEdgeInsets = UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6)
        v.setTitle("confirmSelectedPeople".innerLocalizedFormat(arguments: "0", "\(maxCount)"), for: .normal)
        v.isEnabled = false
        
        v.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] _ in
            self?.onTap?(.complete)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    private lazy var selectCountBtn: LayoutButton = {
        let v = LayoutButton(imagePosition: .trailing, atSpace: 7)
        v.setImage(UIImage(nameInBundle: "common_blue_arrow_up_icon"), for: .normal)
        v.setFont(.f14)
        v.setTitleColor(.c0089FF, for: .normal)
        v.setTitle("selectedPeopleCount".innerLocalizedFormat(arguments: "\(selectedCount)"), for: .normal)

        v.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] _ in
            self?.onTap?(.selected)
        }).disposed(by: disposeBag)
        
        return v
    }()
    
    private let namesLabel: UILabel = {
        let v = UILabel()
        v.textColor = .c8E9AB0
        v.font = .f14
        v.numberOfLines = 1
        
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .tertiarySystemBackground
        selectedCount = 0
        
        addSubview(completeBtn)
        completeBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        completeBtn.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        addSubview(selectCountBtn)
        selectCountBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(8)
        }
        
        addSubview(namesLabel)
        namesLabel.snp.makeConstraints { make in
            make.leading.bottom.equalToSuperview().inset(16)
            make.top.equalTo(selectCountBtn.snp.bottom)
            make.trailing.equalTo(completeBtn.snp.leading).inset(8)
        }
        
        let safeAreaInsets = UIApplication.safeAreaInsets
        
        snp.makeConstraints { make in
            make.height.equalTo(safeAreaInsets.bottom + 70)
        }
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
