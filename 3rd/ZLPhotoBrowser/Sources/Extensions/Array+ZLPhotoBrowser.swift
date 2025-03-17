

























import Photos
import UIKit

extension ZLPhotoBrowserWrapper where Base == [PHAsset] {
    func removeDuplicate() -> [PHAsset] {
        return base.enumerated().filter { index, value -> Bool in
            base.firstIndex(of: value) == index
        }.map { $0.element }
    }
}

extension ZLPhotoBrowserWrapper where Base == [ZLResultModel] {
    func removeDuplicate() -> [ZLResultModel] {
        return base.enumerated().filter { index, value -> Bool in
            base.firstIndex(of: value) == index
        }.map { $0.element }
    }
}
