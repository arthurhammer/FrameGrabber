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
    
    override public var isEnabled: Bool {
        didSet {
            handle.isEnabled = isEnabled
            track.isEnabled = isEnabled
            updateViews()
        }
    }

    public var trackRect: CGRect {
        track.frame
    }

    public var handleRect: CGRect {
        track.convert(handle.frame, to: self)
    }
    
    /// A layout guide that can be used to anchor views relative to the slider's handle.
    public private(set) lazy var handleLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()
        addLayoutGuide(guide)
        guide.topAnchor.constraint(equalTo: handle.topAnchor).isActive = true
        guide.bottomAnchor.constraint(equalTo: handle.bottomAnchor).isActive = true
        guide.leadingAnchor.constraint(equalTo: handle.leadingAnchor).isActive = true
        guide.trailingAnchor.constraint(equalTo: handle.trailingAnchor).isActive = true
        return guide
    }()
    
    // MARK: - Private Properties

    private var _time: CMTime = .zero

    private var previousSize: CGSize = .zero
    private var reloadId: UUID?
    private var initialTrackingTouchLocation: CGPoint = .zero
    private var initialTrackingHandleLocation: CGPoint = .zero

    private let borderWidth: CGFloat = 1
    private let disabledBorderColor = UIColor.systemGray4
    
    private let handleWidth: CGFloat = 8
    private let handleCornerRadius: CGFloat = 2
    private let handleColor: UIColor = .white
    private let disabledHandleColor: UIColor = .systemGray3
    private lazy var verticalHandleInset = borderWidth

    private let trackColor: UIColor = .secondarySystemFill
    private let trackCornerRadius: CGFloat = 12
    private let verticalTrackInset: CGFloat = 0
    private let minimumThumbnailWidth: CGFloat = 8
    private let maximumThumbnailWidth: CGFloat = 90

    private let intrinsicHeight: CGFloat = 54
    private let intrinsicCompactHeight: CGFloat = 38
    private let animationDuration: TimeInterval = 0.2
    private let accessibilityIncrementPercentage: TimeInterval = 0.05

    private lazy var handle: ThumbnailSliderHandle = {
        let frame = CGRect(x: 0, y: 0, width: handleWidth, height: bounds.height)
            .insetBy(dx: 0, dy: verticalHandleInset)
        let view = ThumbnailSliderHandle(frame: frame)
        view.autoresizingMask = .flexibleHeight
        view.handleColor = handleColor
        view.disabledHandleColor = disabledHandleColor
        view.layer.cornerRadius = handleCornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private lazy var track: ThumbnailSliderTrack = {
        let view = ThumbnailSliderTrack(frame: bounds.insetBy(dx: 0, dy: verticalTrackInset))
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = trackColor
        view.layer.cornerRadius = trackCornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private lazy var accessibilityValueFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .default
        formatter.unitsStyle = .spellOut
        formatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
        return formatter
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

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != previousSize else { return }

        previousSize = bounds.size
        updateHandlePosition()
        reloadThumbnails()
    }
    
    override public var intrinsicContentSize: CGSize {
        traitCollection.verticalSizeClass == .compact
            ? CGSize(width: UIView.noIntrinsicMetric, height: intrinsicCompactHeight)
            : CGSize(width: UIView.noIntrinsicMetric, height: intrinsicHeight)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            invalidateIntrinsicContentSize()
        }
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateViews()
        }
    }

    // MARK: - Setting Time

    public func setTime(_ time: CMTime, animated: Bool) {
        _time = time.numericOrZero.clamped(to: .zero, and: duration)
        accessibilityValue = accessibilityValueFormatter.string(from: _time.seconds.rounded())

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

    // MARK: Accessibility

    public override func accessibilityIncrement() {
        let newTime = time + CMTimeMultiplyByFloat64(duration, multiplier: Float64(accessibilityIncrementPercentage))
        setTime(newTime, animated: true)
        sendActions(for: .valueChanged)
    }

    public override func accessibilityDecrement() {
        let newTime = time - CMTimeMultiplyByFloat64(duration, multiplier: Float64(accessibilityIncrementPercentage))
        setTime(newTime, animated: true)
        sendActions(for: .valueChanged)
    }

    // MARK: - Loading Thumbnails

    /// Reloads thumbnails.
    ///
    /// The slider calls this automatically when the slider's size, duration or data source change.
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

            guard self?.reloadId == currentId else { return }

            self?.track.thumbnailViews[index].setImage(image, animated: true)
        }
    }

    // MARK: - Tracking Touches
    
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Disable any recognizer inside the slider (e.g. the navigation default back swipe gesture)
        false
    }

    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)

        let point = touch.location(in: self)

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
        clipsToBounds = true
        
        track.addSubview(handle)
        addSubview(track)
        updateHandlePosition()
        
        backgroundColor = nil
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 6
        layer.shadowOffset = .zero
        
        layer.cornerRadius = trackCornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = borderWidth
        layer.borderColor = tintColor.cgColor
        
        isAccessibilityElement = true
        accessibilityTraits.insert(.adjustable)
    }
    
    private func updateViews() {
        layer.borderColor = isEnabled ? tintColor.cgColor : disabledBorderColor.cgColor
    }

    // MARK: - Utilities

    private func updateHandlePosition() {
        handle.frame.origin.x = handlePosition(for: _time)
        track.progressTintView.frame.size.width = trackPosition(for: _time)
        track.progressTintView.frame.origin = .zero
    }
    
    /// The track position of the current time clamped to the edges.
    private func handlePosition(for time: CMTime) -> CGFloat {
        let center = trackPosition(for: _time)
        let origin = center - handleWidth/2
        let leftEdge = borderWidth
        let rightEdge = track.frame.maxX - handleWidth - borderWidth
        
        return origin.clamped(to: leftEdge, and: rightEdge)
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
