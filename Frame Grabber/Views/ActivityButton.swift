import UIKit

/// A button that shows an activity indicator.
/// 
/// - Note: This class does not support setting titles via `setTitle(:for:)`.
class ActivityButton: UIButton {

    var isShowingActivity = false {
        didSet { updateViews() }
    }

    /// The title that is shown when the button is not showing the activity indicator.
    ///
    /// - Note: Always use this instead of `setTitle(:for:)`.
    var dormantTitle: String? {
        didSet { updateViews() }
    }

    private(set) lazy var activityIndicator = UIActivityIndicatorView(style: .medium)

    override func layoutSubviews() {
        super.layoutSubviews()
        activityIndicator.center = center
    }

    private func updateViews() {
        if isShowingActivity {
            addSubview(activityIndicator)
            activityIndicator.center = center
            activityIndicator.startAnimating()
            setTitle(nil, for: .normal)
            isEnabled = false
        } else {
            activityIndicator.removeFromSuperview()
            setTitle(dormantTitle, for: .normal)
            isEnabled = true
        }
    }
}
