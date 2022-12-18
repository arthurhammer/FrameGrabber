import Combine
import Photos
import Utility
import UIKit

class LibraryDataSource: NSObject, PHPhotoLibraryChangeObserver {
    
    /// Whether the data source is loading updates for the album or its contents.
    @Published private(set) var isUpdating: Bool = false
    
    /// The current photo album.
    ///
    /// When setting the album, the data source asynchronously fetches the assets in the album.
    /// While the update is in progress, the data source still keeps reporting the old album
    /// contents in `assets`, `video(at:)`, `indexPath(of:)` and related functions. This is to allow
    /// a seamless transition between both states in the view. You can use `isLoading` to track
    /// when `album` and `assets` are synchronized again. The same happens from internal updates
    /// such as when the photo library changes.
    ///
    /// When the data source is created and the photo library authorization status is
    /// `.notDetermined`, it holds off accessing the photo library until an album is set for
    /// the first time.
    ///
    /// The album becomes `nil` when it was deleted in the photo library.
    @Published var album: PHAssetCollection? {
        didSet {
            startAccessingPhotoLibraryIfNeeded()
            fetchAssets()
        }
    }
    
    /// When setting the filter, the album contents are updated asynchronously. See: `album`.
    @Published var filter: PhotoLibraryFilter {
        didSet {
            guard filter != oldValue else { return }
            settings.photoLibraryFilter = filter
            fetchAssets()
        }
    }
    
    @Published private(set) var assets: ReversibleFetchResult?
    
    @Published var gridMode: LibraryGridMode {
        didSet { settings.libraryGridMode = gridMode }
    }
    
    /// Whether the authorization is limited. When the status is either authorized or limited, this
    /// value is typically set once when the data source is created. When the status is
    /// `notDetermined`, the value changes the first time an album is set. See: `album`.
    @Published var isAuthorizationLimited = false
        
    let photoLibrary: PHPhotoLibrary = .shared()
    
    private let settings: UserDefaults
    private let updateQueue: DispatchQueue
    private let imageManager: PHImageManager = .default()
    
    init(
        settings: UserDefaults = .standard,
        updateQueue: DispatchQueue = .init(label: "", qos: .userInitiated)
    ) {
        self.settings = settings
        self.gridMode = settings.libraryGridMode
        self.filter = settings.photoLibraryFilter
        self.updateQueue = updateQueue

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
        guard PHPhotoLibrary.authorizationStatus(for: .readWrite) != .notDetermined,
              !isAccessingPhotoLibrary else { return }
        
        isAccessingPhotoLibrary = true
        photoLibrary.register(self)
        
        isAuthorizationLimited = PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited
    }
    
    // MARK: Data Access
    
    var isEmpty: Bool {
        numberOfAssets == 0
    }
    
    var numberOfAssets: Int {
        assets?.count ?? 0
    }

    func asset(at indexPath: IndexPath) -> PHAsset? {
        assets?.asset(at: indexPath.item)
    }

    func thumbnail(
        for asset: PHAsset,
        options: PHImageManager.ImageOptions,
        completionHandler: @escaping (UIImage?, PHImageManager.Info) -> ()
    ) -> Cancellable {
        
        imageManager.requestImage(
            for: asset,
            options: options,
            completionHandler: completionHandler
        )
    }

    func indexPath(of asset: PHAsset) -> IndexPath? {
        guard let index = assets?.index(of: asset) else { return nil }
        return IndexPath(item: index, section: 0)
    }
    
    /// Synchronously fetches the current version for the given asset.
    /// - Returns: The updated asset or `nil` if it was deleted.
    func currentAsset(for asset: PHAsset) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil).firstObject
    }

    func toggleFavorite(for asset: PHAsset) {
        photoLibrary.performChanges({
            PHAssetChangeRequest(for: asset).isFavorite = !asset.isFavorite
        }, completionHandler: nil)
    }

    func delete(_ asset: PHAsset) {
        photoLibrary.performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
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
            guard let self else { return }
            
            // Get the actual current state.
            let (album, filter) = DispatchQueue.main.sync { (self.album, self.filter) }
            
            guard let sourceAlbum = album else {
                DispatchQueue.main.sync {
                    self.tasks -= 1
                    self.assets = nil
                }
                return
            }
            
            let options = PHFetchOptions.assets(filteredBy: filter)
            let fetchResult = PHAsset.fetchAssets(in: sourceAlbum, options: options)
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
            guard let self else { return }
            
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
