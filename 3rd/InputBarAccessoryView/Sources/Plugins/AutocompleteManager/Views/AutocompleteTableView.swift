


























import UIKit

open class AutocompleteTableView: UITableView {

    open var maxVisibleRows = 3 { didSet { invalidateIntrinsicContentSize() } }
    
    open override var intrinsicContentSize: CGSize {
        
        let rows = numberOfRows(inSection: 0) < maxVisibleRows ? numberOfRows(inSection: 0) : maxVisibleRows
        return CGSize(width: super.intrinsicContentSize.width, height: (CGFloat(rows) * rowHeight))
    }
    
}
