import Foundation
import InAppPurchase

extension UserDefaults {

    private struct Key {
        static let compressionQuality = "CompressionQuality"
        static let exportAction = "ExportAction"
        static let includeMetadata = "IncludeMetadata"
        static let imageFormat = "ImageFormat"
        static let libraryGridMode = "LibraryGridMode"
        static let photoLibraryFilter = "PhotoLibraryFilter"
        static let purchasedProductIdentifiers = "PurchasedProductIdentifiers"
        static let timeFormat = "TimeFormat"
    }

    var photoLibraryFilter: PhotoLibraryFilter {
        get { codableValue(forKey: Key.photoLibraryFilter) ?? .videoAndLivePhoto }
        set { setCodableValue(value: newValue, forKey: Key.photoLibraryFilter) }
    }

    var libraryGridMode: LibraryGridMode {
        get { codableValue(forKey: Key.libraryGridMode) ?? .square }
        set { setCodableValue(value: newValue, forKey: Key.libraryGridMode) }
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
        get { codableValue(forKey: Key.timeFormat) ?? .minutesSecondsMilliseconds }
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
