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
        formatter.setLocalizedDateFormatFromTemplate("mm:ss.SS")  // TODO: Hours
        return formatter
    }()

    func string(from time: CMTime) -> String {
        let date = Date(timeIntervalSince1970: time.seconds)
        return formatter.string(from: date)
    }
}
