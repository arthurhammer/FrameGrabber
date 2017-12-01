import UIKit
import Photos

protocol CollectionViewPhotoLibraryChangeUpdaterDelegate: class {
    func changeUpdater(_ updater: CollectionViewPhotoLibraryChangeUpdater, willApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>)
    func changeUpdater(_ updater: CollectionViewPhotoLibraryChangeUpdater, didApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>)
}

extension CollectionViewPhotoLibraryChangeUpdaterDelegate {
    func changeUpdater(_ updater: CollectionViewPhotoLibraryChangeUpdater, willApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>) {}
    func changeUpdater(_ updater: CollectionViewPhotoLibraryChangeUpdater, didApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>) {}
}

/// Observes Photo Library changes from a `PHFetchResult` and applies them to a collection view.
/// Supports a single section only.
class CollectionViewPhotoLibraryChangeUpdater {

    weak var delegate: CollectionViewPhotoLibraryChangeUpdaterDelegate?

    var fetchResult: PHFetchResult<PHAsset> {
        return observer.fetchResult
    }

    init(collectionView: UICollectionView, fetchResult: PHFetchResult<PHAsset>) {
        self.collectionView = collectionView
        self.observer = PHFetchResultChangeObserver(fetchResult: fetchResult)

        self.observer.changeHandler = { [unowned self] _, details in
            self.delegate?.changeUpdater(self, willApplyPhotoLibraryChanges: details)
            self.performBatchUpdates(for: details)
            self.delegate?.changeUpdater(self, didApplyPhotoLibraryChanges: details)
        }
    }

    // MARK: - Private

    private let observer: PHFetchResultChangeObserver<PHAsset>
    private weak var collectionView: UICollectionView?

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

private extension IndexSet {
    /// An array of `IndexPath`s from an `IndexSet` with sections set to 0.
    var indexPaths: [IndexPath] {
        return map { IndexPath(item: $0, section: 0) }
    }
}
