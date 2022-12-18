import Foundation

class ImageMetadataDateFormatter {
    
    private lazy var formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        // yyyy-MM-dd HH:mm:ss
        formatter.formatOptions = [
            .withFullDate,
            .withDashSeparatorInDate,
            .withSpaceBetweenDateAndTime,
            .withTime,
            .withColonSeparatorInTime
        ]
        return formatter
    }()
    
    /// `yyyy:MM:dd HH:mm:ss` in local time zone.
    func exifTimestamp(from date: Date) -> String {
        formatter.timeZone = .current
        return string(from: date)
    }
    
    /// Equivalent to `exifTimestamp`.
    func tiffTimestamp(from date: Date) -> String {
        exifTimestamp(from: date)
    }
    
    /// `yyyy:MM:dd HH:mm:ss` in UTC time zone.
    func gpsTimestamp(from date: Date) -> String {
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return string(from: date)
    }
    
    private func string(from date: Date) -> String {
        formatter.string(from: date).replacingOccurrences(of: "-", with: ":")
    }
}
