import Photos

protocol Album {
    var assetCollection: PHAssetCollection { get }
    var title: String? { get }
    var keyAsset: PHAsset? { get }
    var count: Int? { get }
}

protocol FetchedAlbumProtocol: Album {
    var fetchResult: PHFetchResult<PHAsset> { get }
}

/// An album with static content.
struct StaticAlbum: Album, Equatable {
    let assetCollection: PHAssetCollection
    let keyAsset: PHAsset?
    let count: Int?
}

/// An album with fetched assets.
struct FetchedAlbum: FetchedAlbumProtocol, Equatable {
    let assetCollection: PHAssetCollection
    let fetchResult: PHFetchResult<PHAsset>
}

// MARK: - Extensions

extension Album {
    var title: String? {
        return assetCollection.localizedTitle
    }
}

extension FetchedAlbumProtocol {
    var keyAsset: PHAsset? {
        return fetchResult.firstObject
    }

    var count: Int? {
        return fetchResult.count
    }
}

extension StaticAlbum {
    init(album: Album) {
        self.assetCollection = album.assetCollection
        self.keyAsset = album.keyAsset
        self.count = album.count
    }
}
