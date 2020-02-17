import UIKit

class SwipingSegmentedControl: UISegmentedControl {

    private(set) lazy var swipeLeftGestureRecognizer: UISwipeGestureRecognizer = {
        let gesture =  UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        gesture.direction = .left
        return gesture
    }()

    private(set) lazy var swipeRightGestureRecognizer: UISwipeGestureRecognizer = {
        let gesture =  UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        gesture.direction = .right
        return gesture
    }()

    private lazy var selectionFeedback: UISelectionFeedbackGenerator = .init()
    private lazy var impactFeedback: UIImpactFeedbackGenerator = .init(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }

    /// When the selected segment index changes by swiping, the control sends a `valueChanged` event.
    func installGestures(in view: UIView) {
        view.addGestureRecognizer(swipeLeftGestureRecognizer)
        view.addGestureRecognizer(swipeRightGestureRecognizer)
    }

    private func configureViews() {
        selectedSegmentTintColor = Style.Color.mainTint
        setTitleTextAttributes([.foregroundColor: UIColor.systemBackground], for: .selected)
        setTitleTextAttributes([.foregroundColor: UIColor.systemBackground], for: .highlighted)

        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }

    @objc private func valueChanged() {
        selectionFeedback.selectionChanged()
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard gesture.state == .ended else { return }

        let oldValue = selectedSegmentIndex
        let increment = (gesture.direction == .left) ? 1 : -1
        let newValue = max(0, min(oldValue + increment, numberOfSegments-1))

        if newValue != oldValue {
            selectedSegmentIndex = newValue
            sendActions(for: .valueChanged)
        } else {
            impactFeedback.impactOccurred()
        }
    }
}
