import UIKit
import Photos

struct ImageConfig {
    var size: CGSize = .zero
    var mode: PHImageContentMode = .aspectFill
    var options: PHImageRequestOptions? = .default()
}

class VideosCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, PHPhotoLibraryChangeObserver {

    typealias CellProvider = (IndexPath, PHAsset) -> (UICollectionViewCell)
    typealias ChangeHandler = (PHFetchResultChangeDetails<PHAsset>) -> ()

    private(set) var videos: PHFetchResult<PHAsset>
    var videosChangedHandler: ChangeHandler?

    var imageConfig: ImageConfig {
        didSet { imageManager.stopCachingImagesForAllAssets() }
    }

    private let photoLibrary: PHPhotoLibrary
    private let imageManager: PHCachingImageManager
    private let cellProvider: CellProvider

    init(videos: PHFetchResult<PHAsset> = PHAsset.fetchVideos(),
         photoLibrary: PHPhotoLibrary = .shared(),
         imageManager: PHCachingImageManager = .init(),
         imageConfig: ImageConfig = .init(),
         cellProvider: @escaping CellProvider) {

        self.videos = videos
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        self.imageConfig = imageConfig
        self.cellProvider = cellProvider

        super.init()

        photoLibrary.register(self)
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }

    func video(at indexPath: IndexPath) -> PHAsset {
        return videos.object(at: indexPath.item)
    }

    func videos(at indexPaths: [IndexPath]) -> [PHAsset] {
        let indexSet = IndexSet(indexPaths.map { $0.item })
        return videos.objects(at: indexSet)
    }

    func thumbnail(for video: PHAsset, resultHandler: @escaping (UIImage?, ImageManagerRequest.Info) -> ()) -> ImageRequest {
        return ImageRequest(imageManager: imageManager,
                            asset: video,
                            targetSize: imageConfig.size,
                            contentMode: imageConfig.mode,
                            options: imageConfig.options,
                            resultHandler: resultHandler)
    }
}

extension VideosCollectionViewDataSource {

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellProvider(indexPath, video(at: indexPath))
    }

    // MARK: UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        imageManager.startCachingImages(for: videos(at: indexPaths),
                                        targetSize: imageConfig.size,
                                        contentMode: imageConfig.mode,
                                        options: imageConfig.options)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        imageManager.stopCachingImages(for: videos(at: indexPaths),
                                       targetSize: imageConfig.size,
                                       contentMode: imageConfig.mode,
                                       options: imageConfig.options)
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension VideosCollectionViewDataSource {

    func photoLibraryDidChange(_ change: PHChange) {
        DispatchQueue.main.async { [weak self] in
            guard let this = self,
                let details = change.changeDetails(for: this.videos) else { return }
            this.handlePhotoLibraryChange(for: details)
        }
    }

    private func handlePhotoLibraryChange(for details: PHFetchResultChangeDetails<PHAsset>) {
        videos = details.fetchResultAfterChanges
        imageManager.stopCachingImagesForAllAssets()
        videosChangedHandler?(details)
    }
}
