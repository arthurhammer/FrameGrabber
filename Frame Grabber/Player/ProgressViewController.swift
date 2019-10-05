import UIKit

// For now only progress until I need sth else.
// - [ ] Easy presentation
// - [ ] dynamic type: labels (+ corner radius)
// - [ ] write down for later: add checkmark icon/done label to progress vc

class ProgressViewController: UIViewController {

    static func instantiateFromStoryboard() -> ProgressViewController {
        guard let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: name) as? ProgressViewController else { fatalError("Wrong controller id or type") }
        return controller
    }

    /// The progress object the controller configures its views with. When the cancel
    /// button is pressed, the progress is cancelled.
    var progress: Progress? {
        didSet { configureProgress() }
    }

    @IBOutlet var containerView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var cancelButton: UIButton!

    private var observers = [NSKeyValueObservation?]()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Needs to be set before `viewDidLoad`.
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {

            // `CGColor` doesn't auto-resolve dynamic colors.
            // TODO: still not working. neet do use perform as current?
            cancelButton.layer.borderColor = Style.Color.progressViewAccent.cgColor
        }
    }

    @IBAction func cancel() {
        progress?.cancel()
    }

    private func configureViews() {
        let accent = Style.Color.progressViewAccent
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true

        detailLabel.font = .monospacedDigitSystemFont(forTextStyle: .footnote)

        progressBar.trackTintColor = .systemGray
        progressBar.progressTintColor = accent
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true

        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = accent.cgColor
        cancelButton.setTitleColor(accent, for: .normal)
        cancelButton.layer.cornerRadius = cancelButton.bounds.height/2
        cancelButton.clipsToBounds = true

        configureProgress()
    }

    private func configureProgress() {
        observers = []

        guard isViewLoaded,
            let progress = progress else { return }

        progressBar.observedProgress = progress

        observeProgress(for: \.localizedDescription) { [weak self] in
            self?.titleLabel.text = $0.localizedDescription
        }

        observeProgress(for: \.localizedAdditionalDescription) { [weak self] in
            self?.detailLabel.text = $0.localizedAdditionalDescription
        }
    }

    private func observeProgress<Value>(for keyPath: KeyPath<Progress, Value>, update: @escaping (Progress) -> ()) {
        observers.append(progress?.observe(keyPath, options: .initial) { progress, _ in
            DispatchQueue.main.async {
                update(progress)
            }
        })
    }
}
