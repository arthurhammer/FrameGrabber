import Foundation

class AppFileManager {
    
    let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    /// Removes all items in the user's temporary and `Documents/Inbox` directory.
    ///
    /// The system typically places files in the inbox directory when opening external files in the
    /// app.
    func clearTemporaryDirectories() throws {
        try fileManager.clear(contentsOf: fileManager.temporaryDirectory)
        try fileManager.clear(contentsOf: fileManager.inboxDirectory)
    }
 
    /// Moves or copies the source file to a temporary directory.
    ///
    /// If the file is copied, optionally deletes the source file (including when the copy operation
    /// fails). Throws an error if any operation fails, including deletion of the source file.
    func importVideo(at source: URL, asCopy: Bool, deletingSource: Bool) throws -> URL {
        let temporaryURL = try fileManager.createUniqueTemporaryDirectory()
            .appendingPathComponent(source.lastPathComponent)

        let deleteIfNeeded = {
            guard asCopy, deletingSource else { return }
            try self.fileManager.removeItem(at: source)
        }
    
        do {
            if asCopy {
                try fileManager.copyItem(at: source, to: temporaryURL)
            } else {
                try fileManager.moveItem(at: source, to: temporaryURL)
            }
        } catch {
            try deleteIfNeeded()
            throw error
        }
        
        try deleteIfNeeded()
        return temporaryURL
    }
}
