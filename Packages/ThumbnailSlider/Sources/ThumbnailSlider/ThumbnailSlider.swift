import CoreMedia
import UIKit

public class ThumbnailSlider: UIControl {

    public weak var dataSource: ThumbnailSliderDataSource? {
        didSet { reloadThumbnails() }
    }

    public var time: CMTime {
        get { _time }
        set { setTime(newValue, animated: false) }
    }

    /// Negative and non-numeric values are treated as `.zero`.
    public var duration: CMTime = .zero {
        didSet {
            duration = duration.numericOrZero
            duration = (duration < .zero) ? .zero : duration

            setTime(time, animated: false)

            if duration != oldValue {
                reloadThumbnails()
            }
        }
    }

    public var trackRect: CGRect {
        track.frame
    }

    public var handleRect: CGRect {
        handle.frame
    }

    override public var isEnabled: Bool {
        didSet {
            handle.isEnabled = isEnabled
            track.isEnabled = isEnabled
        }
    }

    // MARK: - Private Properties

    private var _time: CMTime = .zero

    private var previousSize: CGSize = .zero
    private var reloadId: UUID?
    private var initialTrackingTouchLocation: CGPoint = .zero
    private var initialTrackingHandleLocation: CGPoint = .zero

    private let handleWidth: CGFloat = 10
    private let handleCornerRadius: CGFloat = 4
    private let handleColor: UIColor = .white
    private let disabledHandleColor: UIColor = .systemGray4

    private let trackColor: UIColor = .tertiarySystemFill
    private let trackCornerRadius: CGFloat = 8
    private let verticalTrackInset: CGFloat = 4
    private let minimumThumbnailWidth: CGFloat = 8
    private let maximumThumbnailWidth: CGFloat = 90

    private let intrinsicHeight: CGFloat = 50
    private let minimumTouchTarget = CGSize(width: 44, height: 44)
    private let animationDuration: TimeInterval = 0.2

    private lazy var handle: ThumbnailSliderHandle = {
        let view = ThumbnailSliderHandle(
            frame: CGRect(x: 0, y: 0, width: handleWidth, height: bounds.height)
        )
        view.autoresizingMask = .flexibleHeight
        view.handleColor = handleColor
        view.disabledHandleColor = disabledHandleColor
        view.layer.cornerRadius = handleCornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 6
        view.layer.shadowOffset = .zero
        return view
    }()

    private lazy var track: ThumbnailSliderTrack = {
        let view = ThumbnailSliderTrack(
            frame: bounds.insetBy(dx: handleWidth/2, dy: verticalTrackInset)
        )
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = trackColor
        view.layer.cornerRadius = trackCornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: intrinsicHeight)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != previousSize else { return }

        previousSize = bounds.size
        updateHandlePosition()
        reloadThumbnails()
    }

    // MARK: - Setting Time

    public func setTime(_ time: CMTime, animated: Bool) {
        _time = time.numericOrZero.clamped(to: .zero, and: duration)

        if animated {
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: .beginFromCurrentState,
                animations: updateHandlePosition
            )
        } else {
            updateHandlePosition()
        }
    }

    // MARK: - Loading Thumbnails

    /// Reloads thumbnails.
    ///
    /// The slider calls this automatically when the slider's size, duration or data source changes.
    public func reloadThumbnails() {
        track.clearThumbnails()

        guard let aspectRatio = dataSource?.thumbnailAspectRatio(in: self) else { return }

        track.makeThumbnails(
            withAspectRatio: aspectRatio,
            minimumWidth: minimumThumbnailWidth,
            maximumWidth: maximumThumbnailWidth
        )

        loadThumbnails()
    }

    private func loadThumbnails() {
        let times = track
            .thumbnailOffsets(in: self)
            .map(time(for:))

        let size = track.thumbnailSize.scaledToScreen

        reloadId = UUID()
        let currentId = reloadId

        dataSource?.slider(self, loadThumbnailsForTimes: times, size: size) {
            [weak self] (index, image) in

            let isCurrent = self?.reloadId == currentId

            if isCurrent {
                let imageView = self?.track.thumbnailViews[index]
                imageView?.setImage(image, animated: true)
            }
        }
    }

    // MARK: - Tracking Touches

    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)

        let point = touch.location(in: self)

        guard handle.touchTarget.contains(point) else { return false }

        initialTrackingTouchLocation = point
        initialTrackingHandleLocation = handle.center

        DispatchQueue.main.async {  // Send after `touchDown` event.
            self.sendActions(for: .valueChanged)
        }

        return true
    }

    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)

        // Since touch target can be bigger than handle, position relative to initial locations.
        let offset = touch.location(in: self).x - initialTrackingTouchLocation.x
        let position = initialTrackingHandleLocation.x + offset

        time = time(for: position)
        sendActions(for: .valueChanged)

        return true
    }

    // MARK: - Configuring

    private func configureViews() {
        backgroundColor = nil
        addSubview(track)
        addSubview(handle)
        updateHandlePosition()
    }

    // MARK: - Utilities

    private func updateHandlePosition() {
        handle.center.x = trackPosition(for: _time)
    }

    private func trackPosition(for time: CMTime) -> CGFloat {
        let trackFrame = track.frame

        guard duration.seconds != .zero else { return trackFrame.minX }

        let progress = time.seconds / duration.seconds
        let range = trackFrame.maxX - trackFrame.minX
        let position = trackFrame.minX + CGFloat(progress) * range

        return position.clamped(to: trackFrame.minX, and: trackFrame.maxX)
    }

    private func time(for trackPosition: CGFloat) -> CMTime {
        let trackFrame = track.frame
        let range = trackFrame.maxX - trackFrame.minX

        guard range != 0 else { return .zero }

        let progress = (trackPosition - trackFrame.minX) / range
        let time = CMTimeMultiplyByFloat64(duration, multiplier: Float64(progress))

        return time.numericOrZero.clamped(to: .zero, and: duration)
    }
}
