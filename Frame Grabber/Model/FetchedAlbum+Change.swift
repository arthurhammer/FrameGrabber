import Photos

struct FetchedAlbumChangeDetails {
    /// nil if album was deleted.
    let albumAfterChanges: FetchedAlbum?
    /// nil if album did not change.
    let assetCollectionChanges: PHObjectChangeDetails<PHAssetCollection>?
    /// nil if album contents did not change.
    let fetchResultChanges: PHFetchResultChangeDetails<PHAsset>?

    var albumWasDeleted: Bool {
        return albumAfterChanges == nil
    }
}

extension PHChange {

    /// nil if nothing changed.
    func changeDetails(for album: FetchedAlbum) -> FetchedAlbumChangeDetails? {
        let albumChanges = changeDetails(for: album.assetCollection)
        let assetChanges = changeDetails(for: album.fetchResult)
        let didChange = (albumChanges, assetChanges) != (nil, nil)
        let wasDeleted = albumChanges?.objectWasDeleted ?? false

        guard didChange else { return nil }

        let updatedAlbum: FetchedAlbum?

        if wasDeleted {
            updatedAlbum = nil
        } else {
            updatedAlbum = FetchedAlbum(assetCollection: albumChanges?.objectAfterChanges ?? album.assetCollection,
                                        fetchResult: assetChanges?.fetchResultAfterChanges ?? album.fetchResult)
        }

        return FetchedAlbumChangeDetails(albumAfterChanges: updatedAlbum, assetCollectionChanges: albumChanges, fetchResultChanges: assetChanges)
    }
}
