import Photos

/// An album and its fetched album contents.
public struct FetchedAlbum: FetchedAlbumProtocol {
    public let assetCollection: PHAssetCollection
    public let fetchResult: PHFetchResult<PHAsset>
}

// MARK: - Change Details

extension FetchedAlbum {

    /// Photo library change details for the album.
    public struct ChangeDetails {

        /// nil if album was deleted.
        public let albumAfterChanges: FetchedAlbum?

        /// nil if album did not change.
        public let assetCollectionChanges: PHObjectChangeDetails<PHAssetCollection>?

        /// nil if album contents did not change.
        public let fetchResultChanges: PHFetchResultChangeDetails<PHAsset>?
    }

}

// MARK: - Fetching Albums

extension FetchedAlbum {

    /// Fetches assets for the given album.
    public static func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions? = nil) -> FetchedAlbum {
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
        return FetchedAlbum(assetCollection: assetCollection, fetchResult: fetchResult)
    }

    /// Re-fetches both the given album and its assets. Returns nil if the album was deleted.
    public static func fetchUpdate(for assetCollection: PHAssetCollection, assetFetchOptions: PHFetchOptions? = nil) -> FetchedAlbum? {
        let id = assetCollection.localIdentifier

        guard let updatedCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject else {
            return nil
        }

        return fetchAssets(in: updatedCollection, options: assetFetchOptions)
    }

    /// For each type fetches the album and its contents.
    public static func fetchSmartAlbums(with types: [PHAssetCollectionSubtype], assetFetchOptions: PHFetchOptions? = nil) -> [FetchedAlbum] {
        let albums = types.compactMap {
            PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: $0, options: nil).firstObject
        }

        return albums.map { fetchAssets(in: $0, options: assetFetchOptions) }
    }
}
