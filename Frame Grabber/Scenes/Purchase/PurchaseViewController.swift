import Combine
import Utility
import UIKit

final class PurchaseViewController: UIViewController {
    
    let viewModel = PurchaseViewModel()  // (Create & inject externally)
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var scrollViewSeparator: UIView!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var iconView: UIImageView!
    @IBOutlet private var purchaseButtonsView: PurchaseButtonsView!
    @IBOutlet private var confettiView: ConfettiView!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        configureViews()
        viewModel.onViewDidLoad()
    }
    
    private var didAppear = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        didAppear = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        DispatchQueue.main.async { [weak self] in
            self?.updateSeparator()
            self?.updateSheetPresentationSize()
        }
    }
    
    private func updateSheetPresentationSize() {
        guard let contentView = scrollView.subviews.first else { return }
        
        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let contentViewHeight = contentView.systemLayoutSizeFitting(targetSize).height
        let buttonsHeight = purchaseButtonsView.systemLayoutSizeFitting(targetSize).height
        let compressedHeight = contentViewHeight + buttonsHeight + 12 + view.safeAreaInsets.bottom  // Spacings from storyboard.
        let size = CGSize(width: targetSize.width, height: compressedHeight)
        
        if preferredContentSize != size {
            preferredContentSize = size
            if #available(iOS 16.0, *) {
                invalidateSheetDetents(animated: didAppear)
            }
        }
    }

    // MARK: - Actions

    @IBAction private func done() {
        dismiss(animated: true)
    }

    private func showConfetti() {
        confettiView.startConfetti(withDuration: 2)
    }

    @IBAction private func restore() {
        viewModel.onRestore()
    }

    @IBAction private func purchase() {
        viewModel.onPurchase()
    }

    // MARK: - Configuring
    
    private func setupBindings() {
        viewModel.$title
            .combineLatest(viewModel.$subtitle)
            .sink { [weak self] title, subtitle in
                self?.titleLabel.text = title
                self?.subtitleLabel.text = subtitle
            }
            .store(in: &cancellables)
        
        viewModel.$purchaseButtonConfiguration
            .combineLatest(viewModel.$restoreButtonConfiguration)
            .sink { [weak self] purchaseConfig, restoreConfig in
                self?.purchaseButtonsView.setup(withPurchaseButtonConfiguration: purchaseConfig, restoreButtonConfiguration: restoreConfig)
            }
            .store(in: &cancellables)
        
        viewModel.errorPublisher
            .sink { [weak self] alert in
                self?.presentAlert(alert)
            }
            .store(in: &cancellables)
        
        viewModel.confettiPublisher
            .sink { [weak self] in
                self?.showConfetti()
            }
            .store(in: &cancellables)
    }

    private func configureViews() {
        scrollView.delegate = self
                
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurView, at: 0)
        view.backgroundColor = .clear

        let appIconCornerRadius: CGFloat = 18
        let imageContainer = iconView.superview
        iconView.layer.cornerRadius = appIconCornerRadius
        iconView.layer.cornerCurve = .continuous
        imageContainer?.layer.cornerRadius = appIconCornerRadius
        imageContainer?.layer.cornerCurve = .continuous
        imageContainer?.layer.borderWidth = 1
        imageContainer?.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        imageContainer?.configureWithDefaultShadow()
        
        titleLabel.font = .preferredFont(forTextStyle: .title2, weight: .semibold)
        
        updateSeparator()
    }

    private func updateSeparator() {
        guard let contentView = scrollView.subviews.first else { return  }

        let contentRect = scrollView.convert(contentView.frame, to: view)
        scrollViewSeparator.isHidden = !contentRect.intersects(purchaseButtonsView.frame)
    }
}

// MARK: - UIScrollViewDelegate

extension PurchaseViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateSeparator()
    }
}

private extension UIView {
    
    func fade(in fadeIn: Bool) {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .beginFromCurrentState,
            animations: {
                self.alpha = fadeIn ? 1 : 0
            },
            completion: nil
        )
    }
}
