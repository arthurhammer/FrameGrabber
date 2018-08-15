import UIKit

extension UIView {
    func applyDefaultOverlayShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 1)
    }
}
