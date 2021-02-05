import Combine
import Photos
import UIKit


class AlbumCollectionViewDataSource: NSObject {
        
    private(set) var album: PHAssetCollection?
    private var assets: PHFetchResult<PHAsset>?

    /// Called when the album itself (its metadata) has changed.
    var albumChangedHandler: ((PHAssetCollection?) -> ())?
    
    /// Called when the contents of the album have changed.
    var videosChangedHandler: (() -> ())?
    
    /// When setting the filter, the album contents are updated asynchronously. During the update
    /// the data source keeps reporting the old data to the collection view. See also: `setAlbum()`.
    var filter: PhotoLibraryFilter {
        get { settings.photoLibraryFilter }
        set {
            settings.photoLibraryFilter = newValue
            fetchAssets()
        }
    }
    
    var gridContentMode: AlbumGridContentMode {
        get { settings.albumGridContentMode }
        set { settings.albumGridContentMode = newValue }
    }

    var imageOptions = PHImageManager.ImageOptions()
    
    var isEmpty: Bool {
        (assets?.count ?? 0) == 0
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
    private let updateQueue: DispatchQueue
    private let imageManager: PHImageManager
    
    init(
        photoLibrary: PHPhotoLibrary = .shared(),
        imageManager: PHImageManager = .default(),
        settings: UserDefaults = .standard,
        updateQueue: DispatchQueue = .init(label: "", qos: .userInitiated),
        cellProvider: @escaping (IndexPath, PHAsset) -> (UICollectionViewCell)
    ) {
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        self.settings = settings
        self.updateQueue = updateQueue
        self.cellProvider = cellProvider

        super.init()
        
        startAccessingPhotoLibraryIfNeeded()
    }
    
    deinit {
        if isAccessingPhotoLibrary {
            photoLibrary.unregisterChangeObserver(self)
        }
    }
    
    // MARK: - Authorization
    
    private var isAccessingPhotoLibrary = false
    
    private func startAccessingPhotoLibraryIfNeeded() {
        guard PHPhotoLibrary.readWriteAuthorizationStatus != .notDetermined,
              !isAccessingPhotoLibrary else { return }
        
        isAccessingPhotoLibrary = true
        photoLibrary.register(self)
    }
    
    // MARK: Data Access

    /// When setting the album, the data source asynchronously fetches the assets in the album.
    /// While the update is in progress, the data source still keeps reporting the old album
    /// contents in the collection view data source methods and functions such as `video(at:)`,
    /// `indexPath(of:)`. This is to allow a seamless transition between both states in the view.
    ///
    /// When the data source is created and the photo library authorization status is
    /// `.notDetermined`, it holds off accessing the photo library until this method is called for
    /// the first time. This avoids triggering premature authorization dialogs.
    func setAlbum(_ album: PHAssetCollection) {
        startAccessingPhotoLibraryIfNeeded()
        
        self.album = album
        albumChangedHandler?(album)  // Propagate current state.
        fetchAlbum()  // Fetch new state.
        fetchAssets()
    }

    /// Precondition: `indexPath` is valid according to `numberOfItemsInSection`.
    func video(at indexPath: IndexPath) -> PHAsset {
        assets!.object(at: indexPath.item)
    }

    func thumbnail(for video: PHAsset, completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) -> Cancellable {
        imageManager.requestImage(for: video, options: imageOptions, completionHandler: completionHandler)
    }

    func indexPath(of video: PHAsset) -> IndexPath? {
        guard let index = assets?.index(of: video) else { return nil }
        return IndexPath(item: index, section: 0)
    }
    
    /// Synchronously fetches the current version for the given video.
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

    // MARK: Fetching

    private func fetchAlbum() {
        guard isAccessingPhotoLibrary else { return }
            
        guard let albumID = album?.localIdentifier else {
            albumChangedHandler?(nil)
            return
        }
        
        updateQueue.async { [weak self] in
            let result = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumID],
                options: nil
            ).firstObject
         
            DispatchQueue.main.async {
                self?.album = result
                self?.albumChangedHandler?(result)
            }
        }
    }
    
    private func fetchAssets() {
        guard isAccessingPhotoLibrary else { return }
        
        guard let album = album else {
            videosChangedHandler?()
            return
        }
        
        updateQueue.async { [weak self, filter = self.filter] in
            let result = PHAsset.fetchAssets(in: album, options: .assets(filteredBy: filter))
         
            DispatchQueue.main.async {
                self?.assets = result
                self?.videosChangedHandler?()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension AlbumCollectionViewDataSource: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assets?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellProvider(indexPath, video(at: indexPath))
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension AlbumCollectionViewDataSource: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(_ change: PHChange) {
        DispatchQueue.main.async { [weak self] in
            // All updates go through the queue. Enqueue a new fetch instead of taking the values
            // provided by the change details directly. This ensures proper update serialization.
            if let oldAlbum = self?.album,
               change.changeDetails(for: oldAlbum) != nil {
                
                self?.fetchAlbum()
            }
            
            if let assets = self?.assets,
               change.changeDetails(for: assets) != nil {
                
                self?.fetchAssets()
            }
        }
    }
}
