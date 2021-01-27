import Foundation
import InAppPurchase

extension UserDefaults {

    private struct Key {
        static let videoTypesFilter = "VideoTypesFilter"
        static let albumGridContentMode = "AlbumGridContentMode"
        static let includeMetadata = "IncludeMetadata"
        static let imageFormat = "ImageFormat"
        static let compressionQuality = "CompressionQuality"
        static let purchasedProductIdentifiers = "PurchasedProductIdentifiers"
        static let exportAction = "ExportAction"
        static let timeFormat = "TimeFormat"
    }

    var videoTypesFilter: VideoTypesFilter {
        get { codableValue(forKey: Key.videoTypesFilter) ?? .all }
        set { setCodableValue(value: newValue, forKey: Key.videoTypesFilter) }
    }

    var albumGridContentMode: AlbumGridContentMode {
        get { codableValue(forKey: Key.albumGridContentMode) ?? .square }
        set { setCodableValue(value: newValue, forKey: Key.albumGridContentMode) }
    }

    var includeMetadata: Bool {
        get { (object(forKey: Key.includeMetadata) as? Bool) ?? true }
        set { set(newValue, forKey: Key.includeMetadata) }
    }

    /// When setting or getting an unsupported format, sets or gets a fallback format (jpeg).
    var imageFormat: ImageFormat {
        get { (codableValue(forKey: Key.imageFormat) ?? ImageFormat.jpeg).fallbackFormat }
        set { setCodableValue(value: newValue.fallbackFormat, forKey: Key.imageFormat) }
    }

    var compressionQuality: Double {
        get { (object(forKey: Key.compressionQuality) as? Double) ?? 0.95 }
        set { set(newValue, forKey: Key.compressionQuality) }
    }
    
    var exportAction: ExportAction {
        get { codableValue(forKey: Key.exportAction) ?? .showShareSheet }
        set { setCodableValue(value: newValue, forKey: Key.exportAction) }
    }
    
    var timeFormat: TimeFormat {
        get { codableValue(forKey: Key.timeFormat) ?? .minutesSecondsFrameNumber }
        set { setCodableValue(value: newValue, forKey: Key.timeFormat) }
    }
}

extension UserDefaults: PurchasedProductsStore {
    public var purchasedProductIdentifiers: [String] {
        get { (array(forKey: Key.purchasedProductIdentifiers) as? [String]) ?? [] }
        set { set(newValue, forKey: Key.purchasedProductIdentifiers) }
    }
}

extension UserDefaults {

    func codableValue<T: Codable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func setCodableValue<T: Codable>(value: T?, forKey key: String) {
        let data = try? value.flatMap(JSONEncoder().encode)
        set(data, forKey: key)
    }
}
