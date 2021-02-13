import Contacts
import CoreLocation
import Foundation

class LocationFormatter {
    
    var coordinateDecimalPrecision = 5

    private lazy var addressFormatter = CNPostalAddressFormatter()

    private lazy var coordinateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = coordinateDecimalPrecision
        return formatter
    }()

    /// Formats the address as a multi- or single-line string.
    func string(from address: CNPostalAddress, multiline: Bool = true) -> String {
        let string = addressFormatter.string(from: address)
        return multiline ? string : string.replacingOccurrences(of: "\n", with: ", ")
    }

    /// Formats as latitude and longitude decimal degree values.
    ///
    /// The string is not localized, it uses international format.
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
