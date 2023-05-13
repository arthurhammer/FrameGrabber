import CoreGraphics
import Foundation

extension NumberFormatter {

    static func percentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }
    
    static func frameRateFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }

    /// `x fps`. Includes units.
    func string(fromFrameRate frameRate: Float) -> String? {
        guard let fps = string(from: frameRate as NSNumber) else { return nil }
        let format = Localized.formatterFrameRateFormat
        return String.localizedStringWithFormat(format, fps)
    }

    /// `w px × h px`. Includes units.
    func string(fromPixelDimensions size: CGSize) -> String? {
        guard let w = string(from: abs(Int(size.width)) as NSNumber),
            let h = string(from: abs(Int(size.height)) as NSNumber) else { return nil }

        return String.localizedStringWithFormat(Localized.formatterDimensionsFormat, w, h)
    }
}
