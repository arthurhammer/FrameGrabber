import UIKit

extension LibraryViewController: ZoomTransitionDelegate {
    
    func wantsZoomTransition(for type: TransitionType) -> Bool {
        (type == .pop) || (zoomTransitionAsset != nil)
    }

    func zoomTransitionWillBegin(_ transition: ZoomTransition) {
        scrollToTransitionCell()
        transitionCell?.isHidden = true
    }

    func zoomTransitionView(_ transition: ZoomTransition) -> UIView? {
        scrollToTransitionCell()
        return (transitionCell as? LibraryGridCell)?.imageView
    }

    func zoomTransitionDidEnd(_ transition: ZoomTransition) {
        transitionCell?.isHidden = false

        if transition.type == .pop {
            (transitionCell as? LibraryGridCell)?.fadeInOverlays()
        }
    }
}

// MARK: - Util
    
private extension LibraryViewController {
    
    var transitionCell: UICollectionViewCell? {
        transitionIndexPath.flatMap { gridController?.collectionView?.cellForItem(at: $0) }
    }
    
    var transitionIndexPath: IndexPath? {
        zoomTransitionAsset.flatMap(dataSource.indexPath(of:))
    }
    
    func scrollToTransitionCell() {
        guard let indexPath = transitionIndexPath else { return }
        gridController?.collectionView?.scrollCellIntoViewIfNeeded(at: indexPath, animated: false)
    }
}

private extension UICollectionView {

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
