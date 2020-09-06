import UIKit

/// Sends the `touchDown` event in regular intervals while pressed.
class RepeatingButton: UIButton {

    var repeatInterval: TimeInterval = 0.15

    private var timer: Timer?

    override var isEnabled: Bool {
        didSet {
            if !isEnabled { cancelTimer() }
        }
    }

    override var isUserInteractionEnabled: Bool {
        didSet {
            if !isUserInteractionEnabled { cancelTimer() }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    deinit {
        cancelTimer()
    }
}

private extension RepeatingButton {

    func configureViews() {
        addTarget(self, action: #selector(scheduleTimer), for: .touchDown)
        addTarget(self, action: #selector(cancelTimer), for: [.touchUpInside, .touchUpOutside])
    }

    @objc func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] _ in
            self?.sendTouchDown()
        }
    }

    @objc func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }

    func sendTouchDown() {
        removeTarget(self, action: #selector(scheduleTimer), for: .touchDown)
        sendActions(for: .touchDown)
        addTarget(self, action: #selector(scheduleTimer), for: .touchDown)
    }
}
