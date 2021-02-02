import AVFoundation
import Combine

extension AVAsynchronousKeyValueLoading {
    
    /// Whether the value for the key is **successfully loaded**.
    func isLoaded(_ key: String) -> Bool {
        statusOfValue(forKey: key) == .loaded
    }
    
    /// Whether the value for the key **ended loading**, i.e. is either loaded, failed or cancelled.
    func isLoadingCompleted(_ key: String) -> Bool {
        [.loaded, .failed, .cancelled].contains(statusOfValue(forKey: key))
    }
    
    /// Executes the closure only if the key is loaded and returns its result.
    @discardableResult
    func ifLoaded<Value>(_ key: String, then accessor: (Self) -> Value) -> Value? {
        isLoaded(key) ? accessor(self) : nil
    }
    
    /// Convenience for `statusOfValue(forKey:error:)`. Use that to retrieve potential errors.
    func statusOfValue(forKey key: String) -> AVKeyValueStatus {
        statusOfValue(forKey: key, error: nil)
    }
}

// MARK: - Debug

extension AVMetadataItem {
    
    /// Sanity check.
    ///
    /// Verify if we need to load item keys individually or if they are already loaded when the item
    /// itself is loaded. The documentation on `AVAsynchronousKeyValueLoading` is rather sparse, so
    /// it is not clear what needs to be loaded manually and what can be assumed to be loaded.
    func _assertIsLoadingCompleted() {
        let keys = [
            #keyPath(AVMetadataItem.value),
            #keyPath(AVMetadataItem.stringValue),
            #keyPath(AVMetadataItem.dateValue),
            #keyPath(AVMetadataItem.numberValue),
            #keyPath(AVMetadataItem.key),
            #keyPath(AVMetadataItem.commonKey),
            #keyPath(AVMetadataItem.keySpace),
            #keyPath(AVMetadataItem.identifier),
            // …
        ]
        
        keys.forEach {
            assert(isLoadingCompleted($0))
        }
    }
}
