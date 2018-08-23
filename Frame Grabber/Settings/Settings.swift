import Foundation

extension UserDefaults {

    private struct Key {
        static let includeMetadata = "IncludeMetadata"
    }

    var includeMetadata: Bool {
        get { return bool(forKey: Key.includeMetadata, or: true) }
        set { set(newValue, forKey: Key.includeMetadata) }
    }
}

extension UserDefaults {
    func bool(forKey key: String, or defaultValue: Bool) -> Bool {
        return object(forKey: key) as? Bool ?? defaultValue
    }
}
