import UIKit
import AVKit

protocol ZoomingPlayerViewDelegate: class {
    func playerViewDidZoom(_ playerView: ZoomingPlayerView)
    func playerView(_ playerView: ZoomingPlayerView, didUpdateReadyForDisplay ready: Bool)
}

extension ZoomingPlayerViewDelegate {
    func playerViewDidZoom(_ playerView: ZoomingPlayerView) {}
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

    /// The current size and position of the video image as displayed within the player
    /// view's bounds. If the video is zoomed in, the rect may exceed the player view's
    /// bounds.
    var zoomedVideoRect: CGRect {
        return playerView.convert(playerView.bounds, to: self)
    }

    private let scrollView = UIScrollView()
    private var unzoomedContentSize: CGSize?  // Zooming scales the content size
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
        updatePlayerViewSize()
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomingPlayerView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return playerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.centerContentView()
        delegate?.playerViewDidZoom(self)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.playerViewDidZoom(self)
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
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast

        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        scrollView.addSubview(playerView)
        addSubview(scrollView)

        observeLayerReady()
        configureGestures()
        updatePlayerViewSize()
    }

    func observeLayerReady() {
        layerReadyObserver = playerView.playerLayer.observe(\.isReadyForDisplay, options: .initial) { [weak self] layer, _ in
            guard let this = self else { return }
            this.delegate?.playerView(this, didUpdateReadyForDisplay: layer.isReadyForDisplay)
        }
    }

    func observePlayerItemSize() {
        playerItemSizeObserver = player?.observe(\.currentItem?.presentationSize, options: .initial) { [weak self]  _, _ in
            self?.updatePlayerViewSize()
        }
    }

    func updatePlayerViewSize() {
        // Fill scroll view if player item is not ready
        // (item can be `nil` or its size can be zero when it's not ready to play yet)
        let videoSize = player?.currentItem?.presentationSize ?? .zero
        let newContentSize = (videoSize != .zero) ? videoSize : scrollView.bounds.size

        // Remain zoomed in if the player item changed but has the same size
        // (this is to avoid zooming out when looping the same video)
        guard newContentSize != unzoomedContentSize else { return }

        unzoomedContentSize = newContentSize
        playerView.bounds.size = newContentSize
        scrollView.contentSize = newContentSize

        scrollView.updateZoomRangeForContentView()
        scrollView.centerContentView()
    }

    func configureGestures() {
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        playerView.addGestureRecognizer(doubleTapRecognizer)
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

    /// Assuming content view is the only subview
    var contentView: UIView {
        return subviews.first!
    }

    func centerContentView() {
        // Offset in case width or height is smaller than scroll view width or height
        let offsetX = max(0, bounds.width/2 - contentSize.width/2)
        let offsetY = max(0, bounds.height/2 - contentSize.height/2)

        // (Don't use `frame` directly since the scroll view applies a scale transform)
        contentView.center = CGPoint(x: contentSize.width/2 + offsetX,
                                     y: contentSize.height/2 + offsetY)
    }

    func updateZoomRangeForContentView() {
        let widthScale = bounds.width / contentSize.width
        let heightScale = bounds.height / contentSize.height

        // Minimum zoom: Aspect fit into the scroll view
        minimumZoomScale = min(widthScale, heightScale)
        // Maximum zoom: Aspect fill into the scroll view (at least full content size)
        maximumZoomScale = max(widthScale, heightScale, 1)

        // Initial zoom: Aspect fit
        zoomScale = minimumZoomScale
    }
}
