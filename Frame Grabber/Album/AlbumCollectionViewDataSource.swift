import Combine
import PhotoAlbums
import Photos
import UIKit

class AlbumCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, PHPhotoLibraryChangeObserver {

    /// nil if deleted.
    private(set) var album: FetchedAlbum?

    var filter: VideoTypesFilter {
        get { settings.videoTypesFilter }
        set {
            settings.videoTypesFilter = newValue
            fetchAlbum()
        }
    }

    var isEmpty: Bool {
        album?.isEmpty ?? true
    }

    var albumDeletedHandler: (() -> ())?
    var albumChangedHandler: (() -> ())?
    var videosChangedHandler: ((PHFetchResultChangeDetails<PHAsset>?) -> ())?

    var imageOptions: PHImageManager.ImageOptions {
        didSet {
            guard imageOptions != oldValue else { return }
            imageManager.stopCachingImagesForAllAssets()
        }
    }

    var isAuthorizationLimited: Bool {
        false
    }

    var settings: UserDefaults
    let photoLibrary: PHPhotoLibrary

    private let cellProvider: (IndexPath, PHAsset) -> (UICollectionViewCell)
    private let imageManager: PHCachingImageManager
    private let filterQueue: DispatchQueue

    init(album: FetchedAlbum?,
         photoLibrary: PHPhotoLibrary = .shared(),
         imageManager: PHCachingImageManager = .init(),
         imageOptions: PHImageManager.ImageOptions = .init(size: .zero, mode: .aspectFill, requestOptions: .default()),
         settings: UserDefaults = .standard,
         filterQueue: DispatchQueue = .init(label: "", qos: .userInteractive, attributes: []),
         cellProvider: @escaping (IndexPath, PHAsset) -> (UICollectionViewCell)) {

        self.album = album
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        self.imageOptions = imageOptions
        self.settings = settings
        self.filterQueue = filterQueue
        self.cellProvider = cellProvider

        super.init()

        photoLibrary.register(self)
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
        imageManager.stopCachingImagesForAllAssets()
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

    private func fetchAlbum() {
        guard let album = album?.assetCollection else { return }
        let filter = self.filter

        filterQueue.async { [weak self] in
            let fetchOptions = PHFetchOptions.assets(forAlbumType: album.assetCollectionType, videoFilter: filter)
            let filteredAlbum = FetchedAlbum.fetchUpdate(for: album, assetFetchOptions: fetchOptions)

            DispatchQueue.main.async {
                self?.album = filteredAlbum
                self?.videosChangedHandler?(nil)
            }
        }
    }

    private func safeVideos(at indexPaths: [IndexPath]) -> [PHAsset] {
        guard let fetchResult = album?.fetchResult else { return [] }
        let indexes = IndexSet(indexPaths.map { $0.item })
        let safeIndexes = indexes.filteredIndexSet { $0 < fetchResult.count }
        return fetchResult.objects(at: safeIndexes)
    }
}

extension AlbumCollectionViewDataSource {

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        album?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        cellProvider(indexPath, video(at: indexPath))
    }

    // MARK: UICollectionViewDataSourcePrefetching

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

extension AlbumCollectionViewDataSource {

    func photoLibraryDidChange(_ change: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.updateAlbum(with: change)
        }
    }

    private func updateAlbum(with change: PHChange) {
        guard let oldAlbum = album,
            let changeDetails = change.changeDetails(for: oldAlbum) else { return }

        self.album = changeDetails.albumAfterChanges

        guard changeDetails.albumAfterChanges != nil else {
            imageManager.stopCachingImagesForAllAssets()
            albumDeletedHandler?()
            return
        }

        if changeDetails.assetCollectionChanges != nil {
            albumChangedHandler?()
        }

        if let videoChange = changeDetails.fetchResultChanges {
            imageManager.stopCachingImagesForAllAssets()
            videosChangedHandler?(videoChange)
        }
    }
}
