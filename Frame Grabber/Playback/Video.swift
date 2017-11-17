import AVKit
import Photos

/// Status of loading the player item from the Photo Library asset.
enum VideoStatus {
    case notLoaded
    case loading
    case failed(Error?)
    case loaded(AVPlayerItem)
}

/// A video from the Photo Library.
/// Loads an `AVPlayerItem` for playback from an `PHAsset` from the Photo Library.
class Video {

    typealias UpdateHandler = (Video, VideoStatus) -> ()

    let asset: PHAsset

    var playerItem: AVPlayerItem? {
        guard case let .loaded(playerItem) = status else { return nil }
        return playerItem
    }

    private(set) var status: VideoStatus = .notLoaded {
        didSet {

            switch (oldValue, status) {

            // Start loading
            case (.notLoaded, .loading), (.failed, .loading):
                performLoadPlayerItem()

            // Canceled, failed, finished: Clean up request
            case (.loading, .notLoaded), (.loading, .failed), (.loading, .loaded):
                performCancelPlayerItem()

            // Invalid transition
            default:
                status = oldValue
            }

            // In case of invalid transitions (e.g. requested loading while already loaded) send the current status for info
            updateHandler?(self, status)
        }
    }

    init(asset: PHAsset) {
        self.asset = asset
    }

    /// The previous update handler is discarded and all new status changes are reported to the provided one.
    func loadPlayerItem(updateHandler: @escaping UpdateHandler) {
        self.updateHandler = updateHandler
        status = .loading
    }

    func cancelLoadingPlayerItem() {
        status = .notLoaded
    }

    private var updateHandler: UpdateHandler?
    private var playerItemRequest: PlayerItemRequest?
}

// MARK: - Private

private extension Video {

    func performLoadPlayerItem() {
        playerItemRequest = PlayerItemRequest(video: asset, options: .video()) { [weak self] playerItem, info in
            self?.handlePlayerItemRequestResult(playerItem, info: info)
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

    func performCancelPlayerItem() {
        playerItemRequest = nil
    }
}
