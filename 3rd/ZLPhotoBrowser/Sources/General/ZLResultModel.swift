

























import UIKit
import Photos

public class ZLResultModel: NSObject {
    @objc public let asset: PHAsset
    
    @objc public let image: UIImage

    @objc public let isEdited: Bool

    @objc public let editModel: ZLEditImageModel?

    @objc public let index: Int
    
    @objc public init(asset: PHAsset, image: UIImage, isEdited: Bool, editModel: ZLEditImageModel? = nil, index: Int) {
        self.asset = asset
        self.image = image
        self.isEdited = isEdited
        self.editModel = editModel
        self.index = index
        super.init()
    }
}

extension ZLResultModel {
    static func ==(lhs: ZLResultModel, rhs: ZLResultModel) -> Bool {
        return lhs.asset == rhs.asset
    }
}
