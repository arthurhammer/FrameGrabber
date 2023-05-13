import UIKit

extension UICollectionView {
    
    /// Reloads the collection view's data cross-dissolving the before and after visual states.
    ///
    /// This method can be used as an alternative to the animations performed by `reloadSections` or
    /// `performBatchUpdates`. Both have severe problems animating a collection view with a large
    /// number of items (~10k+, which is not uncommon e.g. in photo libraries).
    ///
    /// - Parameters:
    ///   - duration: has no effect if `animated` is `false`.
    ///   - completion: Called synchronously if `animated` is `false`, otherwise asynchronously.
    public func reloadData(animated: Bool, duration: TimeInterval = 0.2, completion: ((Bool) -> Void)? = nil) {
        if !animated {
            reloadData()
            completion?(false)
            return
        }
        
        UIView.transition(
            with: self,
            duration: duration,
            options: [
                .transitionCrossDissolve,
                .beginFromCurrentState,
                .allowUserInteraction
            ],
            animations: {
                self.reloadData()
            },
            completion: completion
        )
    }
}
