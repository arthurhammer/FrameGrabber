import UIKit

extension UILabel {
    
    func setText(_ text: String?, animated: Bool) {
        guard animated else {
            self.text = text
            return
        }

        UIView.animate(withDuration: 0.15, delay: 0, options: .beginFromCurrentState, animations: {
            self.text = text
            self.superview?.layoutIfNeeded()
        })
    }
}
