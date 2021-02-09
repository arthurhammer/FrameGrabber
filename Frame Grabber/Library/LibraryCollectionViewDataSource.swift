import Combine
import Photos
import UIKit

class LibraryCollectionViewDataSource: NSObject, PHPhotoLibraryChangeObserver {
    
    @Published private(set) var album: PHAssetCollection?
    @Published private(set) var assetsChanged: Void = ()
    /// Whether the data source is loading updates for the album or its contents.
    @Published private(set) var isUpdating: Bool = false

    /// When setting the filter, the album contents are updated asynchronously. During the update
    /// the data source keeps reporting the old assets to the collection view. See also: `setAlbum()`.
    var filter: PhotoLibraryFilter {
        get { settings.photoLibraryFilter }
        set {
            settings.photoLibraryFilter = newValue
            fetchAssets()
        }
    }
    
    var gridMode: LibraryGridMode {
        get { settings.libraryGridMode }
        set { settings.libraryGridMode = newValue }
    }

    var imageOptions = PHImageManager.ImageOptions()
    
    var isEmpty: Bool {
        assets?.isEmpty ?? true
    }

    var isAuthorizationLimited: Bool {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited
        } else {
            return false
        }
    }
        
    private var assets: ReversibleFetchResult? {
        didSet { assetsChanged = () }
    }
    
    private let cellProvider: (IndexPath, PHAsset) -> (UICollectionViewCell)
    private let settings: UserDefaults
    private let updateQueue: DispatchQueue
    private let imageManager: PHImageManager = .default()
    let photoLibrary: PHPhotoLibrary = .shared()
    
    init(
        settings: UserDefaults = .standard,
        updateQueue: DispatchQueue = .init(label: "", qos: .userInitiated),
        cellProvider: @escaping (IndexPath, PHAsset) -> (UICollectionViewCell)
    ) {
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
    func setAlbum(_ newAlbum: PHAssetCollection) {
        startAccessingPhotoLibraryIfNeeded()
        album = newAlbum
        fetchAssets()
    }

    func video(at indexPath: IndexPath) -> PHAsset? {
        assets?.asset(at: indexPath.item)
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

    // MARK: Fetching and Updating
    
    // todo: Extract the fetching logic.
    
    private func fetchUpdate(for album: PHAssetCollection?) -> PHAssetCollection? {
        guard let id = album?.localIdentifier else { return nil }
        return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil)
            .firstObject
    }
    
    private var tasks = 0 {
        didSet { isUpdating = tasks > 0 }
    }

    private func fetchAssets() {
        guard isAccessingPhotoLibrary else { return }

        tasks += 1
        
        updateQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Get the actual current state.
            let (album, filter) = DispatchQueue.main.sync { (self.album, self.filter) }
            
            guard let sourceAlbum = album else {
                DispatchQueue.main.sync {
                    self.tasks -= 1
                    self.assets = nil
                }
                return
            }
            
            let fetchResult = PHAsset.fetchAssets(in: sourceAlbum, options: .assets(filteredBy: filter))
            let isSmartAlbum = (sourceAlbum.assetCollectionType == .smartAlbum)
            let assets = ReversibleFetchResult(fetchResult: fetchResult, isReversed: isSmartAlbum)
         
            // Block until the new state is committed.
            DispatchQueue.main.sync {
                self.tasks -= 1
                // Ditch outdated results.
                guard sourceAlbum.localIdentifier == self.album?.localIdentifier else { return }
                self.assets = assets
            }
        }
    }
    
    func photoLibraryDidChange(_ change: PHChange) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            var albumWasDeleted = false
            
            if let currentAlbum = self.album,
               change.changeDetails(for: currentAlbum) != nil {
                
                // Manually refetch the current state.
                self.album = self.fetchUpdate(for: currentAlbum)
                albumWasDeleted = self.album == nil
            }
            
            let assetsChanged = (self.assets?.getFetchResult()).flatMap(change.changeDetails) != nil
            
            if albumWasDeleted || assetsChanged {
                self.fetchAssets()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension LibraryCollectionViewDataSource: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        assets?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let video = video(at: indexPath) else { preconditionFailure("Invalid index.") }
        return cellProvider(indexPath, video)
    }
}
