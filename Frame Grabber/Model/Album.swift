import Photos

protocol PhotosIdentifiable {
    var id: String { get }
}

protocol Album: PhotosIdentifiable {
    var assetCollection: PHAssetCollection { get }
    var title: String? { get }
    var count: Int { get }
    var keyAsset: PHAsset? { get }
}

extension Album {
    var id: String {
        assetCollection.localIdentifier
    }

    var title: String? {
        assetCollection.localizedTitle
    }

    var isEmpty: Bool {
        count == 0
    }
}
