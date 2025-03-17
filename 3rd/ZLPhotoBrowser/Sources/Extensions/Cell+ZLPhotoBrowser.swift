

























import UIKit

extension ZLPhotoBrowserWrapper where Base: UICollectionViewCell {
    static var identifier: String {
        NSStringFromClass(Base.self)
    }
    
    static func register(_ collectionView: UICollectionView) {
        collectionView.register(Base.self, forCellWithReuseIdentifier: identifier)
    }
}

extension ZLPhotoBrowserWrapper where Base: UITableViewCell {
    static var identifier: String {
        NSStringFromClass(Base.self)
    }
    
    static func register(_ tableView: UITableView) {
        tableView.register(Base.self, forCellReuseIdentifier: identifier)
    }
}
