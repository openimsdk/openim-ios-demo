


























import Foundation
import UIKit

class NSLayoutConstraintSet {
    
    var top: NSLayoutConstraint?
    var bottom: NSLayoutConstraint?
    var left: NSLayoutConstraint?
    var right: NSLayoutConstraint?
    var centerX: NSLayoutConstraint?
    var centerY: NSLayoutConstraint?
    var width: NSLayoutConstraint?
    var height: NSLayoutConstraint?
    
    public init(top: NSLayoutConstraint? = nil,
                bottom: NSLayoutConstraint? = nil,
                left: NSLayoutConstraint? = nil,
                right: NSLayoutConstraint? = nil,
                centerX: NSLayoutConstraint? = nil,
                centerY: NSLayoutConstraint? = nil,
                width: NSLayoutConstraint? = nil,
                height: NSLayoutConstraint? = nil) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
        self.centerX = centerX
        self.centerY = centerY
        self.width = width
        self.height = height
    }

    private var availableConstraints: [NSLayoutConstraint] {
        #if swift(>=4.1)
            return [top, bottom, left, right, centerX, centerY, width, height].compactMap {$0}
        #else
            return [top, bottom, left, right, centerX, centerY, width, height].flatMap {$0}
        #endif
    }



    @discardableResult
    func activate() -> Self {
        NSLayoutConstraint.activate(availableConstraints)
        return self
    }



    @discardableResult
    func deactivate() -> Self {
        NSLayoutConstraint.deactivate(availableConstraints)
        return self
    }
}
