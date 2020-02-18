import Photos

/// A type-erasing album with static content.
struct AnyAlbum: Album, Hashable {
    let assetCollection: PHAssetCollection
    let count: Int
    let keyAsset: PHAsset?
}

extension AnyAlbum {
    init(album: Album) {
        self.assetCollection = album.assetCollection
        self.count = album.count
        self.keyAsset = album.keyAsset
    }
}
