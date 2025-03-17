
import Foundation
import UIKit

class SizeAdapter {
        
    static let shared = SizeAdapter()
    
    var baseSize = CGSize(width: 375.0, height: 812.0)
    
    func adaptWidth(input: CGFloat) -> CGFloat {
        input * UIScreen.main.bounds.size.width / baseSize.width
    }
    
    func adaptHeight(input: CGFloat) -> CGFloat {
        input * UIScreen.main.bounds.size.height / baseSize.height
    }
}

extension CGFloat {
    public var h: CGFloat {
        SizeAdapter.shared.adaptHeight(input: self)
    }
    
    public var w: CGFloat {
        SizeAdapter.shared.adaptWidth(input: self)
    }
}

extension Double {
    public var h: CGFloat {
        SizeAdapter.shared.adaptHeight(input: self)
    }
    
    public var w: CGFloat {
        SizeAdapter.shared.adaptWidth(input: self)
    }
}

extension Int {
    public var h: CGFloat {
        SizeAdapter.shared.adaptHeight(input: CGFloat(self))
    }
    
    public var w: CGFloat {
        SizeAdapter.shared.adaptWidth(input: CGFloat(self))
    }
    
    public var floorh: Int {
        Int(SizeAdapter.shared.adaptHeight(input: CGFloat(self)))
    }
    
    public var floorw: Int {
        Int(SizeAdapter.shared.adaptWidth(input: CGFloat(self)))
    }
}
