import Photos
import UIKit

extension PHImageManager {

    /// Releasing the returned object cancels the request.
    /// The handler is called on the main thread and may be called before this method returns.
    func requestImage(for asset: PHAsset, options: ImageOptions, resultHandler: @escaping (UIImage?, Info) -> ()) -> Request {
        Request(manager: self, id: requestImage(for: asset, targetSize: options.size, contentMode: options.mode, options: options.requestOptions) { image, info in
            resultHandler(image, Info(info))
        })
    }

    /// Releasing the returned object cancels the request.
    /// Handlers are called asynchronously on the main thread.
    func requestAVAsset(for video: PHAsset, options: PHVideoRequestOptions?, progressHandler: ((Double) -> ())? = nil, resultHandler: @escaping (AVAsset?, AVAudioMix?, Info) -> ()) -> Request {
        let options = options ?? PHVideoRequestOptions()

        options.progressHandler = { progress, _, _, _ in
            DispatchQueue.main.async {
                progressHandler?(progress)
            }
        }

        return Request(manager: self, id: requestAVAsset(forVideo: video, options: options) { asset, mix, info in
            DispatchQueue.main.async {
                resultHandler(asset, mix, Info(info))
            }
        })
    }
}

extension PHImageManager {

    struct ImageOptions {
        var size: CGSize
        var mode: PHImageContentMode
        var requestOptions: PHImageRequestOptions
    }

    /// When deallocated, the request is cancelld.
    class Request {

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

extension PHImageRequestOptions {
    /// Allowed network access and opportunistic delivery mode.
    static func `default`() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        return options
    }
}

extension PHVideoRequestOptions {
    /// Allowed network access and full quality delivery mode.
    static func `default`() -> PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        return options
    }
}
