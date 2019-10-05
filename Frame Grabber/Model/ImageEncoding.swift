import CoreGraphics

struct ImageEncoding {
    let format: ImageFormat
    let compressionQuality: Double
    let metadata: CGImage.Metadata?
}
