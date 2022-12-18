import UIKit

class ThumbnailImageView: UIImageView {

    private let fadeDuration: TimeInterval = 0.2

    func setImage(_ image: UIImage?, animated: Bool) {
        if animated {
            UIView.transition(
                with: self,
                duration: fadeDuration,
                options: [.transitionCrossDissolve, .beginFromCurrentState],
                animations: { self.image = image }
            )
        } else {
            self.image = image
        }
    }
}
