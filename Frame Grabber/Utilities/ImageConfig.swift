import Photos

struct ImageConfig {
    var size: CGSize = .zero
    var mode: PHImageContentMode = .aspectFill
    var options: PHImageRequestOptions? = .default()
}
