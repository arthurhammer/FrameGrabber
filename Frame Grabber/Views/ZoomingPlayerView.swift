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
        get { playerView.player }
        set {
            playerView.player = newValue
            observeVideoSize()
        }
    }

    let playerView = PreviewPlayerView()

    var posterImageView: UIImageView {
        playerView.posterImageView
    }

    var isReadyForDisplay: Bool {
        playerView.playerLayer.isReadyForDisplay
    }

    /// The current size and position of the full video image in the receiver. If the
    /// player is not ready, is `zero`.
    var zoomedVideoFrame: CGRect {
        guard playerView.frame.size != .zero else { return .zero }
        return scrollView.convert(playerView.frame, to: self)
    }

    private(set) lazy var doubleTapToZoomRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))

    private let scrollView = UIScrollView()
    private var previousSize = CGSize.zero
    private var videoSizeObserver: NSKeyValueObservation?
    private var readyForDisplayObserver: NSKeyValueObservation?

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

        // Reset scroll view setup on rotation etc.
        updatePlayerSize(keepingZoomIfPossible: false)
        scrollView.centerContentView()
        previousSize = bounds.size
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomingPlayerView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        playerView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.centerContentView()
    }
}

// MARK: - Private

private extension ZoomingPlayerView {

    func configureViews() {
        playerView.playerLayer.backgroundColor = nil

        clipsToBounds = true
        scrollView.clipsToBounds = false

        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = .fast

        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        scrollView.addSubview(playerView)
        addSubview(scrollView)

        observeReadyForDisplay()
        configureGestures()
        updatePlayerSize(keepingZoomIfPossible: false)
    }

    func observeReadyForDisplay() {
        readyForDisplayObserver = playerView.playerLayer.observe(\.isReadyForDisplay, options: .initial) { [weak self] layer, _ in
            guard let self = self else { return }
            self.delegate?.playerView(self, didUpdateReadyForDisplay: layer.isReadyForDisplay)
        }
    }

    func observeVideoSize() {
        videoSizeObserver = player?.observe(\.currentItem?.presentationSize, options: .initial) { [weak self]  _, _ in
            self?.updatePlayerSize(keepingZoomIfPossible: true)
        }
    }

    func updatePlayerSize(keepingZoomIfPossible: Bool) {
        let videoSize = player?.currentItem?.presentationSize.nilIfZero ?? playerView.posterImageView.image?.size ?? .zero

        // Remain zoomed in if the player item changed but has same size (to avoid zooming
        // out when looping the same video).
        if keepingZoomIfPossible && (videoSize == scrollView.unzoomedContentSize) {
            return
        }

        playerView.bounds.size = videoSize
        scrollView.contentSize = videoSize

        scrollView.updateZoomRange()
        scrollView.centerContentView()
    }

    func configureGestures() {
        doubleTapToZoomRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapToZoomRecognizer)
    }

    @objc func handleDoubleTap(_ tap: UITapGestureRecognizer) {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            scrollView.maximumZoomScale = scrollView.aspectFillScale
            scrollView.zoomIn(at: tap.location(in: playerView), animated: true)
            scrollView.maximumZoomScale = max(scrollView.aspectFillScale, scrollView.fullSizeScreenScale)
        } else {
            scrollView.zoomOut(animated: true)
        }
    }
}

// MARK: - UIScrollView

private extension UIScrollView {

    /// The first (and ideally only) subview.
    var contentView: UIView {
        subviews.first!
    }

    /// The original, unzoomed size of the content view in contrast to `contentSize` which
    /// reports the scaled size.
    /// - note: `contentSize` must be synced with the size of the content view.
    var unzoomedContentSize: CGSize {
        contentView.bounds.size
    }

    var widthScale: CGFloat {
        guard unzoomedContentSize.width != 0 else { return 0 }
        return bounds.width / unzoomedContentSize.width
    }

    var heightScale: CGFloat {
        guard unzoomedContentSize.height != 0 else { return 0 }
        return bounds.height / unzoomedContentSize.height
    }

    var aspectFitScale: CGFloat {
        min(widthScale, heightScale)
    }

    var aspectFillScale: CGFloat {
        max(widthScale, heightScale)
    }

    /// The full scale ajusted with the screen scale (for visual media on retina screens).
    var fullSizeScreenScale: CGFloat {
        1.0 / UIScreen.main.scale
    }

    func updateZoomRange() {
        minimumZoomScale = aspectFitScale
        maximumZoomScale = max(aspectFillScale, fullSizeScreenScale)
        zoomScale = aspectFitScale
    }

    func zoomIn(at point: CGPoint, animated: Bool) {
        zoom(to: CGRect(origin: point, size: .zero), animated: animated)
    }

    func zoomOut(animated: Bool) {
        setZoomScale(minimumZoomScale, animated: animated)
    }

    func centerContentView() {
        // Offset in case width or height is smaller than scroll view width or height.
        let offsetX = max(0, bounds.width/2 - contentSize.width/2)
        let offsetY = max(0, bounds.height/2 - contentSize.height/2)

        // (Don't use `frame` directly since the scroll view applies a scale transform.)
        contentView.center = CGPoint(x: contentSize.width/2 + offsetX,
                                     y: contentSize.height/2 + offsetY)
    }
}

private extension CGSize {
    var nilIfZero: CGSize? {
        if self == .zero { return nil }
        return self
    }
}
