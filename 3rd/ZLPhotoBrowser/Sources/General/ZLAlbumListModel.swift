

























import UIKit
import Photos

public class ZLAlbumListModel: NSObject {
    public let title: String
    
    public var count: Int {
        return result.count
    }
    
    public var result: PHFetchResult<PHAsset>
    
    public let collection: PHAssetCollection
    
    public let option: PHFetchOptions
    
    public let isCameraRoll: Bool
    
    public var headImageAsset: PHAsset? {
        return result.lastObject
    }
    
    public var models: [ZLPhotoModel] = []

    private var selectedModels: [ZLPhotoModel] = []

    private var selectedCount = 0
    
    public init(
        title: String,
        result: PHFetchResult<PHAsset>,
        collection: PHAssetCollection,
        option: PHFetchOptions,
        isCameraRoll: Bool
    ) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
        self.isCameraRoll = isCameraRoll
    }
    
    public func refetchPhotos() {
        let models = ZLPhotoManager.fetchPhoto(
            in: result,
            ascending: ZLPhotoUIConfiguration.default().sortAscending,
            allowSelectImage: ZLPhotoConfiguration.default().allowSelectImage,
            allowSelectVideo: ZLPhotoConfiguration.default().allowSelectVideo
        )
        self.models.removeAll()
        self.models.append(contentsOf: models)
    }
    
    func refreshResult() {
        result = PHAsset.fetchAssets(in: collection, options: option)
    }
}

extension ZLAlbumListModel {
    static func ==(lhs: ZLAlbumListModel, rhs: ZLAlbumListModel) -> Bool {
        return lhs.title == rhs.title &&
            lhs.count == rhs.count &&
            lhs.headImageAsset?.localIdentifier == rhs.headImageAsset?.localIdentifier
    }
}
