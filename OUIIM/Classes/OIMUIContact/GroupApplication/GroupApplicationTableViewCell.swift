
import RxSwift
import OUICore

class GroupApplicationTableViewCell: UITableViewCell {
    var disposeBag = DisposeBag()

    let avatarView = AvatarView()

    let nameLabel: UILabel = {
        let v = UILabel()
        v.font = .f17
        v.textColor = .c0C1C33
        return v
    }()

    private let applyInfoLabel: UILabel = {
        let v = UILabel()
        v.font = .f14

        return v
    }()

    private let applyReasonLabel: UILabel = {
        let v = UILabel()
        v.font = .f14
        v.textColor = .c8E9AB0
        v.numberOfLines = 3
        return v
    }()

    let agreeBtn: UIButton = {
        let v = UIButton(type: .custom)
        v.titleLabel?.font = .f14
        v.layer.cornerRadius = 5
        v.contentEdgeInsets = UIEdgeInsets(top: .margin8, left: .margin8, bottom: .margin8, right: .margin8)

        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        let vStack = UIStackView(arrangedSubviews: [nameLabel, applyInfoLabel, applyReasonLabel])
        vStack.axis = .vertical
        vStack.spacing = 4
        vStack.alignment = .leading
        
        let hStack = UIStackView(arrangedSubviews: [avatarView, vStack, agreeBtn])
        hStack.spacing = 10
        hStack.alignment = .top
        
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
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

    func setApplyState(_ state: ApplyState, isSendOut: Bool) {
        switch state {
        case .uncertain:
            let title = configButtonTitle(icon: isSendOut, text: isSendOut ? "等待验证".innerLocalized() : "查看".innerLocalized())
            title.addAttributes([.foregroundColor: isSendOut ? UIColor.c8E9AB0 : UIColor.white], range: NSMakeRange(0, title.length))
            agreeBtn.setAttributedTitle(title, for: .normal)
            
            agreeBtn.backgroundColor = isSendOut ? .clear : .c0089FF
            agreeBtn.isEnabled = !isSendOut
        case .agreed:
            let title = configButtonTitle(icon: isSendOut, text: "已同意".innerLocalized())
            title.addAttributes([.foregroundColor: UIColor.c8E9AB0], range: NSMakeRange(0, title.length))
            
            agreeBtn.setAttributedTitle(title, for: .normal)
            agreeBtn.backgroundColor = .clear
            agreeBtn.isEnabled = false
        case .rejected:
            let title = configButtonTitle(icon: isSendOut, text: "已拒绝".innerLocalized())
            title.addAttributes([.foregroundColor: UIColor.c8E9AB0], range: NSMakeRange(0, title.length))
            
            agreeBtn.setAttributedTitle(title, for: .normal)
            agreeBtn.backgroundColor = .clear
            agreeBtn.isEnabled = false
        }
    }
    
    private func configButtonTitle(icon: Bool = false, text: String) -> NSMutableAttributedString {
        
        let attr = NSMutableAttributedString(string: text)
        
        if icon {
            let attach = NSTextAttachment(image: UIImage(nameInBundle: "application_request_icon")!)
            attach.bounds = CGRect(x: 0, y: -4, width: 20, height: 20)
            let attachStr = NSAttributedString(attachment: attach)
            
            attr.insert(attachStr, at: 0)
        }
        
        return attr
    }

    func setCompanyName(_ name: String) {
        let attr = NSMutableAttributedString(string: "申请加入".innerLocalized() + " ", attributes: [.foregroundColor: UIColor.c8E9AB0])
        let companyAttrName = NSAttributedString(string: name, attributes: [.foregroundColor: UIColor.c0089FF])
        attr.append(companyAttrName)
        applyInfoLabel.attributedText = attr
    }

    func setApply(reason: String) {
        applyReasonLabel.text = !reason.isEmpty ? "申请理由".innerLocalized() + ": \(reason)" : nil
    }
    
    enum ApplyState: Int {
        case rejected = -1
        case uncertain = 0
        case agreed = 1
        
    }
}
