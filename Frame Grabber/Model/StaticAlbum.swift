import Photos

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
