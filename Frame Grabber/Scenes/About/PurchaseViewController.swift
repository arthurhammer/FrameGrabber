import Combine
import InAppPurchase
import StoreKit
import Utility
import UIKit

class PurchaseViewController: UIViewController {
    
    let viewModel = PurchaseViewModel()  // (Create & inject externally)
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet private var scrollViewSeparator: UIView!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var iconView: UIImageView!
    @IBOutlet var purchaseButtonsView: PurchaseButtonsView!
    @IBOutlet private var purchasedView: UIView!
    @IBOutlet private var confettiView: ConfettiView!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        configureViews()
        viewModel.onViewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        DispatchQueue.main.async {
            self.updateSeparator()
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
        viewModel.$purchaseButtonConfiguration
            .combineLatest(viewModel.$restoreButtonConfiguration)
            .sink { [weak self] result in
                self?.purchaseButtonsView.setup(withPurchaseButtonConfiguration: result.0, restoreButtonConfiguration: result.1)
            }
            .store(in: &cancellables)

        viewModel.$isPurchasedViewVisible
            .removeDuplicates()
            .sink { [weak self] isVisible in
                self?.purchasedView.fade(in: isVisible)
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
        
        purchasedView.isHidden = false
        purchasedView.alpha = 0
        
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
