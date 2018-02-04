import AVKit
import Photos

enum VideoStatus {
    case notLoaded
    case loading
    case failed(Error?)
    case loaded(AVPlayerItem)
}

class VideoLoader {

    let asset: PHAsset
    private(set) var status: VideoStatus = .notLoaded

    private let imageManager: PHImageManager
    private var request: PlayerItemRequest?

    init(asset: PHAsset, imageManager: PHImageManager = .default()) {
        self.asset = asset
        self.imageManager = imageManager
    }

    deinit {
        cancel()
    }

    func loadPlayerItem(with requestOptions: PHVideoRequestOptions = .default(), resultHandler: @escaping (VideoStatus) -> ()) {
        guard status.canStartLoading else {
            // Send current status
            resultHandler(status)
            return
        }

        status = .loading
        resultHandler(status)

        request = PlayerItemRequest(imageManager: imageManager, video: asset, options: requestOptions) { [weak self] item, info in
            let info = info ?? [:]

            let status: VideoStatus

            if info.wasCanceled {
                status = .notLoaded
            } else if let item = item {
                status = .loaded(item)
            } else {
                status = .failed(info.error)
            }

            self?.request = nil
            self?.status = status
            resultHandler(status)
        }
    }

    func cancel() {
        request = nil
    }
}

// MARK: - Util

private extension VideoStatus {
    var canStartLoading: Bool {
        switch self {
        case .notLoaded, .failed: return true
        default: return false
        }
    }
}

private extension Dictionary where Key == AnyHashable {
    var error: Error? {
        return self[PHImageErrorKey] as? Error
    }

    var wasCanceled: Bool {
        return (self[PHImageCancelledKey] as? Bool) ?? false
    }
}
