import UIKit

// (Should migrate to `UIButton.Configuration` in the future.)

extension Style {
    static let defaultButtonCornerRadius: CGFloat = 16
    static let mediumButtonCornerRadius: CGFloat = 12
}

extension UIButton {
    static func action(withHeight height: CGFloat? = 50, minimumWidth: CGFloat? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.configureAsActionButton(withHeight: height, minimumWidth: minimumWidth)
        return button
    }
}

extension UIButton {
    
    func configureAsActionButton(withHeight height: CGFloat? = 50, minimumWidth: CGFloat? = nil) {
        if let height {
            let constraint = heightAnchor.constraint(equalToConstant: height)
            constraint.priority = .required - 1
            constraint.isActive = true
        }
        
        if let minimumWidth {
            let constraint = widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth)
            constraint.priority = .required - 1
            constraint.isActive = true
        }
        
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layer.cornerRadius = Style.defaultButtonCornerRadius
        layer.cornerCurve = .continuous
        titleLabel?.font = .preferredFont(forTextStyle: .headline)
        configureDynamicTypeLabel()
    }

    func configureDynamicTypeLabel() {
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.6
        titleLabel?.allowsDefaultTighteningForTruncation = true
        titleLabel?.lineBreakMode = .byTruncatingTail
    }
        
    func configureTrailingAlignedImage() {
        // Hack to flip the image to the right side.
        let isRightToLeft = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        semanticContentAttribute = isRightToLeft ? .forceLeftToRight : .forceRightToLeft
    }
}
