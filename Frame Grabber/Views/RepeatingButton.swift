import UIKit

/// Sends the `touchDown` event in regular intervals while pressed.
class RepeatingButton: UIButton {

    var repeatInterval: TimeInterval = 0.2

    private var timer: Timer?
    private let notificationCenter = NotificationCenter.default

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
        
        observe(UIApplication.willResignActiveNotification, selector: #selector(cancelTimer))
        observe(UIApplication.didEnterBackgroundNotification, selector: #selector(cancelTimer))
    }

    @objc func scheduleTimer() {
        cancelTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) {
            [weak self] _ in
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
    
    private func observe(_ notification: NSNotification.Name, selector: Selector) {
        notificationCenter.addObserver(self, selector: selector, name: notification, object: nil)
    }
}
