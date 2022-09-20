import UIKit

extension UIColor {
    static let accent = UIColor(named: "accent")!
    static let secondaryAccent = UIColor(named: "secondaryAccent")!
    static let purchaseAccent = UIColor(named: "purchaseAccent")!
    static let cellSelection = UIColor(named: "cellSelection")!
    static let editorBackground = UIColor(named: "editorBackground")!
    static let editorBars = UIColor(named: "editorBars")!
    static let videoCellGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.4)]
    static let labelInverted = UIColor(named: "labelInverted")!
}

struct Style {
    static func configureAppearance(for window: UIWindow? = nil) {
        window?.tintColor = .accent
        UISwitch.appearance().onTintColor = .accent
    }
}

extension UIView {
    func configureWithDefaultShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 14
        layer.shadowOffset = .zero
    }
    
    func configureWithBarShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.03
        layer.shadowRadius = 5
        layer.shadowOffset = .zero
    }
}
