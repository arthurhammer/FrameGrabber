import Photos

/// A type of album that provides the assets that it contains as a fetch result.
public protocol FetchedAlbumProtocol: AlbumProtocol {
    var fetchResult: PHFetchResult<PHAsset> { get }
}

extension FetchedAlbumProtocol {

    public var keyAsset: PHAsset? {
        switch assetCollection.assetCollectionType {
        case .smartAlbum: return fetchResult.lastObject
        default: return fetchResult.firstObject
        }
    }

    public var count: Int {
        fetchResult.count
    }
}
