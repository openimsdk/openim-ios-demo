
import UIKit

public class LayoutButton: UIButton {
    private var position: NSDirectionalRectEdge?
    private var space: CGFloat = 0
    private var font = UIFont.systemFont(ofSize: 10)
    private var baseForegroundColor: UIColor? = UIColor.white

    private var _originBounds: CGRect = .zero

    public convenience init(imagePosition: NSDirectionalRectEdge = .top, atSpace space: CGFloat = 4) {
        self.init(type: .custom)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.imagePlacement = imagePosition
            config.baseForegroundColor = baseForegroundColor
            config.baseBackgroundColor = .clear
            config.titlePadding = space
            config.imagePadding = space
            config.contentInsets = .zero
            
            configuration = config
        }
        
        self.position = position
        self.space = space
    }
    
    public func setFont(_ font: UIFont) {
        self.font = font
        
        if #available(iOS 15.0, *) {
            if var title = attributedTitle(for: .normal) as? NSMutableAttributedString {
                title.addAttribute(.font, value: font, range: NSMakeRange(0, title.length))
                
                setAttributedTitle(title, for: .normal)
            }
        } else {
            titleLabel?.font = font
        }
    }
    
    public override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        baseForegroundColor = color
        
        if #available(iOS 15.0, *) {
            if var title = attributedTitle(for: .normal) as? NSMutableAttributedString {
                title.addAttribute(.foregroundColor, value: baseForegroundColor, range: NSMakeRange(0, title.length))
                
                setAttributedTitle(title, for: .normal)
            }
        } else {
            super.setTitleColor(color, for: state)
        }
    }
    
    public override func setTitle(_ title: String?, for state: UIControl.State) {
        if #available(iOS 15.0, *) {
            let attrTitle = AttributedString(title ?? "", attributes: AttributeContainer([.foregroundColor: baseForegroundColor, .font: font]))
            
            setAttributedTitle(NSAttributedString(attrTitle), for: state)
        } else {
            super.setTitle(title, for: state)
        }
    }
    
    public override  var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        
        if #available(iOS 15.0, *) {
            return size
        }
        
        if let position {
            switch position {
            case .leading, .trailing:
                size.width += space
            case .top, .bottom:
                let titleHeight = titleLabel?.bounds.height ?? 0
                let imageHeight = imageView?.bounds.height ?? 0
                size.height = space + titleHeight + imageHeight
            default:
                break
            }
        } else {
            size.width += space
        }
        return size
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 15.0, *) {
            return
        }
        
        if _originBounds == bounds {
            return
        }
        _originBounds = bounds

        if let position = position {
            switch position {
            case .top:
                let titleHeight = titleLabel?.bounds.height ?? 0
                let imageHeight = imageView?.bounds.height ?? 0
                let imageWidth = imageView?.bounds.width ?? 0
                let titleWidth = titleLabel?.bounds.width ?? 0
                titleEdgeInsets = UIEdgeInsets(top: (titleHeight + space) * 0.5, left: -imageWidth * 0.5, bottom: -space, right: imageWidth * 0.5)
                imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth * 0.5, bottom: imageHeight + space, right: -titleWidth * 0.5)

            case .bottom:
                let titleHeight = titleLabel?.bounds.height ?? 0
                let imageHeight = imageView?.bounds.height ?? 0
                let imageWidth = imageView?.bounds.width ?? 0
                let titleWidth = titleLabel?.bounds.width ?? 0
                titleEdgeInsets = UIEdgeInsets(top: -(titleHeight + space) * 0.5, left: -imageWidth * 0.5, bottom: space, right: imageWidth * 0.5)
                imageEdgeInsets = UIEdgeInsets(top: imageHeight + space, left: titleWidth * 0.5, bottom: 0, right: -titleWidth * 0.5)

            case .leading:
                titleEdgeInsets = UIEdgeInsets(top: 0, left: space, bottom: 0, right: 0)
                imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: space)
            case .trailing:

                let imageWidth = (imageView?.bounds.width ?? 0) + space * 0.5
                let titleWidth = (titleLabel?.bounds.width ?? 0) + space * 0.5
                titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageWidth, bottom: 0, right: imageWidth)
                imageEdgeInsets = UIEdgeInsets(top: 0, left: titleWidth, bottom: 0, right: -titleWidth)
            default:
                break
            }
        }
    }
}

extension UIButton {

  public func setBackgroundColor(_ color: UIColor, for forState: UIControl.State) {
    UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
    UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
    UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    let colorImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    self.setBackgroundImage(colorImage, for: forState)
  }
}
