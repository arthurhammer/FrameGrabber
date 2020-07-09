import InAppPurchase
import StoreKit
import UIKit

class IceCreamViewController: UIViewController {

    var hasPurchased: Bool {
        paymentsManager.hasPurchasedProduct(withId: inAppPurchaseId)
    }

    var fetchedProduct: SKProduct? {
        productsManager.fetchedProducts.first { $0.productIdentifier == inAppPurchaseId }
    }

    private let inAppPurchaseId = About.inAppPurchaseIdentifier
    private let productsManager = StoreProductsManager()
    private let paymentsManager = StorePaymentsManager.shared

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var confettiView: ConfettiView!
    @IBOutlet private var purchaseButton: ActivityButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStoreManagers()
        configureViews()
        fetchProductsIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.styleNavigationBar()
            self?.showConfettiIfNeeded()

        }, completion: { [weak self] _ in
            self?.styleNavigationBar()
        })
    }

    // MARK: Actions

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

    // MARK: Configuring

    private func configureViews() {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1, size: 36, weight: .semibold)

        purchaseButton.tintColor = .white
        purchaseButton.backgroundColor = Style.Color.iceCream
        purchaseButton.layer.cornerRadius = Style.Size.buttonCornerRadius
        purchaseButton.layer.cornerCurve = .continuous
        purchaseButton.activityIndicator.color = .white

        confettiView.confettiImage = UIImage(named: "confetti")

        updateViews()
    }

    private func updateViews() {
        switch state() {

        case .fetchingProducts, .purchasing, .restoring:
            purchaseButton.isShowingActivity = true
            navigationItem.rightBarButtonItem?.isEnabled = false
            titleLabel.text = UserText.IAPNotPurchasedTitle
            messageLabel.text = UserText.IAPNotPurchasedMessage

        case .productsNotFetched, .readyToPurchase:
            purchaseButton.isShowingActivity = false
            navigationItem.rightBarButtonItem?.isEnabled = true

            if let product = fetchedProduct {
                let price = formattedPrice(for: product)
                purchaseButton.dormantTitle = String.localizedStringWithFormat(UserText.IAPActionWithPriceFormat, price)
            } else {
                purchaseButton.dormantTitle = UserText.IAPActionWithoutPrice
            }

            titleLabel.text = UserText.IAPNotPurchasedTitle
            messageLabel.text = UserText.IAPNotPurchasedMessage

        case .purchased:
            purchaseButton.dormantTitle = nil
            purchaseButton.isHidden = true
            navigationItem.rightBarButtonItem = nil
            titleLabel.text = UserText.IAPPurchasedTitle
            messageLabel.text = UserText.IAPPurchasedMessage
        }
    }

    private func styleNavigationBar() {
        let bar = navigationController?.navigationBar
        bar?.tintColor = .white
        bar?.shadowImage = UIImage()
        bar?.setBackgroundImage(UIImage(), for: .default)
        bar?.backgroundColor = nil
    }

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

    // MARK: Handling Transactions

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

    private enum State {
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
