import UIKit
import Photos

protocol CollectionViewPhotoLibraryChangeUpdaterDelegate: class {
    func willApplyPhotoLibraryChanges(_ changes: PHFetchResultChangeDetails<PHAsset>)
    func didApplyPhotoLibraryChanges(_ changes: PHFetchResultChangeDetails<PHAsset>)
}

extension CollectionViewPhotoLibraryChangeUpdaterDelegate {
    func willApplyPhotoLibraryChanges(_ changes: PHFetchResultChangeDetails<PHAsset>) {}
    func didApplyPhotoLibraryChanges(_ changes: PHFetchResultChangeDetails<PHAsset>) {}
}

/// Observes Photo Library changes from a `PHFetchResult` and applies them to a collection view.
class CollectionViewPhotoLibraryChangeUpdater {

    weak var delegate: CollectionViewPhotoLibraryChangeUpdaterDelegate?

    var fetchResult: PHFetchResult<PHAsset> {
        return observer.fetchResult
    }

    private let observer: PHFetchResultChangeObserver<PHAsset>
    private weak var collectionView: UICollectionView?

    init(collectionView: UICollectionView, fetchResult: PHFetchResult<PHAsset>) {
        self.collectionView = collectionView
        self.observer = PHFetchResultChangeObserver(fetchResult: fetchResult)

        self.observer.changeHandler = { [weak self] _, details in
            self?.delegate?.willApplyPhotoLibraryChanges(details)
            self?.performBatchUpdates(for: details)
            self?.delegate?.didApplyPhotoLibraryChanges(details)
        }
    }

    private func performBatchUpdates(for changes: PHFetchResultChangeDetails<PHAsset>) {
        guard changes.hasIncrementalChanges else {
            collectionView?.reloadData()
            return
        }

        // For indexes to make sense, updates must be in this order: delete, insert, reload, move
        collectionView?.performBatchUpdates({
            if let removed = changes.removedIndexes, !removed.isEmpty {
                collectionView?.deleteItems(at: removed.indexPaths)
            }

            if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                collectionView?.insertItems(at: inserted.indexPaths)
            }

            if let changed = changes.changedIndexes, !changed.isEmpty {
                collectionView?.reloadItems(at: changed.indexPaths)
            }

            changes.enumerateMoves { fromIndex, toIndex in
                self.collectionView?.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                              to: IndexPath(item: toIndex, section: 0))
            }
        })
    }
}
