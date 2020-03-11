import UIKit
import AVFoundation

/// A view that manages zooming for an `AVPlayerLayer`.
/// The view is zoomed with pinch and double tap gestures.
class ZoomingPlayerView: UIView {

    @objc dynamic var player: AVPlayer? {
        get { playerView.player }
        set { playerView.player = newValue }
    }

    let playerView = PlayerView()

    var posterImage: UIImage? {
        get { playerView.posterImageView.image }
        set {
            playerView.posterImageView.image = newValue
            updateContentSize(with: videoContentSize, keepingZoomIfPossible: true)
        }
    }

    private let overZoomFactor: CGFloat = 4

    private(set) lazy var doubleTapToZoomRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.clipsToBounds = false
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = .fast
        return scrollView
    }()

    private var videoContentSize: CGSize {
        player?.currentItem?.presentationSize.nilIfZero
            ?? playerView.posterImageView.image?.size
            ?? .zero
    }

    private var videoSizeObserver: NSKeyValueObservation?

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
        updateContentSize(with: videoContentSize, keepingZoomIfPossible: true)
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

        scrollView.addSubview(playerView)
        addSubview(scrollView)

        configureGestures()
        observeVideoSize()
    }

    func observeVideoSize() {
        videoSizeObserver = observe(\.player?.currentItem?.presentationSize, options: .initial) { [weak self]  _, _ in
            guard let self = self else { return }
            self.updateContentSize(with: self.videoContentSize, keepingZoomIfPossible: true)
        }
    }

    /// Updates the scroll view's content size and zoom range.
    /// - Parameter keepingZoomIfPossible: If true keeps the same zoom level (clamped to
    ///   the new minimum and maximum level) if the content size did not change.
    func updateContentSize(with newSize: CGSize, keepingZoomIfPossible: Bool) {
        let sizeChanged = newSize != scrollView.unzoomedContentSize
        let shouldKeepZoom = keepingZoomIfPossible && !sizeChanged

        playerView.bounds.size = newSize
        scrollView.contentSize = newSize

        scrollView.updateZoomRange(keepingZoom: shouldKeepZoom, overZoomFactor: overZoomFactor)
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
            scrollView.maximumZoomScale = max(scrollView.aspectFillScale, scrollView.fullSizeScreenScale) * overZoomFactor
        } else {
            scrollView.zoomOut(animated: true)
        }
    }
}

// MARK: - UIScrollView

private extension UIScrollView {

    /// The first (and ideally only) subview.
    /// - Note: If this view does not exist, fails.
    var contentView: UIView {
        precondition(subviews.first != nil, "Content view must exist.")
        return subviews.first!
    }

    /// The unzoomed size of the content view in contrast to `contentSize` which reports
    /// the scaled size.
    /// - Note: This assumes that `contentSize` corresponds to the size of the content view.
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

    /// The full scale ajusted with the screen scale.
    var fullSizeScreenScale: CGFloat {
        1.0 / UIScreen.main.scale
    }

    func updateZoomRange(keepingZoom: Bool = true, overZoomFactor: CGFloat = 1) {
        let previousScale = zoomScale

        minimumZoomScale = aspectFitScale
        maximumZoomScale = max(aspectFillScale, fullSizeScreenScale) * overZoomFactor
        zoomScale = keepingZoom ? previousScale : aspectFitScale
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
