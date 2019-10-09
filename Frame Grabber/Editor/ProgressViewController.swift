import UIKit

class ProgressViewController: UIViewController {

    static func instantiateFromStoryboard() -> ProgressViewController {
        guard let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: name) as? ProgressViewController else { fatalError("Wrong controller id or type") }
        return controller
    }

    var didCancel: (() -> ())?

    var titleText: String?  {
        didSet { updateViews() }
    }

    var detailText: String? {
        didSet { updateViews() }
    }

    var progress: Float = 0  {
        didSet { updateViews() }
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
        didCancel?()
    }

    private func configureViews() {
        let accent = Style.Color.progressViewAccent
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true

        detailLabel.font = .monospacedDigitSystemFont(forTextStyle: .footnote)

        progressBar.trackTintColor = .systemGray
        progressBar.progressTintColor = accent
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true

        cancelButton.setTitleColor(accent, for: .normal)
        cancelButton.layer.cornerRadius = cancelButton.bounds.height/2
        cancelButton.clipsToBounds = true

        updateViews()
    }

    private func updateViews() {
        guard isViewLoaded else { return }

        titleLabel.text = titleText
        detailLabel.text = detailText
        progressBar.setProgress(progress, animated: progress != 1)
    }
}

extension ProgressViewController {
    static func frameExport(cancelHandler: @escaping () -> ()) -> ProgressViewController {
        let controller = instantiateFromStoryboard()
        controller.titleText = NSLocalizedString("frame-export.title", value: "Exporting Frames", comment: "Frame export activity title")
        controller.didCancel = cancelHandler
        controller.setProgress(count: 0, of: 0)
        return controller
    }

    func setProgress(count: Int, of: Int) {
        progress = Float(count) / Float(of)
        if progress >= 1 {
            detailText = NSLocalizedString("frame-export.subtitle.completed", value: "Done", comment: "Frame export activity subtitle when activity is completed.")
        } else {
            let format = NSLocalizedString("frame-export.subtitle.progress", value: "%@ of %@", comment: "Frame export activitiy subtitle when activity is not completed, i.e. number of completed of total frames.")
            detailText = String.localizedStringWithFormat(format, count as NSNumber, of as NSNumber)
        }
    }
}
