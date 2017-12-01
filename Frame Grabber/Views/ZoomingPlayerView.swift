import UIKit
import AVKit

protocol ZoomingPlayerViewDelegate: class {
    func playerViewDidZoom(_ playerView: ZoomingPlayerView)
}

/// A view that manages zooming for an `AVPlayerLayer`.
/// The view is zoomed with pinch and double tap gestures.
class ZoomingPlayerView: UIView {

    weak var delegate: ZoomingPlayerViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    var player: AVPlayer? {
        get {
            return playerView.player
        }
        set {
            playerView.player = newValue

            presentationSizeObserver = player?.observe(\.currentItem?.presentationSize, options: .initial) { [weak self]  _, _ in
                self?.updatePlayerViewSize()
            }
        }
    }

    /// The current size and position of the video image as displayed within the player view's bounds.
    /// If the video is zoomed, the rect may exceed the player view's bounds.
    var zoomedVideoRect: CGRect {
        return playerView.convert(playerView.bounds, to: self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        updatePlayerViewSize()
    }

    private let scrollView = UIScrollView()
    private let playerView = PlayerView()
    private var presentationSizeObserver: NSKeyValueObservation?
    private var unzoomedContentSize: CGSize?  // Zooming scales the content size
}

extension ZoomingPlayerView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return playerView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.playerViewDidZoom(self)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.centerContentView()
        delegate?.playerViewDidZoom(self)
    }

    // TODO
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.playerViewDidZoom(self)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.playerViewDidZoom(self)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.playerViewDidZoom(self)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        delegate?.playerViewDidZoom(self)
    }
}

// MARK: - Private

private extension ZoomingPlayerView {

    func configureViews() {
        playerView.playerLayer.backgroundColor = nil

        scrollView.frame = bounds
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast

        scrollView.addSubview(playerView)
        addSubview(scrollView)

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        playerView.addGestureRecognizer(doubleTapRecognizer)

        updatePlayerViewSize()
    }

    func updatePlayerViewSize() {
        // Fill scroll view if player item not ready (item can be nil or its size can be zero when its not yet ready to play)
        let itemSize = playerView.player?.currentItem?.presentationSize ?? .zero
        let size = (itemSize != .zero) ? itemSize : scrollView.bounds.size

        // Remained zoomed in if the player item changes but has the same size
        guard size != unzoomedContentSize else { return }

        unzoomedContentSize = size
        playerView.bounds.size = size
        scrollView.contentSize = size

        scrollView.updateZoomScalesForContentView()
        scrollView.centerContentView()
    }

    @objc func handleDoubleTap(_ tap: UITapGestureRecognizer) {
        // Zoom out
        if scrollView.zoomScale != scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }

        // Zoom in
        let point = tap.location(in: playerView)
        scrollView.zoom(to: CGRect(origin: point, size: .zero), animated: true)
    }
}

private extension UIScrollView {

    /// Assuming content view is the only or first subview
    var contentView: UIView {
        return subviews.first!
    }

    func zoomOut(animated: Bool) {
        setZoomScale(minimumZoomScale, animated: animated)
    }

    func centerContentView() {
        // Offset in case width or height is smaller than scroll view width or height
        let offsetX = max(0, bounds.width/2 - contentSize.width/2)
        let offsetY = max(0, bounds.height/2 - contentSize.height/2)

        // Use `center` (not `frame`) since the scroll view applies a scale transform
        contentView.center = CGPoint(x: contentSize.width/2 + offsetX,
                                     y: contentSize.height/2 + offsetY)
    }

    func updateZoomScalesForContentView() {
        let widthScale = bounds.width / contentSize.width
        let heightScale = bounds.height / contentSize.height
        let minScale = min(widthScale, heightScale)
        let maxScale = max(widthScale, heightScale, 1)  // Fill width or height in case item is smaller than scroll view

        minimumZoomScale = minScale
        maximumZoomScale = maxScale

        // Initial size: Aspect fit
        zoomScale = minScale
    }
}
