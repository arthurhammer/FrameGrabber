import Foundation

extension FileManager {
    
    /// See `createUniqueDirectory(in:preferredName)`.
    func createUniqueTemporaryDirectory() throws -> URL {
        try createUniqueDirectory()
    }

    /// Creates a unique directory, in a temporary or other directory.
    ///
    /// - Parameters:
    ///   - directory: The containing directory in which to create the unique directory. If nil,
    ///     uses the user's temporary directory.
    ///   - preferredName: The base name for the directory. If the name is not unique, appends
    ///     indexes starting with 1. Uses a UUID by default.
    ///
    /// - Returns: The URL of the created directory.
    func createUniqueDirectory(
        in directory: URL? = nil,
        preferredName: String = UUID().uuidString
    ) throws -> URL {
        
        let directory = directory ?? temporaryDirectory

        var i = 0

        while true {
            do {
                let name = (i == 0) ? preferredName : "\(preferredName)-\(i)"
                let subdirectory = directory.appendingPathComponent(name, isDirectory: true)
                try createDirectory(at: subdirectory, withIntermediateDirectories: false)
                return subdirectory
            } catch CocoaError.fileWriteFileExists {
                i += 1
            }
        }
    }
}

extension FileManager {
    
    /// The user's document directory.
    var documentsDirectory: URL {
        let url = self.urls(for: .documentDirectory, in: .userDomainMask).first
        precondition(url != nil, "Could not find the user's directory.")
        return url!
    }

    /// The user's `Documents/Inbox` directory.
    var inboxDirectory: URL {
        documentsDirectory.appendingPathComponent("Inbox", isDirectory: true)
    }
    
    /// Deletes all items in the directory.
    func clear(contentsOf directory: URL) throws {
        do {
            try contentsOfDirectory(at: directory, includingPropertiesForKeys: [])
                .forEach(removeItem)
        }
    }
}
