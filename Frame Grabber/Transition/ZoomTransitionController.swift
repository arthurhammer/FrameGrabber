import UIKit

/// Coordinates the overall zoom transition by vending push and pop transition animators
/// for the navigation controller.
///
/// To use the transition, set the relevant navigation controller's delegate to an instance
/// of this class and adopt the `ZoomTransitionDelegate` protocol in participating view
/// controllers on the navigation stack.
class ZoomTransitionController: NSObject {

    /// Handles both interactive (slide to pop) and non-interactive transition (back button).
    /// (todo: Refactor this into a fresh instance every time?)
    private lazy var popTransition: ZoomPopTransition = {
        let transition = ZoomPopTransition()
        // The transition is non-interactive so it can handle the back button transition.
        // When the user swipes downward for the first time, it becomes interactive.
        transition.wantsInteractiveStart = false
        return transition
    }()

    /// Handles the slide to pop gesture, typically from the top view controller, and
    /// initiates the pop transition if certain criteria are met (gesture moves downwards).
    @objc func handleSlideToPopGesture(_ gesture: UIPanGestureRecognizer, performTransition: () -> ()) {
        let movingDown = gesture.velocity(in: gesture.view).y > 0

        switch gesture.state {

        // Initially moving downwards, start transition.
        case .began where movingDown:
            popTransition.wantsInteractiveStart = true
            performTransition()

        // If now moving downwards where not before, start transition.
        case .changed where movingDown && !popTransition.wantsInteractiveStart:
            popTransition.wantsInteractiveStart = true
            performTransition()
            gesture.setTranslation(.zero, in: gesture.view)

        case .changed:
            break

        default:
            // Non-interactive to handle back button until next swipe attempt.
            popTransition.wantsInteractiveStart = false
        }

        // Rest handled by the transition instance (animation, lifecycle etc.).
        popTransition.updateInteractiveTransition(for: gesture)
    }
}

extension ZoomTransitionController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let from = fromVC as? ZoomTransitionDelegate,
            let to = toVC as? ZoomTransitionDelegate else { return nil }

        if operation == .push  {
            return ZoomPushTransition(from: from, to: to)
        }

        popTransition.fromDelegate = from
        popTransition.toDelegate = to
        return popTransition
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let popTransition = animationController as? ZoomPopTransition else { return nil }

        return popTransition.wantsInteractiveStart ? popTransition : nil
    }
}
