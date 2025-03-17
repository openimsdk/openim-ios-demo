
import UIKit

public enum CodeGeneratorType: String {
    case typeQrCode = "CIQRCodeGenerator"
}

public class CodeImageGenerator {

    public static func createQRCodeImage(content: String, size: CGSize, foregroundColor: UIColor, backgroundColor: UIColor) -> UIImage? {
        let generatorType = CodeGeneratorType.typeQrCode
        guard let codeFilter = CIFilter(name: generatorType.rawValue), let data = content.data(using: .utf8) else {
            return nil
        }

        codeFilter.setValue(data, forKey: "inputMessage")

        codeFilter.setValue("H", forKey: "inputCorrectionLevel")
        guard let codeImage = codeFilter.outputImage else {
            return nil
        }
        let colorFilter = CIFilter(name: "CIFalseColor", parameters: [
            "inputImage": codeImage,
            "inputColor0": CIColor(cgColor: foregroundColor.cgColor),
            "inputColor1": CIColor(cgColor: backgroundColor.cgColor),
        ])
        guard let colorImage = colorFilter?.outputImage, let cgImage = CIContext().createCGImage(colorImage, from: colorImage.extent) else {
            return nil
        }
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.interpolationQuality = .none
        context.scaleBy(x: 1, y: -1)
        context.draw(cgImage, in: context.boundingBoxOfClipPath)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
