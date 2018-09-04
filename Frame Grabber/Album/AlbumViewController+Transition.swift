import UIKit

extension AlbumViewController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        if animator.type == .dismiss {
            collectionView?.scrollSelectedCellIntoViewIfNeeded(animated: false)
            // Seems to be necessary once more for offscreen cells.
            collectionView?.layoutIfNeeded()
        }

        collectionView?.selectedCell?.isHidden = true
    }

    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        guard let selectedCell = collectionView?.selectedCell as? VideoCell else { return nil }

        return selectedCell.imageView.image
    }

    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        guard let selectedCell = collectionView?.selectedCell else { return nil }
        return selectedCell.superview?.convert(selectedCell.frame, to: view) ?? .zero
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        // Also unhide after presentation in case we'll use fallback animation later.
        collectionView?.selectedCell?.isHidden = false

        if animator.type == .dismiss {
            collectionView?.clearSelection()
        }
    }
}

// MARK: - Util

private extension UICollectionView {

    var selectedCell: UICollectionViewCell? {
        return indexPathsForSelectedItems?.first.flatMap(cellForItem)
    }

    func clearSelection(animated: Bool = false) {
        selectItem(at: nil, animated: animated, scrollPosition: .top)
    }

    func scrollSelectedCellIntoViewIfNeeded(animated: Bool) {
        guard let selectedIndexPath = indexPathsForSelectedItems?.first,
            let position = scrollPosition(for: selectedIndexPath) else { return }

        scrollToItem(at: selectedIndexPath, at: position, animated: animated)
    }

    /// nil for fully visible cells, otherwise `top` or `bottom` whichever is closer.
    func scrollPosition(for indexPath: IndexPath) -> UICollectionViewScrollPosition? {
        // Partially visible cells.
        if let cell = cellForItem(at: indexPath) {
            let cellFrame = convert(cell.frame, to: superview ?? self)

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
        return UIEdgeInsetsInsetRect(frame, adjustedContentInset)
    }
}
