import Foundation
import UIKit

extension UIButton {
    
    static func libraryTitle(isCompact: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = libraryTitleFont(isCompact: isCompact)
        button.tintColor = .label
        button.configureDynamicTypeLabel()
        button.setImage(libraryTitleImage(), for: .normal)
        button.configureTrailingAlignedImage()
        return button
    }
    
    static func libraryTitleFont(isCompact: Bool = false) -> UIFont {
        .preferredFont(forTextStyle: .headline, weight: .bold, size: (isCompact ? 22 : 26))
    }
    
    private static func libraryTitleImage() -> UIImage? {
        if #available(iOS 15, *) {
            let configuration = UIImage.SymbolConfiguration(paletteColors: [.accent, .secondarySystemFill])
                .applying(UIImage.SymbolConfiguration(pointSize: 26, weight: .bold))
                .applying(UIImage.SymbolConfiguration(scale: .small))
            
            return UIImage(systemName: "chevron.down.circle.fill", withConfiguration: configuration)
        } else {
            let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
                .applying(UIImage.SymbolConfiguration(scale: .small))
            
            return UIImage(systemName: "chevron.down", withConfiguration: configuration)?
                .withTintColor(.accent, renderingMode: .alwaysOriginal)
        }
    }
}
