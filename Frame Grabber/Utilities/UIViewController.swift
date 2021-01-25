import UIKit

extension UIViewController {
    
    /// Set's the controller's preferred content height to an expanded size. The width is not
    /// specified.
    ///
    /// This can be used to expand view controller's in popovers or other containers.
    func updateExpandedPreferredContentSize() {
        let expandedHeight = view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height
        let expandedSize = CGSize(width: UIView.noIntrinsicMetric, height: expandedHeight)
        
        if preferredContentSize != expandedSize {
            preferredContentSize = expandedSize
        }
    }
}

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

