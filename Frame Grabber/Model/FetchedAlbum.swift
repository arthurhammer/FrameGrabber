import Photos

/// A type of album that provides the assets that it contains as a fetch result.
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

/// An album and its album contents.
struct FetchedAlbum: FetchedAlbumProtocol, Hashable {
    let assetCollection: PHAssetCollection
    let fetchResult: PHFetchResult<PHAsset>
}
