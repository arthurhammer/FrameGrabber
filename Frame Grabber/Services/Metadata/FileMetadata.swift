import Foundation
import UniformTypeIdentifiers

/// Metadata read from a local file.
struct FileMetadata: Hashable {
    let url: URL
    let name: String
    let size: Int?
    let formatIdentifier: String?
    let formatDisplayString: String?
}

extension FileMetadata {
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.size = url.fileSize
        
        let type = UTType(filenameExtension: url.pathExtension)
        self.formatIdentifier = type?.identifier
        self.formatDisplayString = type?.displayString
    }
}

private extension URL {
    
    var fileSize: Int? {
        let values = try? resourceValues(forKeys: [.totalFileSizeKey, .fileSizeKey])
        return values?.fileSize ?? values?.totalFileSize
    }
}
