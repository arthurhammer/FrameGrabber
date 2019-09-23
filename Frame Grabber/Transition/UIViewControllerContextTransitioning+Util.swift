import UIKit

extension UIViewControllerContextTransitioning {
    var fromView: UIView? {
        view(forKey: .from)
    }

    var toView: UIView? {
        view(forKey: .to)
    }

    var finalToFrame: CGRect? {
        viewController(forKey: .to).flatMap(finalFrame)
    }
}

extension UIViewControllerContextTransitioning {

    func installViewsInContainer(for type: TransitionType) {
        // toView is nil if already in container, i.e. for dismissals where presenter
        // remained in view hierarchy.
        if let toView = toView {
            toView.frame = finalToFrame ?? .zero

            if type == .backward, let fromView = fromView {
                containerView.insertSubview(toView, belowSubview: fromView)
            } else {
                containerView.addSubview(toView)
            }
        }

        containerView.layoutIfNeeded()        
    }
}
