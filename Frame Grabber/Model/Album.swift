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
        return assetCollection.localIdentifier
    }

    var title: String? {
        return assetCollection.localizedTitle
    }

    var isEmpty: Bool {
        return count == 0
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
