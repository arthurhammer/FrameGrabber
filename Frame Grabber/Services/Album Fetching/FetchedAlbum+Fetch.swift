import Photos

extension FetchedAlbum {

    /// Fetches assets for the given album.
    static func fetchAssets(in assetCollection: PHAssetCollection, options: PHFetchOptions? = nil) -> FetchedAlbum {
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
        return FetchedAlbum(assetCollection: assetCollection, fetchResult: fetchResult)
    }

    /// Re-fetches both the given album and its assets. Returns nil if album was deleted.
    static func fetchUpdate(for assetCollection: PHAssetCollection, assetFetchOptions: PHFetchOptions? = nil) -> FetchedAlbum? {
        let id = assetCollection.localIdentifier

        guard let updatedCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject else {
            return nil
        }

        return fetchAssets(in: updatedCollection, options: assetFetchOptions)
    }

    /// For each type fetches the album and its contents.
    static func fetchSmartAlbums(with types: [PHAssetCollectionSubtype], assetFetchOptions: PHFetchOptions? = nil) -> [FetchedAlbum] {
        PHAssetCollection.fetchSmartAlbums(with: types)
            .map { fetchAssets(in: $0, options: assetFetchOptions) }
    }
}
