import UIKit

extension UILabel {
    
    public func setText(_ text: String?, animated: Bool) {
        guard animated else {
            self.text = text
            return
        }

        UIView.animate(withDuration: 0.15, delay: 0, options: .beginFromCurrentState) {
            self.text = text
            self.superview?.layoutIfNeeded()
        }
    }
}
