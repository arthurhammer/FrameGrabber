import Foundation
import InAppPurchase
import UIKit

extension UserDefaults {

    private struct Key {
        static let camera = "Camera"
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
        get { decodedValue(forKey: Key.photoLibraryFilter) ?? .videoAndLivePhoto }
        set { setEncodedValue(newValue, forKey: Key.photoLibraryFilter) }
    }

    var libraryGridMode: LibraryGridMode {
        get { decodedValue(forKey: Key.libraryGridMode) ?? .square }
        set { setEncodedValue(newValue, forKey: Key.libraryGridMode) }
    }

    var includeMetadata: Bool {
        get { (object(forKey: Key.includeMetadata) as? Bool) ?? true }
        set { set(newValue, forKey: Key.includeMetadata) }
    }

    /// When setting or getting an unsupported format, sets or gets a fallback format (jpeg).
    var imageFormat: ImageFormat {
        get { (decodedValue(forKey: Key.imageFormat) ?? ImageFormat.jpeg).fallbackFormat }
        set { setEncodedValue(newValue.fallbackFormat, forKey: Key.imageFormat) }
    }

    var compressionQuality: Double {
        get { (object(forKey: Key.compressionQuality) as? Double) ?? 0.95 }
        set { set(newValue, forKey: Key.compressionQuality) }
    }
    
    var exportAction: ExportAction {
        get { decodedValue(forKey: Key.exportAction) ?? .showShareSheet }
        set { setEncodedValue(newValue, forKey: Key.exportAction) }
    }
    
    var timeFormat: TimeFormat {
        get { decodedValue(forKey: Key.timeFormat) ?? .minutesSecondsFrameNumber }
        set { setEncodedValue(newValue, forKey: Key.timeFormat) }
    }
    
    var camera: UIImagePickerController.CameraDevice {
        get { valueForRawValue(forKey: Key.camera) ?? .front }
        set { setRawValue(newValue, forKey: Key.camera) }
    }
}

extension UserDefaults: PurchasedProductsStore {
    public var purchasedProductIdentifiers: [String] {
        get { (array(forKey: Key.purchasedProductIdentifiers) as? [String]) ?? [] }
        set { set(newValue, forKey: Key.purchasedProductIdentifiers) }
    }
}

extension UserDefaults {

    func decodedValue<T: Decodable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func setEncodedValue(_ value: (some Encodable)?, forKey key: String) {
        let data = try? value.flatMap(JSONEncoder().encode)
        set(data, forKey: key)
    }
    
    /// Sets the raw value for the specified key.
    ///
    /// The raw value must be one of the property list types as specified by `UserDefaults`.
    /// Otherwise, you should archive the data to `Data`, e.g. using `setEncodedValue`.
    func setRawValue(_ value: some RawRepresentable, forKey key: String) {
        set(value.rawValue, forKey: key)
    }
    
    func valueForRawValue<R: RawRepresentable>(forKey key: String) -> R? {
        guard let value = object(forKey: key) as? R.RawValue else { return nil }
        return R(value)
    }
}
