import Photos

/// A type-erasing album with static content.
struct AnyAlbum: Album, Hashable {
    let assetCollection: PHAssetCollection
    let title: String?
    let count: Int
    let keyAsset: PHAsset?
}

extension AnyAlbum {
    init(album: Album) {
        self.assetCollection = album.assetCollection
        self.title = album.title  // Stored, not computed for correct hashing/diffing.
        self.count = album.count
        self.keyAsset = album.keyAsset
    }
}
