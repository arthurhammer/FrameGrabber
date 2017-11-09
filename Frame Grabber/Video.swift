import AVKit
import Photos

// TODO
extension VideoStatus {
    var isLoaded: Bool {
        switch self {
        case .loaded: return true
        default: return false
        }
    }

    var isLoading: Bool {
        switch self {
        case .loading: return true
        default: return false
        }
    }
}

enum VideoStatus {
    case notLoaded
    case loading
    case loaded(AVPlayerItem)
    case canceled
    case failed(Error?)
}

/// Represents a video from the Photo Library.
/// Loads an `AVPlayerItem` for playback from an `PHAsset` from the Photo Library.
class Video {

    typealias UpdateHandler = (Video, VideoStatus) -> ()

    let asset: PHAsset

    var playerItem: AVPlayerItem? {
        guard case let .loaded(playerItem) = status else { return nil }
        return playerItem
    }

    /// The current status of loading the `AVPlayerItem` from the `PHAsset`.
    private(set) var status: VideoStatus = .notLoaded {
        didSet {
            var statusChanged = true
            var notify = true

            switch (oldValue, status) {

            // Valid transitions

            case (.notLoaded, .loading), (.canceled, .loading), (.failed, .loading):
                performLoadPlayerItem()

            case (.loading, .canceled) where playerItemRequestId != nil:
                PHImageManager.default().cancelImageRequest(playerItemRequestId!)
                playerItemRequestId = nil

            case (.loading, .failed), (.loading, .loaded):
                break

            // Invalid transitions

            // Loading requested while already loaded.
            // Notify update handler with loaded status.
            case (.loaded, .loading):
                statusChanged = false

            default:
                statusChanged = false
                notify = false
            }

            if !statusChanged {
                status = oldValue
            }

            if notify {
                updateHandler?(self, status)
            }
        }
    }

    init(asset: PHAsset) {
        self.asset = asset
    }

    deinit {
        print("deinit video")
        cancelLoadingPlayerItem()
    }

    /// Previous update handlers are discarded and all new status changes are reported to the provided one.
    func loadPlayerItem(updateHandler: @escaping UpdateHandler) {
        self.updateHandler = updateHandler
        status = .loading
    }

    func cancelLoadingPlayerItem() {
        status = .canceled
    }

    private var updateHandler: UpdateHandler?
    private var playerItemRequestId: PHImageRequestID?

    private var playerItemRequestOptions: PHVideoRequestOptions = {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        return options
    }()
}

// MARK: - Private

private extension Video {

    // Note: `PHVideoRequestOptions.progressHandler` and `PHImageCancelledKey` don't seem to be
    //       working for `PHImageManager.requestPlayerItem`, only for `PHImageManager.requestAVAsset`.

    func performLoadPlayerItem() {
        let imageManager = PHImageManager.default()

        playerItemRequestId = imageManager.requestPlayerItem(forVideo: asset, options: playerItemRequestOptions) { [weak self] playerItem, info in
            DispatchQueue.main.async {
                self?.handlePlayerItemRequestResult(playerItem, info: info)
            }
        }
    }

    func handlePlayerItemRequestResult(_ playerItem: AVPlayerItem?, info: [AnyHashable: Any]?) {
        guard let playerItem = playerItem else {
            let error = info?[PHImageErrorKey] as? Error
            status = .failed(error)
            return
        }

        status = .loaded(playerItem)
    }
}
