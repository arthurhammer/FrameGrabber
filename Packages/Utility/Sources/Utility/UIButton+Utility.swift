import UIKit

extension UIButton {
    
    public func setTitle(_ title: String?, for state: State, animated: Bool) {
        if animated {
            setTitle(title, for: state)
        } else {
            UIView.performWithoutAnimation {
                setTitle(title, for: state)
                layoutIfNeeded()
            }
        }
    }
}
