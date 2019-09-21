import UIKit

enum TransitionType {
    case present
    case dismiss
}

class ZoomTransitionController: NSObject, UIViewControllerTransitioningDelegate {

    /// Uses source or presenting controller if not set manually pre-transition.
    weak var from: ZoomAnimatable?

    /// Uses presented controller if not set manually pre-transition.
    weak var to: ZoomAnimatable?

    func prepareTransition(forSource source: UIViewController, destination: UIViewController) {
        destination.modalPresentationStyle = .fullScreen
        destination.transitioningDelegate = self
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        from = from ?? (source as? ZoomAnimatable) ?? (presenting as? ZoomAnimatable)
        to = to ?? (presented as? ZoomAnimatable)

        return ZoomAnimator(type: .present, from: from, to: to)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        ZoomAnimator(type: .dismiss, from: to, to: from)
    }
}
