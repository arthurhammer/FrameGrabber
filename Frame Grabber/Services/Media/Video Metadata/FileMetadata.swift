import Foundation

/// Metadata read from a local file.
struct FileMetadata: Hashable {
    let url: URL
    let fileName: String
    let fileSize: Int?
}

extension FileMetadata {
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        self.fileSize = url.fileSize
    }
}

private extension URL {
    var fileSize: Int? {
        let values = try? resourceValues(forKeys: [.totalFileSizeKey, .fileSizeKey])
        return values?.fileSize ?? values?.totalFileSize
    }
}
