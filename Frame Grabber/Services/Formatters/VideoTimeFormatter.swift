import CoreMedia
import Foundation

class VideoTimeFormatter {
    
    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = .current
        return formatter
    }()
    
    private let fallbackString = "--:--"

    /// `HH:mm:ss.SSS` or `HH:mm:ss`.
    func string(from time: CMTime, includeMilliseconds: Bool = false) -> String {
        let hours = (time.seconds >= 3600) ? "HH:" : ""
        let minutesSeconds = "mm:ss"
        let millis = includeMilliseconds ? ".SSS" : ""
        let format = "\(hours)\(minutesSeconds)\(millis)"
        
        return string(from: time, localizedFormatTemplate: format)
    }
    
    /// `HH:mm:ss.ff` or `HH:mm:ss.SSS.ff`.
    func string(from time: CMTime, includeMilliseconds: Bool = false, frameNumber: Int) -> String {
        guard time.isNumeric else { return fallbackString }
        
        let mmss = string(from: time, includeMilliseconds: includeMilliseconds)
        let ff = String(format: "%02d", frameNumber)
        let mmssff = "\(mmss).\(ff)"
        
        return mmssff
    }

    private func string(from time: CMTime, localizedFormatTemplate: String) -> String {
        guard time.isNumeric else { return fallbackString }

        let date = Date(timeIntervalSince1970: time.seconds)
        formatter.setLocalizedDateFormatFromTemplate(localizedFormatTemplate)
        
        return formatter.string(from: date)
    }
}
