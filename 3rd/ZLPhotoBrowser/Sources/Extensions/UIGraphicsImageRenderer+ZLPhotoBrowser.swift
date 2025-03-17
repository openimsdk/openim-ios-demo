

























import UIKit

extension ZLPhotoBrowserWrapper where Base: UIGraphicsImageRenderer {
    static func renderImage(
        size: CGSize,
        formatConfig: ((UIGraphicsImageRendererFormat) -> Void)? = nil,
        imageActions: ((CGContext) -> Void)
    ) -> UIImage {
        let format: UIGraphicsImageRendererFormat
        if #available(iOS 11.0, *) {
            format = .preferred()
        } else {
            format = .default()
        }
        formatConfig?(format)
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            imageActions(context.cgContext)
        }
    }
}
