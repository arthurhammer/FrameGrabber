import UIKit

extension UIActivityIndicatorView {

    var isShowingAndAnimating: Bool {
        get { return isAnimating && !isHidden }
        set {
            if newValue {
                start()
            } else {
                stop()
            }
        }
    }

    /// Start and show, optionally with delay and animation.
    func start(after delay: TimeInterval? = nil) {
        guard !isAnimating || isHidden else { return }

        if let delay = delay {
            perform(#selector(performStart), with: nil, afterDelay: delay)
        } else {
            performStart()
        }
    }

    /// Stop and hide
    func stop() {
        cancelPendingDelays()
        isHidden = true
        stopAnimating()
    }

    @objc private func performStart() {
        cancelPendingDelays()
        startAnimating()
        isHidden = false
    }

    private func cancelPendingDelays() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
}
