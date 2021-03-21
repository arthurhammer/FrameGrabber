import Photos

/// A type that represents a `PhotoKit` photo album and its fetched album contents.
protocol FetchedAlbumProtocol: AlbumProtocol {
    var fetchResult: PHFetchResult<PHAsset> { get }
}

extension FetchedAlbumProtocol {

    public var keyAsset: PHAsset? {
        switch assetCollection.assetCollectionType {
        case .smartAlbum:
            return fetchResult.lastObject
        default:
            return fetchResult.firstObject
        }
    }

    public var count: Int {
        fetchResult.count
    }
}
