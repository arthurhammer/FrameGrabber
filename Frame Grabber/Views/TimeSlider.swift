import UIKit

/// A slider with a fixed-position value indicator and a moving progress bar.
public class TimeSlider: UIControl {

    public var value: Float {
        get { return _value }
        set { setValue(newValue, animated: false) }
    }

    public func setValue(_ value: Float, animated: Bool) {
        _value = value.clamped(to: minimumValue, and: maximumValue)
        updateScrollViewOffsetForValue(animated: animated)
    }

    public var minimumValue: Float = 0 {
        didSet {
            // Follows `UISlider` behaviour.
            if minimumValue > maximumValue {
                maximumValue = minimumValue
            }

            // Clamp value to new range and update offset.
            setValue(value, animated: false)
        }
    }

    public var maximumValue: Float = 1 {
        didSet {
            if maximumValue < minimumValue {
                minimumValue = maximumValue
            }

            setValue(value, animated: false)
        }
    }

    /// Whether the slider moves or continues to move from a user interaction.
    public var isInteracting: Bool {
        return scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating
    }

    override public var isEnabled: Bool {
        didSet { updateViews() }
    }

    public var valueIndicatorWidth: CGFloat = 3 {
        didSet { setNeedsLayout() }
    }

    public var valueIndicatorCornerRadius: CGFloat = 2 {
        didSet { updateViews() }
    }

    public var trackHeight: CGFloat = 24 {
        didSet { setNeedsLayout() }
    }

    public var trackCornerRadius: CGFloat = 4 {
        didSet { updateViews() }
    }

    public var trackEdgeCornerRadius: CGFloat = 2 {
        didSet { updateViews() }
    }

    public var trackColor: UIColor = .white {
        didSet { updateViews() }
    }

    public var disabledTrackColor: UIColor = UIColor.white.withAlphaComponent(0.2) {
        didSet { updateViews() }
    }

    override public func tintColorDidChange() {
        updateViews()
    }

    // MARK: Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required public init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        configureViews()
    }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 30)
    }

    // Manual layout instead of AutoLayout.
    override public func layoutSubviews() {
        super.layoutSubviews()

        let scrollViewOrigin = CGPoint(x: 0, y: floor(bounds.midY - trackHeight/2))
        let trackSize = CGSize(width: bounds.width, height: trackHeight)

        scrollView.frame = CGRect(origin: scrollViewOrigin, size: trackSize)
        scrollView.contentSize = trackSize
        // Scrolling is enabled through the insets.
        scrollView.contentInset = UIEdgeInsets(top: 0, left: bounds.midX, bottom: 0, right: bounds.midX)

        progressTrack.frame = CGRect(origin: .zero, size: trackSize)

        let valueIndicatorX = floor(bounds.midX - valueIndicatorWidth / 2)
        valueIndicator.frame = CGRect(x: valueIndicatorX, y: 0, width: valueIndicatorWidth, height: bounds.height)

        updateScrollViewOffsetForValue(animated: false)
    }

    // MARK: Private

    // Separate value storage avoids `value` and `setValue` recursively calling each other.
    private var _value: Float = 0

    private let scrollView = UIScrollView()
    private let progressTrack = UIView()
    private let valueIndicator = UIView()

    private func configureViews() {
        backgroundColor = .clear

        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = true
        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast

        scrollView.addSubview(progressTrack)
        addSubview(scrollView)
        addSubview(valueIndicator)

        updateViews()
        setValue(value, animated: false)  // Scroll to initial value
    }

    private func updateViews() {
        scrollView.layer.cornerRadius = trackEdgeCornerRadius

        progressTrack.backgroundColor = isEnabled ? trackColor : disabledTrackColor
        progressTrack.layer.cornerRadius = trackCornerRadius

        valueIndicator.backgroundColor = tintColor
        valueIndicator.layer.cornerRadius = valueIndicatorCornerRadius
    }

    private func updateScrollViewOffsetForValue(animated: Bool) {
        scrollView.setContentOffset(offset(for: value), animated: animated)
    }

    private func updateValueForScrollViewOffset() {
        _value = value(for: scrollView.contentOffset)
    }

    // MARK: Util

    private func offset(for value: Float) -> CGPoint {
        let inset = scrollView.contentInset.left
        let relativeValue = value.relative(between: minimumValue, and: maximumValue)
        let offset = CGFloat(relativeValue) * bounds.width - inset

        return CGPoint(x: offset, y: 0)
    }

    private func value(for offset: CGPoint) -> Float {
        let inset = scrollView.contentInset.left
        let relativeOffset = (offset.x + inset) / bounds.width

        return Float(relativeOffset).absolute(between: minimumValue, and: maximumValue)
    }
}

// MARK: - UIScrollViewDelegate

extension TimeSlider: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Only update value for UI-driven change (programmatic `setValue` changes scroll
        // view offset which calls `scrollViewDidScroll` which would again change value).
        // (This also avoids the case where `slider.value = 3; slider.value == 3` is false
        // due to imperfect conversion from value to offset and back again.)
        guard isInteracting else { return }

        updateValueForScrollViewOffset()
        sendActions(for: .valueChanged)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }

        updateValueForScrollViewOffset()
        sendActions(for: .valueChanged)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateValueForScrollViewOffset()
        sendActions(for: .valueChanged)
    }
}

// MARK: - Util

private extension Comparable {
    func clamped(to lower: Self, and upper: Self) -> Self {
        assert(lower <= upper, "\(lower), \(upper)")
        return max(lower, min(upper, self))
    }
}

private extension BinaryFloatingPoint {
    /// Example: `0.5.absolute(between: 1, and: 7) == 4`
    func absolute(between min: Self, and max: Self) -> Self {
        let value = clamped(to: 0, and: 1)
        return value * (max - min) + min
    }

    /// Example: `8.relative(between: 0, and: 10) == 0.8`
    func relative(between min: Self, and max: Self) -> Self {
        guard min != max else { return 0 }
        let value = clamped(to: min, and: max)
        return (value - min) / (max - min)
    }
}
