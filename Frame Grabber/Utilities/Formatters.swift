import AVFoundation
import Contacts
import CoreLocation
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

class VideoTimeFormatter {
    
    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale.current
        return formatter
    }()

    func string(fromCurrentTime time: CMTime, includeMilliseconds: Bool = false) -> String {
        let hours = (time.seconds >= 3600) ? "HH:" : ""
        let minutesSeconds = "mm:ss"
        let millis = includeMilliseconds ? ".SSS" : ""

        let format = "\(hours)\(minutesSeconds)\(millis)"
        return string(from: time, localizedFormatTemplate: format)
    }

    func string(from time: CMTime, localizedFormatTemplate: String) -> String {
        guard time.isNumeric else { return "--:--" }

        let date = Date(timeIntervalSince1970: time.seconds)
        formatter.setLocalizedDateFormatFromTemplate(localizedFormatTemplate)
        return formatter.string(from: date)
    }
}

class LocationFormatter {
    
    var coordinateDecimalPrecision = 5

    private lazy var addressFormatter = CNPostalAddressFormatter()

    private lazy var coordinateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = coordinateDecimalPrecision
        return formatter
    }()

    /// Formats as a single line address.
    func string(from address: CNPostalAddress) -> String {
        addressFormatter.string(from: address).replacingOccurrences(of: "\n", with: ", ")
    }

    /// Formats as latitude and longitude decimal degree values.
    /// - Note: The string is not localized, it uses international format.
    func string(fromCoordinate coordinate: CLLocationCoordinate2D) -> String {
        guard let lat = coordinateFormatter.string(from: coordinate.latitude as NSNumber),
            let long = coordinateFormatter.string(from: coordinate.longitude as NSNumber)
        else {
            return fallbackString(fromCoordinate: coordinate)
        }

        let latRef = (coordinate.latitude >= 0) ? "N" : "S"
        let longRef = (coordinate.longitude >= 0) ? "E" : "W"

        return "\(lat)° \(latRef) \(long)° \(longRef)"
    }
    
    private func fallbackString(fromCoordinate coordinate: CLLocationCoordinate2D) -> String {
        let format = "%.\(coordinateDecimalPrecision)f"
        return String(format: "\(format), \(format)", coordinate.latitude, coordinate.longitude)
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
        return String.localizedStringWithFormat(UserText.formatterFrameRateFormat, formattedFps)
    }

    /// Includes units.
    func string(fromPixelDimensions size: CGSize) -> String? {
        guard let w = string(from: abs(Int(size.width)) as NSNumber),
            let h = string(from: abs(Int(size.height)) as NSNumber) else { return nil }

        return String.localizedStringWithFormat(UserText.formatterDimensionsFormat, w, h)
    }
}

extension DateFormatter {

    static func `default`() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }
}
