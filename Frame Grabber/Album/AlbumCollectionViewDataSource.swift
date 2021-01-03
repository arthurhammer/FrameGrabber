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
        
    /// When setting the filter, the current album is asynchronously refetched with the new filter.
    ///
    /// If the authorization status is `notDetermined`, does not perform the fetch.
    ///
    /// - Note: The `album` property is updated only after the asynchronous fetch has finished,
    ///         reported to the callback handlers.
    var filter: VideoTypesFilter {
        get { settings.videoTypesFilter }
        set {
            settings.videoTypesFilter = newValue
            fetchAlbum()
        }
    }
    
    var gridContentMode: AlbumGridContentMode {
        get { settings.albumGridContentMode }
        set { settings.albumGridContentMode = newValue }
    }

    var imageOptions: PHImageManager.ImageOptions {
        didSet {
            guard imageOptions != oldValue else { return }
            imageManager.stopCachingImagesForAllAssets()
        }
    }
    
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
    private let imageManager: PHCachingImageManager
    private let fetchQueue: DispatchQueue
    
    /// The source album the data source fetches assets from.
    private var sourceAssetCollection: PHAssetCollection?
    
    private var shouldAccessPhotoLibrary: Bool {
        PHPhotoLibrary.readWriteAuthorizationStatus != .notDetermined
    }
    
    private var isAccessingPhotoLibrary = false

    init(
        sourceAlbum: AnyAlbum? = nil,
        photoLibrary: PHPhotoLibrary = .shared(),
        imageManager: PHCachingImageManager = .init(),
        imageOptions: PHImageManager.ImageOptions = .init(size: .zero, mode: .aspectFill, requestOptions: .default()),
        settings: UserDefaults = .standard,
        fetchQueue: DispatchQueue = .init(label: "", qos: .userInteractive, attributes: []),
        cellProvider: @escaping (IndexPath, PHAsset) -> (UICollectionViewCell)
    ) {
        self.sourceAssetCollection = sourceAlbum?.assetCollection
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        self.imageOptions = imageOptions
        self.settings = settings
        self.fetchQueue = fetchQueue
        self.cellProvider = cellProvider

        super.init()
        
        startAccessingPhotoLibrary()
    }
    
    deinit {
        if isAccessingPhotoLibrary {
            photoLibrary.unregisterChangeObserver(self)
        }
        imageManager.stopCachingImagesForAllAssets()
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
        fetchAlbum()
    }
    
    // MARK: Data Access
    
    /// When setting the album, the receiver asynchronously (re-)fetches its contents.
    ///
    /// If the authorization status is `notDetermined`, does not perform the fetch.
    ///
    /// - Note: The `album` property is updated only after the asynchronous fetch has finished,
    ///         reported to the callback handlers.
    func setSourceAlbum(_ sourceAlbum: AnyAlbum) {
        sourceAssetCollection = sourceAlbum.assetCollection
        fetchAlbum()
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
    
    private func safeVideos(at indexPaths: [IndexPath]) -> [PHAsset] {
        guard let fetchResult = album?.fetchResult else { return [] }
        
        let indexes = IndexSet(indexPaths.map { $0.item })
        let safeIndexes = indexes.filteredIndexSet { $0 < fetchResult.count }
        return fetchResult.objects(at: safeIndexes)
    }
    
    // MARK: Fetching and Updating

    private func fetchAlbum() {
        guard shouldAccessPhotoLibrary else { return }
        
        guard let sourceAlbum = sourceAssetCollection else {
            album = nil
            albumChangedHandler?(nil)
            videosChangedHandler?(nil)
            return
        }

        let filter = self.filter

        fetchQueue.async { [weak self] in
            let fetchOptions = PHFetchOptions.assets(
                forAlbumType: sourceAlbum.assetCollectionType,
                videoFilter: filter
            )
            
            let filteredAlbum = FetchedAlbum.fetchUpdate(
                for: sourceAlbum,
                assetFetchOptions: fetchOptions
            )

            DispatchQueue.main.async {
                self?.sourceAssetCollection = filteredAlbum?.assetCollection
                self?.album = filteredAlbum
                self?.albumChangedHandler?(nil)
                self?.videosChangedHandler?(nil)
            }
        }
    }
    
    private func updateAlbum(with change: PHChange) {
        guard let oldAlbum = album,
            let changeDetails = change.changeDetails(for: oldAlbum) else { return }

        let newAlbum = changeDetails.albumAfterChanges
        sourceAssetCollection = newAlbum?.assetCollection
        album = newAlbum

        guard newAlbum != nil else {
            imageManager.stopCachingImagesForAllAssets()
            albumChangedHandler?(nil)
            videosChangedHandler?(nil)
            return
        }

        if changeDetails.assetCollectionChanges != nil {
            albumChangedHandler?(newAlbum)
        }

        if let videoChange = changeDetails.fetchResultChanges {
            imageManager.stopCachingImagesForAllAssets()
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

// MARK: - UICollectionViewDataSourcePrefetching

extension AlbumCollectionViewDataSource: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Index paths might not exist anymore in the model.
        let videos = safeVideos(at: indexPaths)
        imageManager.startCachingImages(for: videos, targetSize: imageOptions.size, contentMode: imageOptions.mode, options: imageOptions.requestOptions)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let videos = safeVideos(at: indexPaths)
        imageManager.stopCachingImages(for: videos, targetSize: imageOptions.size, contentMode: imageOptions.mode, options: imageOptions.requestOptions)
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
