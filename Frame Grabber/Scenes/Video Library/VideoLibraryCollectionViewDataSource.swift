import UIKit
import Photos

// TODO: options/isNetworkAccessAllowed for PHCachingImageManager

protocol VideoLibraryCollectionViewDataSourceDelegate: class {
    func didChange()
}

class VideoLibraryCollectionViewDataSource: NSObject {

    typealias CellProvider = (IndexPath, PHAsset) -> (UICollectionViewCell)

    weak var delegate: VideoLibraryCollectionViewDataSourceDelegate?

    var fetchResult: PHFetchResult<PHAsset> {
        return updater.fetchResult
    }

    private let cellProvider: CellProvider
    private let updater: CollectionViewPhotoLibraryChangeUpdater
    private lazy var imageManager = PHCachingImageManager()
    private let thumbnailSize: CGSize

    init(collectionView: UICollectionView,
         fetchResult: PHFetchResult<PHAsset> = PHAsset.videos(),
         thumbnailSize: CGSize,
         cellProvider: @escaping CellProvider) {

        self.thumbnailSize = thumbnailSize
        self.cellProvider = cellProvider
        self.updater = CollectionViewPhotoLibraryChangeUpdater(collectionView: collectionView, fetchResult: fetchResult)

        super.init()

        collectionView.isPrefetchingEnabled = true
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        self.updater.delegate = self
    }

    var isEmpty: Bool {
        return fetchResult.isEmpty
    }

    func asset(at indexPath: IndexPath) -> PHAsset {
        return fetchResult.object(at: indexPath.item)
    }

    func assets(at indexPaths: [IndexPath]) -> [PHAsset] {
        return fetchResult.objects(at: indexPaths.indexSet)
    }

    func thumbnail(for asset: PHAsset, resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> ()) -> ImageRequest {
        return ImageRequest(manager: imageManager,
                            asset: asset,
                            targetSize: thumbnailSize,
                            contentMode: .aspectFill,
                            options: .videoLibraryThumbnail(),
                            resultHandler: resultHandler)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDataSourcePrefetching

extension VideoLibraryCollectionViewDataSource: UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {

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
                                        options: .videoLibraryThumbnail())
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        imageManager.stopCachingImages(for: assets(at: indexPaths),
                                       targetSize: thumbnailSize,
                                       contentMode: .aspectFill,
                                       options: .videoLibraryThumbnail())
    }
}

// MARK: - CollectionViewPhotoLibraryChangeUpdaterDelegate

extension VideoLibraryCollectionViewDataSource: CollectionViewPhotoLibraryChangeUpdaterDelegate {

    func didApplyPhotoLibraryChanges(_ changes: PHFetchResultChangeDetails<PHAsset>) {
        // Assets changed, stop caching.
        // Caching resumes on next prefetch or images are generated directly.
        imageManager.stopCachingImagesForAllAssets()
        delegate?.didChange()
    }
}
