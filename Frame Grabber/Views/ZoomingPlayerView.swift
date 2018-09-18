import UIKit
import AVKit

protocol ZoomingPlayerViewDelegate: class {
    func playerView(_ playerView: ZoomingPlayerView, didUpdateReadyForDisplay ready: Bool)
}

extension ZoomingPlayerViewDelegate {
    func playerView(_ playerView: ZoomingPlayerView, didUpdateReadyForDisplay ready: Bool) {}
}

/// A view that manages zooming for an `AVPlayerLayer`.
/// The view is zoomed with pinch and double tap gestures.
class ZoomingPlayerView: UIView {

    weak var delegate: ZoomingPlayerViewDelegate?

    var player: AVPlayer? {
        get { return playerView.player }
        set {
            playerView.player = newValue
            observePlayerItemSize()
        }
    }

    let playerView = PlayerView()

    var isReadyForDisplay: Bool {
        return playerView.playerLayer.isReadyForDisplay
    }

    /// The current size and position of the full video image in the receiver. If the
    /// player is not ready, is `zero`.
    var zoomedVideoFrame: CGRect {
        guard playerView.frame.size != .zero else { return .zero }
        return scrollView.convert(playerView.frame, to: self)
    }

    fileprivate(set) lazy var doubleTapToZoomRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))

    private let scrollView = UIScrollView()
    private var unzoomedContentSize: CGSize?  // Zooming scales the content size.
    private var previousSize = CGSize.zero
    private var playerItemSizeObserver: NSKeyValueObservation?
    private var layerReadyObserver: NSKeyValueObservation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard previousSize != bounds.size else { return }

        // Reset scroll view setup on rotation (etc.).
        updatePlayerViewSize(keepingZoomIfPossible: false)
        scrollView.centerContentView()
        previousSize = bounds.size
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomingPlayerView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return playerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.centerContentView()
    }
}

// MARK: - Private

private extension ZoomingPlayerView {

    func configureViews() {
        playerView.playerLayer.backgroundColor = nil

        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast

        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        scrollView.addSubview(playerView)
        addSubview(scrollView)

        observeLayerReady()
        configureGestures()
        updatePlayerViewSize(keepingZoomIfPossible: false)
    }

    func observeLayerReady() {
        layerReadyObserver = playerView.playerLayer.observe(\.isReadyForDisplay, options: .initial) { [weak self] layer, _ in
            guard let self = self else { return }
            self.delegate?.playerView(self, didUpdateReadyForDisplay: layer.isReadyForDisplay)
        }
    }

    func observePlayerItemSize() {
        playerItemSizeObserver = player?.observe(\.currentItem?.presentationSize, options: .initial) { [weak self]  _, _ in
            self?.updatePlayerViewSize(keepingZoomIfPossible: true)
        }
    }

    func updatePlayerViewSize(keepingZoomIfPossible: Bool) {
        let newContentSize = player?.currentItem?.presentationSize ?? .zero

        // Remain zoomed in if the player item changed but has same size (to avoid zooming
        // out when looping the same video).
        if keepingZoomIfPossible && (newContentSize == unzoomedContentSize) {
            return
        }

        unzoomedContentSize = newContentSize
        playerView.bounds.size = newContentSize
        scrollView.contentSize = newContentSize

        scrollView.updateZoomRangeForContentView()
        scrollView.centerContentView()
    }

    func configureGestures() {
        doubleTapToZoomRecognizer.numberOfTapsRequired = 2
        playerView.addGestureRecognizer(doubleTapToZoomRecognizer)
    }

    @objc func handleDoubleTap(_ tap: UITapGestureRecognizer) {
        if scrollView.zoomScale != scrollView.minimumZoomScale {
            // Zoom out
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // Zoom in
            let point = tap.location(in: playerView)
            scrollView.zoom(to: CGRect(origin: point, size: .zero), animated: true)
        }
    }
}

private extension UIScrollView {

    var contentView: UIView {
        return subviews.first!
    }

    func centerContentView() {
        // Offset in case width or height is smaller than scroll view width or height.
        let offsetX = max(0, bounds.width/2 - contentSize.width/2)
        let offsetY = max(0, bounds.height/2 - contentSize.height/2)

        // (Don't use `frame` directly since the scroll view applies a scale transform.)
        contentView.center = CGPoint(x: contentSize.width/2 + offsetX,
                                     y: contentSize.height/2 + offsetY)
    }

    func updateZoomRangeForContentView() {
        guard (contentSize.width != 0) && (contentSize.height != 0) else {
            (minimumZoomScale, maximumZoomScale, zoomScale) = (1, 1, 1)
            return
        }

        let widthScale = bounds.width / contentSize.width
        let heightScale = bounds.height / contentSize.height

        // Minimum zoom: Aspect fit into the scroll view.
        minimumZoomScale = min(widthScale, heightScale)
        // Maximum zoom: Aspect fill into the scroll view (at least full content size).
        maximumZoomScale = max(widthScale, heightScale, 1)

        // Initial zoom: Aspect fit.
        zoomScale = minimumZoomScale
    }
}
