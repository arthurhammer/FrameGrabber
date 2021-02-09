import UIKit

extension LibraryViewController: ZoomTransitionDelegate {
    
    func wantsZoomTransition(for type: TransitionType) -> Bool {
        // Only push if we have a source view. Always allow pop.
        (type == .pop) || (transitionAsset != nil)
    }

    func zoomTransitionWillBegin(_ transition: ZoomTransition) {
        if transition.type == .pop {
            select(asset: transitionAsset, animated: false)
            collectionView?.scrollSelectedCellIntoViewIfNeeded(animated: false)
        }

        collectionView?.selectedCell?.isHidden = true
    }

    func zoomTransitionView(_ transition: ZoomTransition) -> UIView? {
        // Might have once more been removed during interactive gesture.
        select(asset: transitionAsset, animated: false)
        collectionView?.scrollSelectedCellIntoViewIfNeeded(animated: false)

        return (collectionView?.selectedCell as? VideoCell)?.imageView
    }

    func zoomTransitionDidEnd(_ transition: ZoomTransition) {
        // Also unhide after presentation in case we'll use fallback animation later.
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

    func clearSelection(animated: Bool = false) {
        selectItem(at: nil, animated: animated, scrollPosition: .top)
    }

    func scrollSelectedCellIntoViewIfNeeded(animated: Bool) {
        guard let selectedIndexPath = indexPathsForSelectedItems?.first,
            let position = closestScrollPosition(for: selectedIndexPath) else { return }

        scrollToItem(at: selectedIndexPath, at: position, animated: animated)
        layoutIfNeeded()
    }

    /// nil for fully visible cells, otherwise `top` or `bottom` whichever is closer,
    /// taking into account the receiver's safe area.
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
