import UIKit

extension UICollectionView {
    
    /// Reloads the collection view's data cross-dissolving the before and after visual states.
    ///
    /// This method can be used as an alternative to the animations performed by `reloadSections` or
    /// `performBatchUpdates`. Both have severe problems animating a collection view with a large
    /// number of items (~10k+, which is not uncommon e.g. in photo libraries).
    ///
    /// The animation is performed by inserting a simple snapshot of the collection view's before
    /// state into its superview, performing the reload, then cross-dissolving the snapshot into the
    /// after state. If a snapshot could not be created or the superview does not exist, reloads
    /// without animation.
    ///
    /// - Precondition: You are responsible for ensuring that it is safe to modify the superview's
    ///   view hierarchy by temporarily inserting a snapshot view.
    func reloadDataAnimated(
        withDuration duration: TimeInterval = 0.35,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard let snapshot = snapshotView(afterScreenUpdates: false),  // `false` is key.
              let superview = superview else {

            reloadData()
            completion?(false)
            return
        }
                
        superview.insertSubview(snapshot, aboveSubview: self)
        
        reloadData()

        UIView.transition(
            from: snapshot,
            to: self,
            duration: duration,
            options: [
                .transitionCrossDissolve,
                .showHideTransitionViews,
                .beginFromCurrentState,
                .allowUserInteraction
            ],
            completion: {
                snapshot.removeFromSuperview()
                completion?($0)
            }
        )
    }
}
