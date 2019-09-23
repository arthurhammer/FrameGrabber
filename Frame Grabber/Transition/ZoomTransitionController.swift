import UIKit

enum TransitionType {
    /// Typically `presentation` for modal presentation and `push` for navigation
    /// controller operation.
    case forward
    /// Typically `dismissal` for modal presentation and `pop` for navigation
    /// controller operation.
    case backward
}

class ZoomTransitionController: NSObject {

    private weak var modalFrom: ZoomAnimatable?
    private weak var modalTo: ZoomAnimatable?
}

// MARK: - Modal Transition

extension ZoomTransitionController: UIViewControllerTransitioningDelegate {

    func prepareModalTransition(forSource source: UIViewController, destination: UIViewController) {
        destination.modalPresentationStyle = .custom
        destination.transitioningDelegate = self
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        modalFrom = modalFrom ?? (source as? ZoomAnimatable) ?? (presenting as? ZoomAnimatable)
        modalTo = modalTo ?? (presented as? ZoomAnimatable)

        return ZoomAnimator(type: .forward, from: modalFrom, to: modalTo)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        ZoomAnimator(type: .backward, from: modalTo, to: modalFrom)
    }
}

// MARK: - UINavigationController Transition

extension ZoomTransitionController: UINavigationControllerDelegate {

    func prepareNavigationControllerTransition(for navigationController: UINavigationController?) {
        navigationController?.delegate = self
    }

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let type = (operation == .push) ? TransitionType.forward : .backward
        let from = fromVC as? ZoomAnimatable
        let to = toVC as? ZoomAnimatable

        return ZoomAnimator(type: type, from: from, to: to)
    }
}
