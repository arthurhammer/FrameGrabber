import UIKit

extension LibraryGridViewController: ZoomTransitionDelegate {
    
    func wantsZoomTransition(for type: TransitionType) -> Bool {
        (type == .pop) || (transitionAsset != nil)
    }

    func zoomTransitionWillBegin(_ transition: ZoomTransition) {
        select(asset: transitionAsset, animated: false)
        collectionView?.scrollSelectedCellIntoViewIfNeeded(animated: false)
        collectionView?.selectedCell?.isHidden = true
    }

    func zoomTransitionView(_ transition: ZoomTransition) -> UIView? {
        select(asset: transitionAsset, animated: false)
        collectionView?.scrollSelectedCellIntoViewIfNeeded(animated: false)
        return (collectionView?.selectedCell as? VideoCell)?.imageView
    }

    func zoomTransitionDidEnd(_ transition: ZoomTransition) {
        // Also unhide after push in case we'll use fallback animation later.
        collectionView?.selectedCell?.isHidden = false

        if transition.type == .pop {
            (collectionView.selectedCell as? VideoCell)?.fadeInOverlays()
        }
    }
}

// MARK: - Util

private extension UICollectionView {

    var selectedCell: UICollectionViewCell? {
        indexPathsForSelectedItems?.first.flatMap(cellForItem)
    }

    func scrollSelectedCellIntoViewIfNeeded(animated: Bool) {
        guard let selection = indexPathsForSelectedItems?.first else { return }
        scrollCellIntoViewIfNeeded(at: selection, animated: animated)
    }
    
    func scrollCellIntoViewIfNeeded(at indexPath: IndexPath, animated: Bool) {
        guard let position = closestScrollPosition(for: indexPath) else { return }
        scrollToItem(at: indexPath, at: position, animated: animated)
        layoutIfNeeded()
    }

    /// `nil` for fully visible cells, otherwise `top` or `bottom` whichever is closer, taking into
    /// account the receiver's safe area.
    ///
    /// Assumes a vertical layout with an ordering between items, like a standard grid-column layout.
    func closestScrollPosition(for indexPath: IndexPath) -> UICollectionView.ScrollPosition? {
        // Partially visible cells.
        if let cell = cellForItem(at: indexPath) {
            let cellFrame = (cell.superview ?? self).convert(cell.frame, to: superview)

            if cellFrame.minY < safeFrame.minY {
                return .top
            }

            if cellFrame.maxY > safeFrame.maxY {
                return .bottom
            }
        }

        // Dequeued/offscreen cells.
        let visible = indexPathsForVisibleItems.sorted()

        if let firstVisible = visible.first, indexPath < firstVisible {
            return .top
        }

        if let lastVisible = visible.last, indexPath > lastVisible {
            return .bottom
        }

        // Fully visible cells.
        return nil
    }

    var safeFrame: CGRect {
        frame.inset(by: adjustedContentInset)
    }
}
