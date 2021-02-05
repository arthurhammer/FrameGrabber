import Photos
import UIKit
import Combine

extension PHImageManager {

    /// Options for an image request.
    ///
    /// By default: `zero` size, `aspectFill` content mode, `default()` request options.
    struct ImageOptions: Equatable {
        var size: CGSize = .zero
        var mode: PHImageContentMode = .aspectFill
        var requestOptions: PHImageRequestOptions = .default()
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

extension PHImageManager {

    /// Releasing the returned object cancels the request.
    /// The handler is called on the main thread and may be called before this method returns.
    func requestImage(for asset: PHAsset, options: ImageOptions, completionHandler: @escaping (UIImage?, Info) -> ()) -> Cancellable {
        let id = requestImage(for: asset, targetSize: options.size, contentMode: options.mode, options: options.requestOptions) { image, info in
            completionHandler(image, Info(info))
        }

        return AnyCancellable {
            self.cancelImageRequest(id)
        }
    }

    /// Releasing the returned object cancels the request.
    /// Handlers are called asynchronously on the main thread.
    func requestAVAsset(for video: PHAsset, options: PHVideoRequestOptions = .default(), progressHandler: ((Double) -> ())? = nil, completionHandler: @escaping (AVAsset?, AVAudioMix?, Info) -> ()) -> Cancellable {
        options.progressHandler = { progress, _, _, _ in
            DispatchQueue.main.async {
                progressHandler?(progress)
            }
        }

        let id = requestAVAsset(forVideo: video, options: options) { asset, mix, info in
            DispatchQueue.main.async {
                completionHandler(asset, mix, Info(info))
            }
        }

        return AnyCancellable {
            self.cancelImageRequest(id)
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
