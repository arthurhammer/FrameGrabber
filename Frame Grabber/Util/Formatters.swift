import Foundation
import AVKit

class VideoDurationFormatter {

    private lazy var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    func string(from timeInterval: TimeInterval) -> String? {
        // Don't pad hours for minutes
        formatter.allowedUnits = (timeInterval >= 3600) ? [.hour, .minute, .second] : [.minute, .second]
        return formatter.string(from: timeInterval)
    }
}

class VideoTimeFormatter {
    
    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter
    }()

    // TODO: Hours
    func string(fromCurrentTime time: CMTime, includeMilliseconds: Bool = true) -> String {
        let format = includeMilliseconds ? "mm:ss.SS" : "mm:ss"
        return string(from: time, localizedFormatTemplate: format)
    }

    func string(fromRemainingTime time: CMTime) -> String {
        return string(from: time, localizedFormatTemplate: "mm:ss")
    }

    func string(from time: CMTime, localizedFormatTemplate: String) -> String {
        guard time.isReallyReallyValid else { return "--:--" }

        let date = Date(timeIntervalSince1970: time.seconds)
        formatter.setLocalizedDateFormatFromTemplate(localizedFormatTemplate)
        return formatter.string(from: date)
    }
}

class VideoDimensionFormatter {
    func string(from size: CGSize) -> String? {
        guard size.isValidVideoDimension else { return nil }
        return "\(Int(size.width)) 𝖷 \(Int(size.height))"
    }
}

private extension CGSize {
    var isValidVideoDimension: Bool {
        return width > 0 && height > 0
    }
}

// ???
private extension CMTime {
    var isReallyReallyValid: Bool {
        return isValid && isNumeric && !isNegativeInfinity && !isPositiveInfinity && !isIndefinite
    }
}
