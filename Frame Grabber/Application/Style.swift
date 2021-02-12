import UIKit

extension UIColor {
    static let accent = UIColor(named: "accent")
    static let secondaryAccent = UIColor(named: "secondaryAccent")
    static let purchaseAccent = UIColor(named: "purchaseAccent")
    static let cellSelection = UIColor(named: "cellSelection")
    static let videoCellGradient = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.4)]
}

struct Style {

    static let buttonCornerRadius: CGFloat = 18
    static let staticTableViewTopMargin: CGFloat = 12

    static func configureAppearance(for window: UIWindow?) {
        window?.tintColor = .accent
        UISwitch.appearance().onTintColor = .accent
    }
}

extension UIButton {

    func configureAsActionButton(withHeight height: CGFloat? = 50, minimumWidth: CGFloat? = nil) {
        if let height = height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        if let minimumWidth = minimumWidth {
            widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth).isActive = true
        }
        
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        layer.cornerRadius = Style.buttonCornerRadius
        layer.cornerCurve = .continuous
        
        titleLabel?.font = .preferredFont(forTextStyle: .headline)
        configureDynamicTypeLabel()
    }

    func configureDynamicTypeLabel() {
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.allowsDefaultTighteningForTruncation = true
        titleLabel?.minimumScaleFactor = 0.6
        titleLabel?.lineBreakMode = .byTruncatingTail
    }
    
    func configureTrailingAlignedImage() {
        // Hack to flip the image to the right side.
        let isRightToLeft = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        semanticContentAttribute = isRightToLeft ? .forceLeftToRight : .forceRightToLeft
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
