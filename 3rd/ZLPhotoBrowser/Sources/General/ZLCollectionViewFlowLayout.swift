

























import UIKit

class ZLCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override var flipsHorizontallyInOppositeLayoutDirection: Bool { isRTL() }
}
