
import RxSwift
import SnapKit
import UIKit

open class JNDatePickerView: UIView {
    lazy var cancelButton: UIButton = {
        let v = UIButton()
        v.setTitle("取消".innerLocalized(), for: .normal)
        v.setTitleColor(.c0089FF, for: .normal)
        return v
    }()

    lazy var confirmButton: UIButton = {
        let v = UIButton()
        v.setTitle("确定".innerLocalized(), for: .normal)
        v.setTitleColor(.c0089FF, for: .normal)
        return v
    }()

    lazy var container: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white
        return v
    }()

    public lazy var datePicker: UIDatePicker = {
        let v = UIDatePicker()
        v.datePickerMode = .date
        if #available(iOS 13.4, *) {
            v.preferredDatePickerStyle = .wheels
        }
        v.minimumDate = Date()
        return v
    }()

    var currentDate: Date = .init()

    let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        container.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(5)
            make.size.equalTo(CGSize(width: 44, height: 34))
        }
        container.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.size.equalTo(cancelButton)
        }

        container.addSubview(datePicker)
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(cancelButton.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().offset(-40)
            make.height.equalTo(200)
        }

        addSubview(container)
        container.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            _bottomConstraint = make.bottom.equalTo(200).constraint
        }

        cancelButton.rx.tap.throttle(.milliseconds(300), latest: false, scheduler: MainScheduler.instance)
            .map { [weak self] _ -> Bool in
                guard let sself = self else { return false }
                let ret = sself.anySubviewScrolling(sself.datePicker)
                return ret
            }
            .subscribe { [weak self] event in
                if let isSpinning = event.element, !isSpinning {
                    self?.hide()
                }
            }.disposed(by: disposeBag)
    }

    static public func show(onWindowOfView: UIView, currentDate: Date = Date(), configure: ((JNDatePickerView) -> Void)?, confirmAction: @escaping ((Date) -> Void)) {
        let pickerView: JNDatePickerView = {
            let v = JNDatePickerView()
            v.backgroundColor = UIColor(white: 0, alpha: 0.6)
            v.currentDate = currentDate
            v.confirmButton.rx.tap.throttle(.milliseconds(300), latest: false, scheduler: MainScheduler.instance)
                .map { [weak v] _ -> Bool in
                    guard let sself = v else { return false }
                    let ret = sself.anySubviewScrolling(sself.datePicker)
                    return ret
                }
                .subscribe { [weak v] event in
                    guard let sself = v else { return }
                    if let isScrolling = event.element, !isScrolling {
                        sself.currentDate = sself.datePicker.date
                        confirmAction(sself.currentDate)
                        sself.hide()
                    }
                }.disposed(by: v.disposeBag)
            return v
        }()
        configure?(pickerView)
        onWindowOfView.window?.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        pickerView.layoutIfNeeded()
        pickerView.backgroundColor = UIColor(white: 0, alpha: 0)
        pickerView.datePicker.setDate(currentDate, animated: false)
        UIView.animate(withDuration: 0.3) {
            pickerView.backgroundColor = UIColor(white: 0, alpha: 0.6)
            pickerView._bottomConstraint?.updateOffset(amount: 0)
            pickerView.layoutIfNeeded()
        } completion: { _ in
        }
    }

    public func show(onWindowOfView: UIView) {
        onWindowOfView.window?.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        layoutIfNeeded()
        backgroundColor = UIColor(white: 0, alpha: 0)
        datePicker.setDate(currentDate, animated: false)
        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = UIColor(white: 0, alpha: 0.6)
            self._bottomConstraint?.updateOffset(amount: 0)
            self.layoutIfNeeded()
        } completion: { _ in
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = UIColor(white: 0, alpha: 0)
            self._bottomConstraint?.updateOffset(amount: self.container.bounds.size.height)
            self.layoutIfNeeded()
        } completion: { [weak self] complete in
            if complete {
                self?.removeFromSuperview()
            }
        }
    }

    @available(*, unavailable)
    required public init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func anySubviewScrolling(_ view: UIView) -> Bool {
        if let scrview = view as? UIScrollView {
            if scrview.isDragging || scrview.isDecelerating {
                return true
            }
        }

        for subview in view.subviews {
            if anySubviewScrolling(subview) {
                return true
            }
        }
        return false
    }

    private var _bottomConstraint: Constraint?

    deinit {
        #if DEBUG
            print("dealloc \(type(of: self))")
        #endif
    }

    private class ContainerView: UIView {
        weak var untouchableView: UIView?

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first, let view = untouchableView else {
                return
            }

            let point = touch.location(in: self)
            let tPoint = view.convert(point, from: self)
            if view.point(inside: tPoint, with: event) {
                return
            }

            removeFromSuperview()
        }
    }
}
