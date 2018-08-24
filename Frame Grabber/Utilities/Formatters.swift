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
    func string(fromWidth width: Int, height: Int, separator: String = "✕") -> String {
        return "\(abs(width)) \(separator) \(abs(height))"
    }
}

// MARK: - Util

private extension CMTime {
    var isValidVideoTime: Bool {
        return isValid && isNumeric && !isNegativeInfinity && !isPositiveInfinity && !isIndefinite
    }
}
