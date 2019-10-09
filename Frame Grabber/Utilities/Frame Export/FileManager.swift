import Foundation

extension FileManager {

    /// Creates a temporary directory with a unique name and returns its URL.
    func createUniqueTemporaryDirectory(preferredName: String? = nil) throws -> URL {
        let basename = preferredName ?? UUID().uuidString

        var i = 0

        while true {
            do {
                let name = (i == 0) ? basename : "\(basename)-\(i)"
                let subdirectory = temporaryDirectory.appendingPathComponent(name, isDirectory: true)
                try createDirectory(at: subdirectory, withIntermediateDirectories: false)
                return subdirectory
            } catch CocoaError.fileWriteFileExists {
                i += 1
            }
        }
    }
}

extension FileManager {
    
    /// Removes all items in the user's temporary directory.
    func clearTemporaryDirectory() throws {
        do {
            try contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: [])
                .forEach(removeItem)
        }
    }
}
