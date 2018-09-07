import UIKit
import Photos

extension UICollectionView {

    /// - Note: https://developer.apple.com/documentation/photokit/phfetchresultchangedetails
    func applyPhotoLibraryChanges<T>(for changes: PHFetchResultChangeDetails<T>, in section: Int = 0, cellConfigurator: (IndexPath) -> ()) {
        guard changes.hasIncrementalChanges else {
            reloadData()
            return
        }

        // First, apply deletions and insertions.
        performBatchUpdates({
            if let removed = changes.removedIndexes, !removed.isEmpty {
                deleteItems(at: removed.indexPaths(in: section))
            }

            if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                insertItems(at: inserted.indexPaths(in: section))
            }
        })

        // Apply moves separately.
        performBatchUpdates({
            changes.enumerateMoves { from, to in
                self.moveItem(at: IndexPath(item: from, section: section),
                              to: IndexPath(item: to, section: section))
            }
        })

        // Changes refer to the final state. According to docs, cells should be 
        // reconfigured instead of reloaded.
        if let changed = changes.changedIndexes, !changed.isEmpty {
            changed.indexPaths(in: section).forEach(cellConfigurator)
        }
    }
}

extension IndexSet {
    func indexPaths(in section: Int = 0) -> [IndexPath] {
        return map { IndexPath(item: $0, section: section) }
    }
}
