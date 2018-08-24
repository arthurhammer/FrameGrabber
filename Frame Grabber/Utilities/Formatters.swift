import Foundation
import AVKit

class VideoDurationFormatter {

    private lazy var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    func string(from timeInterval: TimeInterval) -> String? {
        let hasHour = timeInterval >= 3600
        formatter.allowedUnits = hasHour ? [.hour, .minute, .second] : [.minute, .second]
        return formatter.string(from: timeInterval)
    }
}

class VideoTimeFormatter {
    
    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter
    }()

    func string(fromCurrentTime time: CMTime, includeMilliseconds: Bool = false) -> String {
        let format = includeMilliseconds ? "mm:ss.SS" : "mm:ss"
        return string(from: time, localizedFormatTemplate: format)
    }

    func string(from time: CMTime, localizedFormatTemplate: String) -> String {
        guard time.isValidVideoTime else { return "--:--" }

        let date = Date(timeIntervalSince1970: time.seconds)
        formatter.setLocalizedDateFormatFromTemplate(localizedFormatTemplate)
        return formatter.string(from: date)
    }
}

class VideoDimensionFormatter {
    /// Negative values are normalized.
    func string(fromWidth width: Int, height: Int, separator: String = "✕", unit: String? = "px") -> String {
        let unit = (unit != nil) ? " \(unit!)" : ""
        return "\(abs(width)) \(separator) \(abs(height))" + unit
    }
}

class FrameRateFormatter {

    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    // should look into localized formatting with units…
    func string(from frameRate: Float, unit: String? = "fps") -> String? {
        guard let formatted = formatter.string(from: frameRate as NSNumber) else { return nil }
        let unit = (unit != nil) ? " \(unit!)" : ""
        return formatted + unit
    }
}

// MARK: - Util

private extension CMTime {
    var isValidVideoTime: Bool {
        return isValid && isNumeric && !isNegativeInfinity && !isPositiveInfinity && !isIndefinite
    }
}
