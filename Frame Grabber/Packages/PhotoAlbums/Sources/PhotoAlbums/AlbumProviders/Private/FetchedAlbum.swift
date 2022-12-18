import Photos

/// A `PhotoKit` photo album and its fetched contents.
struct FetchedAlbum: AlbumProtocol {
    
    /// The photo album.
    let assetCollection: PHAssetCollection
    
    /// The contents of the album.
    let fetchResult: PHFetchResult<PHAsset>
    
    /// The options used to fetch the contents.
    let fetchOptions: PHFetchOptions?
    
    var count: Int {
        fetchResult.count
    }
    
    var keyAsset: PHAsset? {
        switch assetCollection.assetCollectionType {
        case .smartAlbum:
            return fetchResult.lastObject
        default:
            return fetchResult.firstObject
        }
    }
}

// MARK: - Fetching Albums

extension FetchedAlbum {

    /// Fetches assets for the given album.
    static func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions? = nil) -> FetchedAlbum {
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
        
        return FetchedAlbum(
            assetCollection: assetCollection,
            fetchResult: fetchResult,
            fetchOptions: options
        )
    }

    /// Fetches smart albums with the given types.
    static func fetchSmartAlbums(with types: [PHAssetCollectionSubtype], options: PHFetchOptions? = nil) -> [FetchedAlbum] {
        let albums = types.compactMap {
            PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: $0,
                options: nil
            ).firstObject
        }

        return albums.map {
            fetchAssets(in: $0, options: options)            
        }
    }
}

// MARK: - Updating Albums

extension FetchedAlbum {
    
    /// An updated album by applying the given photo library changes.
    ///
    /// Returns `nil` if the album was deleted.
    func applying(change: PHChange) -> FetchedAlbum? {
        let albumChanges = change.changeDetails(for: assetCollection)
        let assetChanges = change.changeDetails(for: fetchResult)
        let didChange = (albumChanges, assetChanges) != (nil, nil)
        let wasDeleted = albumChanges?.objectWasDeleted ?? false

        guard didChange else { return self }
        guard !wasDeleted else { return nil }
        
        return FetchedAlbum(
            assetCollection: albumChanges?.objectAfterChanges ?? assetCollection,
            fetchResult: assetChanges?.fetchResultAfterChanges ?? fetchResult,
            fetchOptions: fetchOptions
        )
    }
}
