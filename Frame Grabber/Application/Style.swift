import UIKit

extension UIColor {
    static let accent = UIColor(named: "accent")!
    static let secondaryAccent = UIColor(named: "secondaryAccent")!
    static let purchaseAccent = UIColor(named: "purchaseAccent")!
    static let cellSelection = UIColor(named: "cellSelection")!
    static let videoCellGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.4)]
}

struct Style {
    static func configureAppearance(for window: UIWindow? = nil) {
        window?.tintColor = .accent
        UISwitch.appearance().onTintColor = .accent
    }
}

extension UIView {
    func applyDefaultShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 14
        layer.shadowOffset = .zero
    }
}
