import Photos

protocol Album {
    var assetCollection: PHAssetCollection { get }
    var title: String? { get }
    var count: Int { get }
    var keyAsset: PHAsset? { get }
}

extension Album {
    var title: String? {
        return assetCollection.localizedTitle
    }
}

/// An album with static content.
struct StaticAlbum: Album, Equatable {
    let assetCollection: PHAssetCollection
    let count: Int
    let keyAsset: PHAsset?
}

extension StaticAlbum {
    init(album: Album) {
        self.assetCollection = album.assetCollection
        self.count = album.count
        self.keyAsset = album.keyAsset
    }
}
