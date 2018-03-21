import UIKit

extension UIView {
    func setHidden(_ hidden: Bool, animated: Bool) {
        guard isHidden != hidden else { return }

        if !animated {
            isHidden = hidden
            return
        }

        alpha = hidden ? 1.0 : 0.0
        isHidden = false

        let duration = 0.2
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
