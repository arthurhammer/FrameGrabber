import InAppPurchase
import StoreKit
import UIKit

class PurchaseViewController: UIViewController {

    private var hasPurchased: Bool {
        paymentsManager.hasPurchasedProduct(withId: inAppPurchaseId)
    }

    private var fetchedProduct: SKProduct? {
        productsManager.fetchedProducts.first { $0.productIdentifier == inAppPurchaseId }
    }

    private let inAppPurchaseId = About.inAppPurchaseIdentifier
    private let productsManager = StoreProductsManager()
    private let paymentsManager = StorePaymentsManager.shared

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var scrollViewSeparator: UIView!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var iconView: UIImageView!
    @IBOutlet private var supporterBadgeView: UIView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var purchaseButtonsView: PurchaseButtonsView!
    @IBOutlet private var purchasingView: UIView!
    @IBOutlet private var purchasedView: UIView!
    @IBOutlet private var confettiView: ConfettiView!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
                
        configureStoreManagers()
        configureViews()
        fetchProductsIfNeeded()
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

    private func fetchProductsIfNeeded() {
        defer { updateViews() }

        guard !hasPurchased,
            !productsManager.isFetchingProducts else { return }

        productsManager.fetchProducts(with: [inAppPurchaseId])
    }

    private func showConfettiIfNeeded() {
        guard hasPurchased else { return }
        confettiView.startConfetti(withDuration: 2)
    }

    @IBAction private func restore() {
        defer { updateViews() }

        guard paymentsManager.canMakePayments else {
            presentAlert(.restoreNotAllowed())
            return
        }

        paymentsManager.restore()
    }

    @IBAction private func purchase() {
        defer { updateViews() }

        guard !hasPurchased,
            !paymentsManager.hasPendingUnfinishedTransactions(withId: inAppPurchaseId) else {
            return
        }

        guard paymentsManager.canMakePayments else {
            presentAlert(.purchaseNotAllowed())
            return
        }

        guard let product = fetchedProduct else {
            presentAlert(.productNotFetched())
            fetchProductsIfNeeded()  // Retry.
            return
        }

        paymentsManager.purchase(product)
    }

    // MARK: - Configuring

    private func configureViews() {
        scrollView.delegate = self
        confettiView.confettiImage = UIImage(named: "confetti")
        titleLabel.font = .preferredFont(forTextStyle: .title1, size: 36, weight: .semibold)
                
        supporterBadgeView.layer.cornerRadius = 8
        supporterBadgeView.layer.cornerCurve = .continuous
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurView, at: 0)
        view.backgroundColor = .clear

        let appIconCornerRadius: CGFloat = 20
        let imageContainer = iconView.superview
        iconView.layer.cornerRadius = appIconCornerRadius
        iconView.layer.cornerCurve = .continuous
        imageContainer?.layer.cornerRadius = appIconCornerRadius
        imageContainer?.layer.cornerCurve = .continuous
        imageContainer?.layer.borderWidth = 1
        imageContainer?.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        imageContainer?.applyDefaultShadow()
        
        purchasingView.alpha = 0
        purchasingView.isHidden = false
        purchasedView.isHidden = false
        purchasedView.alpha = 0
        
        updateViews()
        updateSeparator()
    }

    private func updateViews() {
        let state = self.state()
        let price = fetchedProduct.flatMap(formattedPrice)
        
        purchaseButtonsView.configure(with: state, price: price)
        purchasingView.fade(in: [.fetchingProducts, .purchasing].contains(state))

        purchasedView.fade(in: state == .purchased)
    }

    private func updateSeparator() {
        guard let contentView = scrollView.subviews.first else { return  }

        let contentRect = scrollView.convert(contentView.frame, to: view)
        scrollViewSeparator.isHidden = !contentRect.intersects(purchaseButtonsView.frame)
    }

    // MARK: Handling Transactions

    private func configureStoreManagers() {
        productsManager.requestDidFail = { [weak self] _, _ in
            self?.updateViews()
        }

        productsManager.requestDidSucceed = { [weak self] _, _ in
            self?.updateViews()
        }

        paymentsManager.restoreDidFail = { [weak self] error in
            self?.handleRestoreDidFail(with: error)
        }

        paymentsManager.restoreDidComplete = { [weak self] in
            self?.handleRestoreDidComplete()
        }

        paymentsManager.transactionDidUpdate = { [weak self] transaction in
            self?.handleTransactionDidUpdate(transaction)
        }
    }

    private func handleTransactionDidUpdate(_ transaction: SKPaymentTransaction) {
        defer { updateViews() }

        if transaction.error?.isStoreKitCancelledError == true {
            return
        }

        if transaction.transactionState == .failed {
            presentAlert(.purchaseFailed(error: transaction.error))
            return
        }

        if [.purchased, .restored].contains(transaction.transactionState) {
            showConfettiIfNeeded()
        }
    }

    private func handleRestoreDidFail(with error: Error) {
        if !error.isStoreKitCancelledError {
            presentAlert(.restoreFailed(error: error))
        }

        updateViews()
    }

    private func handleRestoreDidComplete() {
        if paymentsManager.restored.isEmpty {
            presentAlert(.nothingToRestore())
        }

        updateViews()
    }

    private func formattedPrice(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let fallback = "\(product.price)"
        return formatter.string(from: product.price as NSNumber) ?? fallback
    }

    // MARK: Determining Current State

    enum State {
        case fetchingProducts
        case productsNotFetched  // Not yet fetched or failed to fetch.
        case readyToPurchase
        case purchasing
        case restoring
        case purchased
    }

    private func state() -> State {
        if hasPurchased {
            return .purchased
        }

        if productsManager.isFetchingProducts {
            return .fetchingProducts
        }

        if fetchedProduct == nil {
            return .productsNotFetched
        }

        if paymentsManager.isRestoring {
            return .restoring
        }

        if paymentsManager.hasPendingUnfinishedTransactions(withId: inAppPurchaseId) {
            return .purchasing
        }

        return .readyToPurchase
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
            }, completion: nil)
    }
}
