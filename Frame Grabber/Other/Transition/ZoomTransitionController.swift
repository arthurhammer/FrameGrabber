import UIKit

/// Coordinates the overall zoom transition by vending push and pop transition animators for the
/// navigation controller.
///
/// To use the transition:
///   - Assign the navigation controller to the `navigationController` property.
///   - Adopt the `ZoomTransitionDelegate` protocol in participating view controllers on the
///     navigation stack.
class ZoomTransitionController: NSObject {
        
    /// The navigation controller for which to manage the zoom transition. The receiver assigns
    /// itself as the delegate of the navigation controller.
    weak var navigationController: UINavigationController? {
        didSet { navigationController?.delegate = self }
    }
    
    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
        super.init()
        navigationController?.delegate = self
    }
    
    /// Handles the slide to pop gesture, typically called from the view controller to be popped.
    /// When the gesture is deemed to start the transition, initiates the pop transition via
    /// `navigationController.popViewController`.
    @objc func handleSlideToPopGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            startInteractiveTransition()
        case .changed:
            break
        default:
            // Allow for the non-interactive back button transition until the next swipe attempt.
            wantsInteractiveStart = false
        }

        // Rest handled by the transition instance after the transition started.
        popTransition?.updateInteractiveTransition(for: gesture)
    }
        
    // The transition is non-interactive initially to allow the non-interactive back button
    // transition. When the user swipes downward for the first time, it becomes interactive.
    private var wantsInteractiveStart = false
    private var popTransition: ZoomPopTransition?
    
    private func startInteractiveTransition() {
        wantsInteractiveStart = true
        navigationController?.popViewController(animated: true)
    }
}

extension ZoomTransitionController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let from = fromVC as? ZoomTransitionDelegate,
            let to = toVC as? ZoomTransitionDelegate,
            from.wantsZoomTransition(for: operation),
            to.wantsZoomTransition(for: operation) else { return nil }
        
        return (operation == .push)
            ? ZoomPushTransition(from: from, to: to)
            : ZoomPopTransition(from: from, to: to)
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let popTransition = animationController as? ZoomPopTransition,
              wantsInteractiveStart else { return nil }
            
        self.popTransition = popTransition
        popTransition.wantsInteractiveStart = true  // This is key.
        return popTransition
    }
}
