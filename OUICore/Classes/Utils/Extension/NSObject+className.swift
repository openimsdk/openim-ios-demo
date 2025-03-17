
import Foundation

extension NSObject {
    var clazzName: String {
        return type(of: self).description()
    }

    public class var className: String {
        return String(describing: self)
    }
}
