import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureInteractivePopGesture()
    }

    /// Restores the default swipe to right to pop gesture (note: not the custom swipe to
    /// bottom to pop gesture).
    private func configureInteractivePopGesture() {
        // On custom navigation transitions, UIKit seems to disable the default
        // interactive pop gesture. Restore it by setting the delegate. But work around
        // the fact that the recognizer is nil until a second controller has been pushed.
        pushViewController(UIViewController(), animated: false)
        popViewController(animated: false)
        interactivePopGestureRecognizer?.delegate = self
    }
}

extension NavigationController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
