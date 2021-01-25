import Combine
import PhotoAlbums
import Photos
import UIKit

class AlbumCollectionViewDataSource: NSObject {

    /// The currently fetched album and its contents.
    ///
    /// The album contents respect the current filter. The album is `nil` if the current source
    /// album was deleted, was set to `nil` explicitly or the initial fetch hasn't finished yet.
    private(set) var album: FetchedAlbum?

    /// Called when the album itself and its metadata have changed.
    var albumChangedHandler: ((FetchedAlbum?) -> ())?
    
    /// Called when the contents of the album have changed.
    var videosChangedHandler: ((PHFetchResultChangeDetails<PHAsset>?) -> ())?
        
    /// When setting the filter, the current album is synchronously refetched with the new filter.
    ///
    /// If the authorization status is `notDetermined`, does not perform the fetch.
    var filter: VideoTypesFilter {
        get { settings.videoTypesFilter }
        set {
            settings.videoTypesFilter = newValue
            fetchAlbumContents(includingAlbum: false)
        }
    }
    
    var gridContentMode: AlbumGridContentMode {
        get { settings.albumGridContentMode }
        set { settings.albumGridContentMode = newValue }
    }

    var imageOptions = PHImageManager.ImageOptions()
    
    var isEmpty: Bool {
        album?.isEmpty ?? true
    }

    var isAuthorizationLimited: Bool {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited
        } else {
            return false
        }
    }
    
    let settings: UserDefaults
    let photoLibrary: PHPhotoLibrary

    private let cellProvider: (IndexPath, PHAsset) -> (UICollectionViewCell)
    private let imageManager: PHImageManager
    
    /// The source album the data source fetches assets from.
    private var sourceAssetCollection: PHAssetCollection?
    
    private var shouldAccessPhotoLibrary: Bool {
        PHPhotoLibrary.readWriteAuthorizationStatus != .notDetermined
    }
    
    private var isAccessingPhotoLibrary = false

    init(
        sourceAlbum: AnyAlbum? = nil,
        photoLibrary: PHPhotoLibrary = .shared(),
        imageManager: PHImageManager = .default(),
        settings: UserDefaults = .standard,
        cellProvider: @escaping (IndexPath, PHAsset) -> (UICollectionViewCell)
    ) {
        self.sourceAssetCollection = sourceAlbum?.assetCollection
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        self.settings = settings
        self.cellProvider = cellProvider

        super.init()
        
        startAccessingPhotoLibrary()
    }
    
    deinit {
        if isAccessingPhotoLibrary {
            photoLibrary.unregisterChangeObserver(self)
        }
    }
    
    /// Fetches the current album contents and starts observing it for changes, if the photo library
    /// authorization status is not `notDetermined`.
    ///
    /// Does nothing if the authorization status is `notDetermined`. This avoids triggering
    /// premature authorization dialogs when the data source is created. Instead, explicitly
    /// authorize access and call this method afterwards.
    func startAccessingPhotoLibrary() {
        guard shouldAccessPhotoLibrary,
              !isAccessingPhotoLibrary else { return }
        
        isAccessingPhotoLibrary = true
        photoLibrary.register(self)
        fetchAlbumContents(includingAlbum: true)
    }
    
    // MARK: Data Access
    
    /// When setting the album, the receiver synchronously (re-)fetches its contents.
    ///
    /// If the authorization status is `notDetermined`, does not perform the fetch.
    func setSourceAlbum(_ sourceAlbum: AnyAlbum) {
        sourceAssetCollection = sourceAlbum.assetCollection
        fetchAlbumContents(includingAlbum: true)
    }

    /// Precondition: `album != nil`.
    func video(at indexPath: IndexPath) -> PHAsset {
        album!.fetchResult.object(at: indexPath.item)
    }

    func thumbnail(for video: PHAsset, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) -> Cancellable {
        imageManager.requestImage(for: video, options: imageOptions, completionHandler: completionHandler)
    }

    func indexPath(of video: PHAsset) -> IndexPath? {
        guard let index = album?.fetchResult.index(of: video) else { return nil }
        return IndexPath(item: index, section: 0)
    }
    
    /// Fetches the current version for the given video.
    /// - Returns: The updated video or `nil` if it was deleted.
    func currentVideo(for video: PHAsset) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [video.localIdentifier], options: nil).firstObject
    }

    func toggleFavorite(for video: PHAsset) {
        photoLibrary.performChanges({
            PHAssetChangeRequest(for: video).isFavorite = !video.isFavorite
        }, completionHandler: nil)
    }

    func delete(_ video: PHAsset) {
        photoLibrary.performChanges({
            PHAssetChangeRequest.deleteAssets([video] as NSArray)
        }, completionHandler: nil)
    }

    // MARK: Fetching and Updating
    
    /// Synchronously fetches the album's assets.
    /// - Parameter includingAlbum: True to fetch an update for the album itself (i.e. its metadata).
    private func fetchAlbumContents(includingAlbum: Bool) {
        guard shouldAccessPhotoLibrary else { return }
        
        guard let sourceAlbum = sourceAssetCollection else {
            album = nil
            albumChangedHandler?(nil)
            videosChangedHandler?(nil)
            return
        }
        
        let fetchOptions = PHFetchOptions.assets(
            forAlbumType: sourceAlbum.assetCollectionType,
            videoFilter: filter
        )
                
        let updatedAlbum = includingAlbum
            ? FetchedAlbum.fetchUpdate(for: sourceAlbum, assetFetchOptions: fetchOptions)
            : FetchedAlbum.fetchAssets(in: sourceAlbum, options: fetchOptions)
                    
        sourceAssetCollection = updatedAlbum?.assetCollection
        album = updatedAlbum
        
        albumChangedHandler?(album)
        videosChangedHandler?(nil)
    }
    
    private func updateAlbum(with change: PHChange) {
        guard let oldAlbum = album,
            let changeDetails = change.changeDetails(for: oldAlbum) else { return }

        let newAlbum = changeDetails.albumAfterChanges
        sourceAssetCollection = newAlbum?.assetCollection
        album = newAlbum

        guard newAlbum != nil else {
            albumChangedHandler?(nil)
            videosChangedHandler?(nil)
            return
        }

        if changeDetails.assetCollectionChanges != nil {
            albumChangedHandler?(newAlbum)
        }

        if let videoChange = changeDetails.fetchResultChanges {
            videosChangedHandler?(videoChange)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension AlbumCollectionViewDataSource: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        album?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellProvider(indexPath, video(at: indexPath))
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension AlbumCollectionViewDataSource: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(_ change: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.updateAlbum(with: change)
        }
    }
}
