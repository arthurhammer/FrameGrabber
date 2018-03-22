import UIKit

extension UIColor {

    // Global

    static let accent = UIColor(red: 0.09, green: 0.82, blue: 0.39, alpha: 1.00) // UIColor(red:0.34, green:0.45, blue:0.98, alpha:1.00)
    static let mainBackground = UIColor.white

    // Video Library

    static let videoLibraryCellGradient = [UIColor.black.withAlphaComponent(0),
                                           UIColor.black.withAlphaComponent(0.6)]

    // Player

    static let timeSliderThumbTint = UIColor.accent
    static let timeSliderMinimumTrackTint = UIColor.timeSliderMaximumTrackTint
    static let timeSliderMaximumTrackTint = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.00)

    static let playerOverlayNavigationGradient = [UIColor.black.withAlphaComponent(0.4),
                                                  UIColor.black.withAlphaComponent(0)]

    static let playerOverlayControlsGradient = [UIColor.black.withAlphaComponent(0),
                                                UIColor.black.withAlphaComponent(0.4)]
}
