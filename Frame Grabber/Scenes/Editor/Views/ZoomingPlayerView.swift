import UIKit
import AVFoundation

/// A view that manages zooming for an `AVPlayerLayer`.
/// The view is zoomed with pinch and double tap gestures.
final class ZoomingPlayerView: UIView {
    
    private enum Constant {
        static let maximumZoomFactor: CGFloat = 8
    }
    
    let playerView = PlayerView()

    var player: AVPlayer? {
        get { playerView.player }
        set {
            playerView.player = newValue
            observeVideoSize()
        }
    }

    var posterImage: UIImage? {
        get { playerView.posterImage }
        set {
            playerView.posterImage = newValue
            updateContentSize(keepingZoomIfPossible: true)
        }
    }

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

    // (? Refactor this into `intrinsicContentSize` of `PlayerView`.)
    private var videoContentSize: CGSize {
        player?.currentItem?.presentationSize.nilIfZero
            ?? playerView.posterImage?.size
            ?? .zero
    }

    private var previousSize: CGSize = .zero
    private var videoSizeObservation: Any?

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
        guard bounds.size != previousSize else { return }
        previousSize = bounds.size
        updateContentSize(keepingZoomIfPossible: false)
    }

    // MARK: Private

    private func configureViews() {
        playerView.layer.backgroundColor = nil
        clipsToBounds = true

        scrollView.addSubview(playerView)
        addSubview(scrollView)

        configureGestures()
        observeVideoSize()
    }

    private func observeVideoSize() {
        videoSizeObservation = player?.observe(\.currentItem?.presentationSize, options: .initial) { [weak self]  _, _ in
            self?.updateContentSize(keepingZoomIfPossible: true)
        }
    }

    /// Updates the scroll view's content size and zoom range.
    /// - Parameter keepingZoomIfPossible: If true keeps the same zoom level (clamped to the new minimum and maximum
    ///   level) if the content size did not change.
    private func updateContentSize(keepingZoomIfPossible: Bool) {
        let newSize = videoContentSize
        
        let sizeChanged = newSize != scrollView.unzoomedContentSize
        let keepZoom = keepingZoomIfPossible && !sizeChanged

        playerView.bounds.size = newSize
        scrollView.contentSize = newSize

        scrollView.updateZoomRange(keepingZoom: keepZoom, maximumZoomFactor: Constant.maximumZoomFactor)
        scrollView.centerContentView()
    }

    private func configureGestures() {
        doubleTapToZoomRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapToZoomRecognizer)
    }

    @objc private func handleDoubleTap(_ tap: UITapGestureRecognizer) {
        if scrollView.zoomScale < scrollView.aspectFitScale {
            scrollView.setZoomScale(scrollView.aspectFitScale, animated: true)
        } else if scrollView.zoomScale == scrollView.aspectFitScale {
            let actualMaximumZoomScale = scrollView.maximumZoomScale
            scrollView.maximumZoomScale = scrollView.aspectFillScale
            scrollView.zoomIn(at: tap.location(in: playerView), animated: true)
            scrollView.maximumZoomScale = actualMaximumZoomScale
        } else {
            scrollView.setZoomScale(scrollView.aspectFitScale, animated: true)
        }
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

// MARK: - UIScrollView

extension UIScrollView {

    /// The first (and ideally only) subview.
    /// - Note: If this view does not exist, fails.
    fileprivate var contentView: UIView {
        precondition(subviews.first != nil, "Content view must exist.")
        return subviews.first!
    }

    /// The unzoomed size of the content view in contrast to `contentSize` which reports the scaled size.
    /// - Note: This assumes that `contentSize` corresponds to the size of the content view.
    fileprivate var unzoomedContentSize: CGSize {
        contentView.bounds.size
    }

    fileprivate var widthScale: CGFloat {
        guard unzoomedContentSize.width != 0 else { return 1 }
        return bounds.width / unzoomedContentSize.width
    }

    fileprivate var heightScale: CGFloat {
        guard unzoomedContentSize.height != 0 else { return 1 }
        return bounds.height / unzoomedContentSize.height
    }

    fileprivate var aspectFitScale: CGFloat {
        min(widthScale, heightScale)
    }

    fileprivate var aspectFillScale: CGFloat {
        max(widthScale, heightScale)
    }

    /// The full scale ajusted with the screen scale.
    fileprivate var fullSizeScreenScale: CGFloat {
        1.0 / UIScreen.main.scale
    }

    fileprivate func updateZoomRange(keepingZoom: Bool = true, maximumZoomFactor: CGFloat = 1) {
        let previousScale = zoomScale

        minimumZoomScale = min(aspectFitScale, fullSizeScreenScale)
        maximumZoomScale = max(aspectFillScale, fullSizeScreenScale * maximumZoomFactor)
        
        zoomScale = keepingZoom ? previousScale : aspectFitScale
    }

    fileprivate func zoomIn(at point: CGPoint, animated: Bool) {
        zoom(to: CGRect(origin: point, size: .zero), animated: animated)
    }

    fileprivate func centerContentView() {
        // Offset in case width or height is smaller than scroll view width or height.
        let offsetX = max(0, bounds.width/2 - contentSize.width/2)
        let offsetY = max(0, bounds.height/2 - contentSize.height/2)

        // (Don't set `frame` directly since the scroll view applies a scale transform.)
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
