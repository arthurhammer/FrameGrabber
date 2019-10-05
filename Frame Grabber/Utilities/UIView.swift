import UIKit

extension UIView {
    func setHidden(_ hidden: Bool, animated: Bool, duration: TimeInterval = 0.2) {
        guard isHidden != hidden else { return }

        if !animated {
            isHidden = hidden
            return
        }

        alpha = hidden ? 1.0 : 0.0
        isHidden = false

        UIView.animate(withDuration: duration, delay: 0, options: [], animations: {
            self.alpha = hidden ? 0.0 : 1.0
        }, completion: { _ in
            self.alpha = 1.0
            self.isHidden = hidden
        })
    }

    func toggleHidden(animated: Bool) {
        setHidden(!isHidden, animated: animated)
    }
}

extension UIView {

    func bounce(with scale: CGFloat = 0.95, duration: TimeInterval = 0.4) {
        let duration = duration / 2

        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        }, completion: { _ in
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
                self.transform = .identity
            }, completion: nil)
        })
    }
}
