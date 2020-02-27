import Foundation
import AVKit

class VideoDurationFormatter {

    private lazy var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    func string(from timeInterval: TimeInterval) -> String? {
        let timeInterval = timeInterval.rounded()
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

extension NumberFormatter {

    static func frameRateFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        return formatter
    }

    static func percentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }

    /// Includes units.
    func string(fromFrameRate frameRate: Float) -> String? {
        guard let formattedFps = string(from: frameRate as NSNumber) else { return nil }
        let format = NSLocalizedString("numberFormatter.frameRate",  value: "%@ fps", comment: "Video frame rate with unit")
        return String.localizedStringWithFormat(format, formattedFps)
    }

    /// Includes units.
    func string(fromPixelDimensions size: CGSize) -> String? {
        guard let w = string(from: abs(Int(size.width)) as NSNumber),
            let h = string(from: abs(Int(size.height)) as NSNumber) else { return nil }

        let format = NSLocalizedString("numberFormatter.videoDimensions", value: "%@ × %@ px", comment: "Video pixel size with unit")
        return String.localizedStringWithFormat(format, w, h)
    }
}

extension DateFormatter {

    static func `default`() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }
}
