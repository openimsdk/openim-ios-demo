


























import UIKit

internal extension NSMutableAttributedString {
 
    @discardableResult
    func bold(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize, textColor: UIColor) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key:AnyObject] = [
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor : textColor
        ]
        let boldString = NSMutableAttributedString(string: text, attributes: attrs)
        self.append(boldString)
        return self
    }
    
    @discardableResult
    func medium(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize, textColor: UIColor) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key:AnyObject] = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.medium),
            NSAttributedString.Key.foregroundColor : textColor
        ]
        let mediumString = NSMutableAttributedString(string: text, attributes: attrs)
        self.append(mediumString)
        return self
    }
    
    @discardableResult
    func italic(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize, textColor: UIColor) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key:AnyObject] = [
            NSAttributedString.Key.font : UIFont.italicSystemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor : textColor
        ]
        let italicString = NSMutableAttributedString(string: text, attributes: attrs)
        self.append(italicString)
        return self
    }
    
    @discardableResult
    func normal(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize, textColor: UIColor) -> NSMutableAttributedString {
        let attrs:[NSAttributedString.Key:AnyObject] = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: fontSize),
            NSAttributedString.Key.foregroundColor : textColor
        ]
        let normal =  NSMutableAttributedString(string: text, attributes: attrs)
        self.append(normal)
        return self
    }

    @discardableResult
    func bold(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize) -> NSMutableAttributedString {
        if #available(iOS 13, *) {
            return bold(text, fontSize: fontSize, textColor: .label)
        } else {
            return bold(text, fontSize: fontSize, textColor: .black)
        }
    }

    @discardableResult
    func medium(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize) -> NSMutableAttributedString {
        if #available(iOS 13, *) {
            return medium(text, fontSize: fontSize, textColor: .label)
        } else {
            return medium(text, fontSize: fontSize, textColor: .black)
        }
    }

    @discardableResult
    func italic(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize) -> NSMutableAttributedString {
        if #available(iOS 13, *) {
            return italic(text, fontSize: fontSize, textColor: .label)
        } else {
            return italic(text, fontSize: fontSize, textColor: .black)

        }
    }

    @discardableResult
    func normal(_ text: String, fontSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize) -> NSMutableAttributedString {
        if #available(iOS 13, *) {
            return normal(text, fontSize: fontSize, textColor: .label)
        } else {
            return normal(text, fontSize: fontSize, textColor: .black)
        }
    }
}

internal extension NSAttributedString {

    func replacingCharacters(in range: NSRange, with attributedString: NSAttributedString) -> NSMutableAttributedString {
        let ns = NSMutableAttributedString(attributedString: self)
        ns.replaceCharacters(in: range, with: attributedString)
        return ns
    }
    
    static func += (lhs: inout NSAttributedString, rhs: NSAttributedString) {
        let ns = NSMutableAttributedString(attributedString: lhs)
        ns.append(rhs)
        lhs = ns
    }
    
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let ns = NSMutableAttributedString(attributedString: lhs)
        ns.append(rhs)
        return NSAttributedString(attributedString: ns)
    }
    
}
