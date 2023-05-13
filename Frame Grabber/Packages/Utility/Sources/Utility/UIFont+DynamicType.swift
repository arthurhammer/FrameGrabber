import UIKit

extension UIFont {
    
    // MARK: Unscaled Fonts
    
    /// The unscaled font for the given text style at the given content size category.
    public static func preferredFont(forTextStyle style: TextStyle, atSizeCategory size: UIContentSizeCategory) -> UIFont {
        preferredFont(forTextStyle: style, compatibleWith: .init(preferredContentSizeCategory: size))
    }
    
    // MARK: Scaled Fonts
    
    public enum MaximumSize {
        case pointSize(CGFloat)
        case sizeCategory(UIContentSizeCategory)
    }
    
    /// A preferred font for the given style that scales up to the maximum size (if any).
    public static func preferredFont(
        forTextStyle style: TextStyle,
        weight: Weight?,  // no default parameter to disambiguate from `preferredFont(forTextStyle:)`
        maximumSize: MaximumSize? = nil
    ) -> UIFont {
        let baseFont = preferredFont(forTextStyle: style, atSizeCategory: .default)
        let baseFontSize = baseFont.pointSize
        return preferredFont(forTextStyle: style, weight: weight, size: baseFontSize, maximumSize: maximumSize)
    }
    
    /// A preferred font for the given style using an explicit base size that scales up to the maximum size (if any).
    /// - Parameters:
    ///   - size: The explicit base size of the font. The scaling behavior matches that of the text style.
    public static func preferredFont(
        forTextStyle style: TextStyle,
        weight: Weight?,
        size: CGFloat,
        maximumSize: MaximumSize? = nil
    ) -> UIFont {
        
        let targetFont: UIFont
        if let weight {
            targetFont = systemFont(ofSize: size, weight: weight)
        } else {
            targetFont = systemFont(ofSize: size)
        }
        
        return scaledFont(for: targetFont, textStyle: style, maximumSize: maximumSize)
    }
    
    // MARK: Monospaced Fonts

    /// A monospaced digit font for the given style that scales up to the maximum size (if any).
    public static func monospacedDigitSystemFont(
        forTextStyle style: TextStyle,
        weight: Weight = .regular,
        maximumSize: MaximumSize? = nil
    ) -> UIFont {
        let baseFont = preferredFont(forTextStyle: style, atSizeCategory: .default)
        let targetFont = monospacedDigitSystemFont(ofSize: baseFont.pointSize, weight: weight)
        return scaledFont(for: targetFont, textStyle: style, maximumSize: maximumSize)
    }
}

// MARK: - Private

extension UIFont {
    
    fileprivate static func scaledFont(
        for font: UIFont,
        textStyle: TextStyle,
        maximumSize: MaximumSize? = nil
    ) -> UIFont {
        
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        
        switch maximumSize {
        case .none:
            return fontMetrics.scaledFont(for: font)

        case .pointSize(let pointSize):
            return fontMetrics.scaledFont(for: font, maximumPointSize: pointSize)
            
        case .sizeCategory(let sizeCategory):
            let maximumFont = preferredFont(forTextStyle: textStyle, atSizeCategory: sizeCategory)
            let maximumFontSize = maximumFont.pointSize
            return fontMetrics.scaledFont(for: font, maximumPointSize: maximumFontSize)
        }
    }
}
