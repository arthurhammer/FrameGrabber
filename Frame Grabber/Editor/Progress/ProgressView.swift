import UIKit

/// Basic progress view for both indeterminate and determinate progress.
/// Currently only supported as is from the storyboard. Do not add this view directly to
/// the view hierarchy, instead use `show` and `hide`.
class ProgressView: UIView {

    enum Progress: Equatable {
        case determinate(Float)
        case indeterminate
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var determinateProgressView: CircularProgressView!
    @IBOutlet var indeterminateProgressView: UIActivityIndicatorView!

    /// The time between calling `show` and the view appearing. If `hide` is called
    /// within that time frame, the view is not shown (and `minimumShowDuration` has no
    /// effect).
    var showDelay: TimeInterval = 0.1 {
        didSet { showDelay = max(0, showDelay) }
    }

    /// The minimum time to show the view. If `hide` is called before that time is over,
    /// hiding is delayed until it is.
    ///
    /// - Note: `minimumShowDuration` is added on top of `showDelay`, i.e. between
    /// calling `show` and the view hiding later there is, in the general case, at least a
    /// time of `showDelay + minimumShowDuration`.
    var minimumShowDuration: TimeInterval = 0.45 {
        didSet { minimumShowDuration = max(0, minimumShowDuration) }
    }

    /// Animation duration for showing and hiding the view.
    var animationDuration: TimeInterval = 0.15 {
        didSet { animationDuration = max(0, animationDuration) }
    }

    private var isScheduledToShow = false
    private var lastShown: Date = .distantPast
    private var timer: Timer?
    private let superviewMargins: CGFloat = 16

    private var isShown: Bool {
        superview != nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    deinit {
        cancelTimer()
    }

    /// Shows the view in the specified container, taking into account `showDelay`.
    ///
    /// If the view is already in the container, this has no effect, including when the
    /// view is currently scheduled to hide within in the same container. If the view is
    /// currently scheduled to hide in another container, hides immediately and schedules
    /// to show in the new container.
    func show(in view: UIView, animated: Bool = true, completion: (() -> ())? = nil) {
        guard !view.subviews.contains(self) else {
            completion?()
            return
        }

        cancelTimer()
        doShow(false, animated: false)
        isScheduledToShow = true

        let show = { [weak self] (_: Any?) in
            guard let self = self else { return }

            self.cancelTimer()
            self.isScheduledToShow = false
            self.lastShown = Date()

            view.addSubview(self)
            self.center(in: view)
            self.doShow(true, animated: animated)
            completion?()
        }

        if showDelay > 0 {
            timer = .scheduledTimer(withTimeInterval: showDelay, repeats: false, block: show)
        } else {
            show(nil)
        }
    }

    /// Hides the view, taking into account `showDelay` and `minimumShowDuration`.
    ///
    /// Hides synchronously if the view has been shown for at least `minimumShowDuration`.
    /// Otherwise, schedules to hide after the remaining time. If the view is not yet shown
    /// but scheduled to show, cancels showing it.
    func hide(animated: Bool = true, completion: (() -> ())? = nil) {
        let isScheduledToShow = !isShown && self.isScheduledToShow
        let earliestHideDate = lastShown + minimumShowDuration
        let now = Date()
        let hideNow = earliestHideDate <= now

        cancelTimer()
        self.isScheduledToShow = false

        let hide = { [weak self] (animated: Bool) in
            self?.cancelTimer()
            self?.isScheduledToShow = false
            self?.doShow(false, animated: animated)
            completion?()
        }

        if isScheduledToShow {
            hide(false)
        } else if hideNow {
            hide(animated)
        } else {
            let remaining = now.distance(to: earliestHideDate)
            timer = .scheduledTimer(withTimeInterval: remaining, repeats: false) { _ in
                hide(animated)
            }
        }
    }

    /// Sets the view's determinate or indeterminate progress.
    func setProgress(_ progress: Progress, animated: Bool) {
        switch progress {

        case .indeterminate:
            determinateProgressView.isHidden = true
            indeterminateProgressView.isHidden = false
            indeterminateProgressView.startAnimating()

        case .determinate(let fraction):
            determinateProgressView.isHidden = false
            indeterminateProgressView.isHidden = true
            determinateProgressView.setProgress(fraction, animated: animated)
        }
    }

    // MARK: - Private

    private func configureViews() {
        backgroundColor = nil
        clipsToBounds = true
        layer.cornerRadius = Style.Size.buttonCornerRadius
        layer.cornerCurve = .continuous

        titleLabel.font = .preferredFont(forTextStyle: .subheadline, weight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true
    }

    private func center(in view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false

        centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        // Did get broken constraints and wrong layout when using leading/trailing and
        // top/bottom anchors.
        heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 1, constant: 2 * -superviewMargins).isActive = true
        widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 1, constant: 2 * -superviewMargins).isActive = true
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func doShow(_ show: Bool, animated: Bool) {
        isHidden = false

        if animated {
            // Don't set fixed alpha values before or after the animation as `beginFromCurrentState`
            // interpolates when multiple calls are made.
            UIView.animate(withDuration: animationDuration, delay: 0, options: [.beginFromCurrentState], animations: { [weak self] in
                self?.alpha = show ? 1 : 0
            }, completion: { [weak self] _ in
                if !show {
                    self?.removeFromSuperview()
                }
            })
        } else {
            if !show {
                removeFromSuperview()
            }

            alpha = show ? 1 : 0
        }
    }
}
