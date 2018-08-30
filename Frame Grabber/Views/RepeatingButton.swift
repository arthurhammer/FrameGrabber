import UIKit

class RepeatingButton: UIButton {

    var repeatInterval: TimeInterval = 0.15
    var repeatAction: (() -> ())?
    private var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

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
        repeatAction?()

        timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { [weak self] _ in
            self?.repeatAction?()
        }
    }

    @objc func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
}
