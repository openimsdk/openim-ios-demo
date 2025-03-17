
import Foundation
import UIKit

extension Array {
    func deduplicate<E: Equatable>(filter: (Element) -> E) -> [Element] {
        var ret = [Element]()
        for value in self {
            let key = filter(value)
            if !ret.map({filter($0)}).contains(key) {
                ret.append(value)
            }
        }
        return ret
    }
}

extension UIViewController {
    func showAlertView(message: String) {
        let alertView = UIAlertController.init(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "取消", style: .cancel)
        alertView.addAction(action)
        
        present(alertView, animated: true)
    }
}
