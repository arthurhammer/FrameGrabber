import UIKit

extension UIViewController {

    /// Adds the given view controller as a child controller.
    ///
    /// Sets the child's view's frame and autoresizing mask to occupy the receiver's view fully.
    func embed(_ childController: UIViewController) {
        guard !children.contains(childController) else { return }
        
        // It is generally ok to trigger a view load when embedding the child but this can
        // prematurely load the child's view (e.g. when it is hidden in a tab or navigation
        // controller). During development, we keep the assert to be mindful of this situation.
        assert(isViewLoaded, "Embedded a child before the view loaded.")
        
        addChild(childController)
        view.addSubview(childController.view)

        childController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        childController.view.frame = view.bounds

        childController.didMove(toParent: self)
    }
    
    /// Removes the given view controller as a child controller.
    func unembed(_ childController: UIViewController) {
        guard childController.parent == self else { return }
        
        childController.willMove(toParent: nil)
        childController.view.removeFromSuperview()
        childController.removeFromParent()
    }
}

