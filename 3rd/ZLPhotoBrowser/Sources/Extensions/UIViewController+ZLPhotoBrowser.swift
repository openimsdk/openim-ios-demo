

























import UIKit

extension ZLPhotoBrowserWrapper where Base: UIViewController {
    func showAlertController(_ alertController: UIAlertController) {
        if deviceIsiPad() {
            alertController.popoverPresentationController?.sourceView = base.view
        }
        base.showDetailViewController(alertController, sender: nil)
    }
}
