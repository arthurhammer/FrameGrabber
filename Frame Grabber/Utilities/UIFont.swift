import UIKit

extension UIFont {

    /// The preferred scaled font for the given style adjusted with the given weight.
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight) -> UIFont {
        let baseSize = baseFont(forTextStyle: style).pointSize
        return preferredFont(forTextStyle: style, size: baseSize, weight: weight)
    }
    
    /// A scaled font for the given base size adjusted for the weight and scaled for the style.
    static func preferredFont(
        forTextStyle style: TextStyle,
        size: CGFloat,
        weight: Weight
    ) -> UIFont {
        
        let targetFont = systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: targetFont)
    }
    
    /// A monospaced digit font that scales for the given style and weight.
    static func monospacedDigitSystemFont(
        forTextStyle style: TextStyle,
        weight: Weight = .regular
    ) -> UIFont {
        
        let baseSize = baseFont(forTextStyle: style).pointSize
        let targetFont = monospacedDigitSystemFont(ofSize: baseSize, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: targetFont)
    }
    
    /// The preferred font for the given text style at the default (but not necessarily current)
    /// content size category. The default content size category is `.large`.
    private static func baseFont(forTextStyle style: TextStyle) -> UIFont {
        let defaultCategory = UITraitCollection(preferredContentSizeCategory: .large)
        return preferredFont(forTextStyle: style, compatibleWith: defaultCategory)
    }
}
