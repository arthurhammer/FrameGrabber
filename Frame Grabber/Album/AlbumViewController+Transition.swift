import UIKit

extension AlbumViewController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        guard animator.type == .dismiss else { return }

        collectionView?.scrollSelectedCellIntoViewIfNeeded(animated: false)
        // Seems to be necessary once more for offscreen cells.
        collectionView?.layoutIfNeeded()
    }

    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        guard let selectedCell = collectionView?.selectedCell as? VideoCell else { return nil }

        return selectedCell.imageView.image
    }

    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        guard let selectedCell = collectionView?.selectedCell else { return nil }

        return collectionView?.cellFrameClippedToSafeFrame(for: selectedCell, in: view)
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        guard animator.type == .dismiss else { return }

        collectionView?.clearSelection()
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

    func cellFrameClippedToSafeFrame(for cell: UICollectionViewCell, in view: UIView) -> CGRect {
        let cellFrame = (cell.superview ?? self).convert(cell.frame, to: view)
        let safeFrame = (superview ?? self).convert(self.safeFrame, to: view)
        return safeFrame.intersection(cellFrame)
    }
}
