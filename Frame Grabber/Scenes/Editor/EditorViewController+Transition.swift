import UIKit

extension EditorViewController: ZoomTransitionDelegate {

    func zoomTransitionWillBegin(_ transition: ZoomTransition) {
        switch transition.type {
        case .push: animatePush(transition)
        case .pop: animatePop(transition)
        default: break
        }
    }
    
    private func animatePush(_ transition: ZoomTransition) {
        let toolbar = toolbarController.toolbar!
        let yOffset = toolbar.bounds.height * 0.5
        toolbar.transform = CGAffineTransform.identity.translatedBy(x: 0, y: yOffset)

        transition.animate(alongsideTransition: { _ in
            toolbar.transform = .identity
        }, completion:nil)
    }
    
    private func animatePop(_ transition: ZoomTransition) {
        let backgroundColor = view.backgroundColor
        let toolbar = toolbarController.toolbar!

        transition.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            self.view.backgroundColor = .clear
            self.progressView.alpha = 0
            
            let yOffset = toolbar.bounds.height * 1.0
            toolbar.transform = CGAffineTransform.identity.translatedBy(x: 0, y: yOffset)
            toolbar.alpha = 0
        }, completion: { [weak self] _ in
            self?.view.backgroundColor = backgroundColor
        })
    }

    func zoomTransitionView(_ transition: ZoomTransition) -> UIView? {
        zoomingPlayerView.playerView
    }
}
