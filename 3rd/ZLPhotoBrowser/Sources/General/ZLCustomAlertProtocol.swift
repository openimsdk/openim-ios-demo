






import UIKit

public enum ZLCustomAlertStyle {
    case alert
    case actionSheet
}

public protocol ZLCustomAlertProtocol: AnyObject {

    static func alert(title: String?, message: String, style: ZLCustomAlertStyle) -> ZLCustomAlertProtocol
    
    func addAction(_ action: ZLCustomAlertAction)
    
    func show(with parentVC: UIViewController?)
}

public class ZLCustomAlertAction: NSObject {
    public enum Style {
        case `default`
        case tint
        case cancel
        case destructive
    }
    
    public let title: String
    
    public let style: ZLCustomAlertAction.Style
    
    public let handler: ((ZLCustomAlertAction) -> Void)?
    
    deinit {
        zl_debugPrint("ZLCustomAlertAction deinit")
    }
    
    public init(title: String, style: ZLCustomAlertAction.Style, handler: ((ZLCustomAlertAction) -> Void)?) {
        self.title = title
        self.style = style
        self.handler = handler
        super.init()
    }
}

extension ZLCustomAlertStyle {
    var toSystemAlertStyle: UIAlertController.Style {
        switch self {
        case .alert:
            return .alert
        case .actionSheet:
            return .actionSheet
        }
    }
}

extension ZLCustomAlertAction.Style {
    var toSystemAlertActionStyle: UIAlertAction.Style {
        switch self {
        case .default, .tint:
            return .default
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}

extension ZLCustomAlertAction {
    func toSystemAlertAction() -> UIAlertAction {
        return UIAlertAction(title: title, style: style.toSystemAlertActionStyle) { _ in
            self.handler?(self)
        }
    }
}
