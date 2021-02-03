import Foundation

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
