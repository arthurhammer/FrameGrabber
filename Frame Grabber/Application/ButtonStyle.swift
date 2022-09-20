import UIKit

extension Style {
    static let defaultButtonCornerRadius: CGFloat = 16
    static let mediumButtonCornerRadius: CGFloat = 12
}

extension UIButton.Configuration {
    
    static func action(using baseConfiguration: Self = .filled()) -> Self {
        var configuration = baseConfiguration
        configuration.setDefaultContentInsets()
        configuration.buttonSize = .large
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = Style.defaultButtonCornerRadius
        configuration.baseForegroundColor = .label
        configuration.baseBackgroundColor = .accent
        configuration.imagePadding = 8
        configuration.titleTextAttributesTransformer = .init { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .headline)
            return attributes
        }
        return configuration
    }
}

// MARK: - Deprecated

@available(*, deprecated, message: "Use `UIButton.Configuration`")
extension UIButton {
    
    static func action(withHeight height: CGFloat? = 50, minimumWidth: CGFloat? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.configureAsActionButton(withHeight: height, minimumWidth: minimumWidth)
        return button
    }
    
    func configureAsActionButton(withHeight height: CGFloat? = 50, minimumWidth: CGFloat? = nil) {
        if let height = height {
            let constraint = heightAnchor.constraint(equalToConstant: height)
            constraint.priority = .required - 1
            constraint.isActive = true
        }
        
        if let minimumWidth = minimumWidth {
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
