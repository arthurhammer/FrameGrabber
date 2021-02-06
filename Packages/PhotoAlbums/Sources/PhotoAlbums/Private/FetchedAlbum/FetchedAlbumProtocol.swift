import Photos

/// A type of album that provides the assets that it contains as a fetch result.
public protocol FetchedAlbumProtocol: Album {
    var fetchResult: PHFetchResult<PHAsset> { get }
}

extension FetchedAlbumProtocol {

    public var keyAsset: PHAsset? {
        fetchResult.firstObject
    }

    public var count: Int {
        fetchResult.count
    }
}
