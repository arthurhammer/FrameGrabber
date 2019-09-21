import Photos

protocol FetchedAlbumProtocol: Album {
    var fetchResult: PHFetchResult<PHAsset> { get }
}

extension FetchedAlbumProtocol {
    var keyAsset: PHAsset? {
        fetchResult.firstObject
    }

    var count: Int {
        fetchResult.count
    }
}

/// An album with fetched assets.
struct FetchedAlbum: FetchedAlbumProtocol, Equatable {
    let assetCollection: PHAssetCollection
    let fetchResult: PHFetchResult<PHAsset>
}
