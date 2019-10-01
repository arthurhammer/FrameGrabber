import Photos
import UIKit

extension PHImageManager {

    /// Releasing the returned object cancels the request.
    /// The handler is called on the main thread and may be called before this method returns.
    func requestImage(for asset: PHAsset, config: ImageConfig, resultHandler: @escaping (UIImage?, Info) -> ()) -> ImageRequest {
        let id = requestImage(for: asset, targetSize: config.size, contentMode: config.mode, options: config.options) { image, info in
            resultHandler(image, Info(info))
        }

        return ImageRequest(manager: self, id: id)
    }

    /// Releasing the returned object cancels the request.
    /// Handlers are called asynchronously on the main thread.
    func requestAVAsset(for video: PHAsset, options: PHVideoRequestOptions?, progressHandler: ((Double) -> ())? = nil, resultHandler: @escaping (AVAsset?, AVAudioMix?, Info) -> ()) -> ImageRequest {
        let options = options ?? PHVideoRequestOptions()

        options.progressHandler = { progress, _, _, _ in
            DispatchQueue.main.async {
                progressHandler?(progress)
            }
        }

        let id = requestAVAsset(forVideo: video, options: options) { asset, mix, info in
            DispatchQueue.main.async {
                resultHandler(asset, mix, Info(info))
            }
        }

        return ImageRequest(manager: self, id: id)
    }
}

/// Cancels the request on `deinit`.
class ImageRequest {

    let manager: PHImageManager
    let id: PHImageRequestID

    init(manager: PHImageManager, id: PHImageRequestID) {
        self.manager = manager
        self.id = id
    }

    func cancel() {
        manager.cancelImageRequest(id)
    }

    deinit {
        cancel()
    }
}

extension PHImageManager {
    /// Wrapper for image request info dictionary.
    struct Info {
        let info: [AnyHashable: Any]

        init(_ info: [AnyHashable: Any]?) {
            self.info = info ?? [:]
        }

        var error: Error? {
            info[PHImageErrorKey] as? Error
        }

        var isCancelled: Bool {
            (info[PHImageCancelledKey] as? Bool) ?? false
        }
    }
}
