import UIKit
import Photos

protocol PhotoLibraryCollectionViewUpdaterDelegate: class {
    func changeUpdater(_ updater: PhotoLibraryCollectionViewUpdater, willApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>)
    func changeUpdater(_ updater: PhotoLibraryCollectionViewUpdater, didApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>)
}

extension PhotoLibraryCollectionViewUpdaterDelegate {
    func changeUpdater(_ updater: PhotoLibraryCollectionViewUpdater, willApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>) {}
    func changeUpdater(_ updater: PhotoLibraryCollectionViewUpdater, didApplyPhotoLibraryChanges changes: PHFetchResultChangeDetails<PHAsset>) {}
}

/// Observes Photo Library changes from a `PHFetchResult` and applies them to a collection
/// view. Supports a single section only.
class PhotoLibraryCollectionViewUpdater {

    weak var delegate: PhotoLibraryCollectionViewUpdaterDelegate?
    weak var collectionView: UICollectionView?

    var fetchResult: PHFetchResult<PHAsset> {
        return observer.fetchResult
    }

    init(library: PHPhotoLibrary = .shared(), fetchResult: PHFetchResult<PHAsset>, collectionView: UICollectionView) {
        self.collectionView = collectionView
        self.observer = PhotoLibraryFetchResultObserver(library: library, fetchResult: fetchResult)

        self.observer.changeHandler = { [unowned self] _, changes in
            self.delegate?.changeUpdater(self, willApplyPhotoLibraryChanges: changes)
            self.applyChanges(changes)
            self.delegate?.changeUpdater(self, didApplyPhotoLibraryChanges: changes)
        }
    }

    // MARK: - Private

    private let observer: PhotoLibraryFetchResultObserver<PHAsset>

    private func applyChanges(_ changes: PHFetchResultChangeDetails<PHAsset>) {
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
