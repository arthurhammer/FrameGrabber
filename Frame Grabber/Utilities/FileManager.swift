import Foundation

extension FileManager {

    /// Creates a unique directory, in a temporary or other directory.
    ///
    /// - Parameters:
    ///   - directory: The containing directory in which to create the unique directory.
    ///                If nil, uses the user's temporary directory.
    ///   - preferredName: The base name for the directory. If the name is not unique,
    ///                    appends indexes starting with 1. By default, uses a UUID.
    ///
    /// - Returns: The URL of the created directory.
    func createUniqueDirectory(in directory: URL? = nil,
                               preferredName: String = UUID().uuidString) throws -> URL {

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
    
    /// Removes all items in the user's temporary directory.
    func clearTemporaryDirectory() throws {
        do {
            try contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: [])
                .forEach(removeItem)
        }
    }
}
