import UIKit
import Photos

class VideosCollectionViewDataSource: NSObject {

    typealias CellProvider = (IndexPath, PHAsset) -> (UICollectionViewCell)

    var fetchResult: PHFetchResult<PHAsset> {
        return collectionViewUpdater.fetchResult
    }

    private let cellProvider: CellProvider
    private let collectionViewUpdater: PhotoLibraryCollectionViewUpdater
    private let imageManager: PHCachingImageManager
    private let thumbnailSize: CGSize

    init(collectionView: UICollectionView,
         fetchResult: PHFetchResult<PHAsset> = PHAsset.fetchVideos(),
         thumbnailSize: CGSize,
         imageManager: PHCachingImageManager = .init(),
         cellProvider: @escaping CellProvider) {

        self.thumbnailSize = thumbnailSize
        self.imageManager = imageManager
        self.cellProvider = cellProvider
        self.collectionViewUpdater = PhotoLibraryCollectionViewUpdater(fetchResult: fetchResult, collectionView: collectionView)

        super.init()

        self.collectionViewUpdater.delegate = self

        collectionView.isPrefetchingEnabled = true
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
    }

    var isEmpty: Bool {
        return fetchResult.count == 0
    }

    func asset(at indexPath: IndexPath) -> PHAsset {
        return fetchResult.object(at: indexPath.item)
    }

    func assets(at indexPaths: [IndexPath]) -> [PHAsset] {
        let indexSet = IndexSet(indexPaths.map { $0.item })
        return fetchResult.objects(at: indexSet)
    }

    func thumbnail(for asset: PHAsset, resultHandler: @escaping (UIImage?, ImageManagerRequest.Info) -> ()) -> ImageRequest {
        return ImageRequest(imageManager: imageManager,
                            asset: asset,
                            targetSize: thumbnailSize,
                            contentMode: .aspectFill,
                            options: .default(),
                            resultHandler: resultHandler)
    }

}

// MARK: - UICollectionViewDataSource, UICollectionViewDataSourcePrefetching

extension VideosCollectionViewDataSource: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellProvider(indexPath, asset(at: indexPath))
    }

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        imageManager.startCachingImages(for: assets(at: indexPaths),
                                        targetSize: thumbnailSize,
                                        contentMode: .aspectFill,
                                        options: .default())
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        imageManager.stopCachingImages(for: assets(at: indexPaths),
                                       targetSize: thumbnailSize,
                                       contentMode: .aspectFill,
                                       options: .default())
    }
}

// MARK: - CollectionViewPhotoLibraryChangeUpdaterDelegate

extension VideosCollectionViewDataSource: PhotoLibraryCollectionViewUpdaterDelegate {

    func changeUpdater(_ updater: PhotoLibraryCollectionViewUpdater, didApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>) {
        // Assets changed, stop caching.
        // Caching resumes on next prefetch or images are generated directly.
        imageManager.stopCachingImagesForAllAssets()
    }
}
