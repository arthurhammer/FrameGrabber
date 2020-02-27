import UIKit

/// (Currently not a reusable class, specific to the instance configured in storyboard.)
class VideoTypeFilterControl: UIControl {

    var selectedSegmentIndex: Int {
        get { _selectedSegmentIndex }
        set { setSelectedSegmentIndex(newValue, animated: false) }
    }

    private var segments: [UIButton] {
        segmentsStack.arrangedSubviews as! [UIButton]
    }

    private lazy var selectionView: UIView = {
        var view = UIView(frame: .zero)
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Style.Color.mainTint
        visualEffectView.contentView.insertSubview(view, at: 0)
        return view
    }()

    @IBOutlet private var segmentsStack: UIStackView!
    @IBOutlet private var visualEffectView: UIVisualEffectView!

    private var _selectedSegmentIndex: Int = -1
    private var selectionViewConstraints = [NSLayoutConstraint]()
    private lazy var selectionFeedback = UISelectionFeedbackGenerator()

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }

    func setSelectedSegmentIndex(_ index: Int, animated: Bool) {
        setSelectedSegmentIndex(index, interactively: false, animated: animated)
    }

    // MARK: - Private

    private func configureViews() {
        backgroundColor = nil
        clipsToBounds = true

        segments.forEach { button in
            button.addTarget(self, action: #selector(selectSegment), for: .touchUpInside)
        }

        setSelectedSegmentIndex(0, animated: false)
        updateCornerRadius()
    }

    private func updateCornerRadius() {
        layer.cornerRadius = bounds.height / 2
        selectionView.layer.cornerRadius = selectionView.bounds.height / 2
    }

    @objc private func selectSegment(_ sender: UIButton) {
        let index = segments.firstIndex(of: sender)!
        setSelectedSegmentIndex(index, interactively: true, animated: true)
    }

    private func setSelectedSegmentIndex(_ index: Int, interactively: Bool, animated: Bool) {
        let index = max(0, min(index, segments.count-1))

        let didChange = index != _selectedSegmentIndex
        _selectedSegmentIndex = index

        segments.forEach { button in
            button.setTitleColor(.secondaryLabel, for: .normal)
        }

        let selectedButton = segments[index]
        selectedButton.setTitleColor(.white, for: .normal)

        NSLayoutConstraint.deactivate(selectionViewConstraints)
        selectionViewConstraints = constraints(for: selectionView, pinningTo: selectedButton)
        NSLayoutConstraint.activate(selectionViewConstraints)

        if animated {
            segmentsStack.isUserInteractionEnabled = false

            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
                self.selectionView.superview?.layoutIfNeeded()
            }, completion: { _ in
                self.segmentsStack.isUserInteractionEnabled = true
            })
        } else {
            selectionView.superview?.layoutIfNeeded()
        }

        if didChange, interactively {
            selectionFeedback.selectionChanged()
            sendActions(for: .valueChanged)
        }
    }

    private func constraints(for view: UIView, pinningTo other: UIView) -> [NSLayoutConstraint] {
        [view.leadingAnchor.constraint(equalTo: other.leadingAnchor),
         view.trailingAnchor.constraint(equalTo: other.trailingAnchor),
         view.topAnchor.constraint(equalTo: other.topAnchor),
         view.bottomAnchor.constraint(equalTo: other.bottomAnchor)]
    }
}
