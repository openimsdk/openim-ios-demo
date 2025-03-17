import UIKit
import Localize_Swift
import Kingfisher

public class CallingBaseController: UIViewController {
    @objc public var onAccepted: (() -> Void)?
    @objc public var onRejected: (() -> Void)?
    @objc public var onCancel: (() -> Void)?
    @objc public var onHungup: ((_ duration: Int) -> Void)?
    @objc public var onInvitedOthers: (() -> Void)?
    @objc public var onConnectFailure: (() -> Void)?
    @objc public var onDisconnect: (() -> Void)?
    @objc public func startLiveChat(inviter: @escaping UserInfoHandler,
                                    others: @escaping UserInfoHandler,
                                    isVideo: Bool = true) {}
    @objc public func connectRoom(liveURL: String, token: String) {}
    @objc public func dismiss() {}
    
    public func isConnected() -> Bool { false }
}

class SizeBox: UIView {
    init(width: Int = 0, height: Int = 0) {
        super.init(frame: .zero)
        
        snp.makeConstraints { make in
            if width > 0 {
                make.width.equalTo(width)
            }
            
            if height > 0 {
                make.height.equalTo(height)
            }
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Bundle {
    static func callingBundle() -> Bundle {
        guard let path = Bundle(for: CallingBaseViewController.self).resourcePath else { return Bundle.main }
        var finalPath: String = path
        finalPath.append("/OIMUICalling.bundle")
        let bundle = Bundle(path: finalPath)
        return bundle ?? Bundle.main
    }
}

extension UIImage {
    convenience init?(nameInBundle: String) {
        self.init(named: nameInBundle, in: Bundle.callingBundle(), compatibleWith: nil)
    }
}

extension UIImageView {
    func setImage(with string: String?, placeHolder: String?) {
        guard let string = string, !string.isEmpty, let url = URL(string: string) else {
            if let placeHolder = placeHolder {
                image = UIImage(named: placeHolder, in: Bundle.callingBundle(), compatibleWith: nil)
            } else {
                image = nil
            }
            return
        }
        let placeImage: UIImage?
        if let placeHolder = placeHolder {
            placeImage = UIImage(named: placeHolder, in: Bundle.callingBundle(), compatibleWith: nil)
        } else {
            placeImage = nil
        }
        kf.setImage(with: url, placeholder: placeImage)
    }
    
    func setImagePath(_ path: String, placeHolder _: String?) {
        if !FileManager.default.fileExists(atPath: path) {
            return
        }
        let url = URL(fileURLWithPath: path)
        image = UIImage(contentsOfFile: url.path)
    }
}

extension String {
    func localized() -> String {
        let bundle = Bundle.callingBundle()
        let str = localized(using: nil, in: bundle)
        
        return str
    }
}
