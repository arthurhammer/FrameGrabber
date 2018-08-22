import UIKit
import Photos

/*
 Apple's sample code in `PHPhotoLibraryChangeObserver` can lead to collection view
 internal inconsistency exceptions for various updates. The following adaptions seem to
 remove many exceptions...
 */

extension UICollectionView {

    func applyPhotoLibraryChanges<T>(for changes: PHFetchResultChangeDetails<T>, in section: Int = 0) {
        guard changes.hasIncrementalChanges else {
            reloadData()
            return
        }

        let removed = changes.removedIndexes
        let inserted = changes.insertedIndexes
        var changed = changes.changedIndexes

        // Overlapping changed with removed indexes is a major source for exceptions.
        if let removed = removed {
            changed?.subtract(removed)
        }

        // According to Apple, updates must be in this order:
        // delete, insert, reload, move.
        performBatchUpdates({
            if let removed = removed, !removed.isEmpty {
                deleteItems(at: removed.indexPaths(in: section))
            }

            if let inserted = inserted, !inserted.isEmpty {
                insertItems(at: inserted.indexPaths(in: section))
            }

            if let changed = changed, !changed.isEmpty {
                reloadItems(at: changed.indexPaths(in: section))
            }
        })

        // Applying moves separately seems to reduce exceptions significantly.
        performBatchUpdates({
            changes.enumerateMoves { from, to in
                self.moveItem(at: IndexPath(item: from, section: section),
                              to: IndexPath(item: to, section: section))
            }
        })
    }
}

extension IndexSet {
    func indexPaths(in section: Int = 0) -> [IndexPath] {
        return map { IndexPath(item: $0, section: section) }
    }
}
