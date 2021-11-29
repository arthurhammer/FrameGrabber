import UIKit

typealias TransitionType = UINavigationController.Operation

/// A push or pop animator.
protocol ZoomTransition {

    var type: TransitionType { get }
    
    /// The delegate that provides the source view to animate from.
    var fromDelegate: ZoomTransitionDelegate? { get }
    
    /// The delegate that provides the target view to animate to.
    var toDelegate: ZoomTransitionDelegate? { get }

    /// Runs the specified animations within the same time and context as the transition
    /// animations.
    ///
    /// This method can be used to add additional animations that are not handled
    /// implicitly by the transition. For example, the `from` or `to` view controllers can
    /// fade or unfade UI elements.
    ///
    /// - Note: Ideally, `transitionCoordinator.animate(alongsideTransition:completion:)`
    /// could be used instead for this purpose but it does not seem to work for
    /// interactive transitions.
    func animate(alongsideTransition animation: @escaping (UIViewControllerContextTransitioning) -> (), completion: ((UIViewControllerContextTransitioning) -> ())?)
}

/// Provides source and/or target views for the push or pop animation.
protocol ZoomTransitionDelegate: AnyObject {

    /// `True` to proceed with the zoom transition, `false` to proceed with the default push/pop
    /// transition.
    ///
    /// Is called before `zoomTransitionWillBegin`. The zoom transition only begins when both
    /// delegates return `true`. The delegates can abort the zoom animation, e.g. when they can't
    /// provide source or target image views to animate from/to.
    func wantsZoomTransition(for type: TransitionType) -> Bool

    func zoomTransitionWillBegin(_ transition: ZoomTransition)
    
    /// If the delegate is the transition's `fromDelegate`, the source view that will be
    /// animated from. If the delegate is the transition's `toDelegate` return the target
    /// view that will be animated to.
    func zoomTransitionView(_ transition: ZoomTransition) -> UIView?

    func zoomTransitionDidEnd(_ transition: ZoomTransition)
}

// MARK: - Convenience

extension ZoomTransition {

    func transitionWillBegin() {
        fromDelegate?.zoomTransitionWillBegin(self)
        toDelegate?.zoomTransitionWillBegin(self)
    }

    func transitionDidEnd () {
        fromDelegate?.zoomTransitionDidEnd(self)
        toDelegate?.zoomTransitionDidEnd(self)
    }
}

extension ZoomTransitionDelegate {
    func wantsZoomTransition(for type: TransitionType) -> Bool { true }
    func zoomTransitionWillBegin(_ transition: ZoomTransition) {}
    func zoomTransitionDidEnd(_ transition: ZoomTransition) {}
}
