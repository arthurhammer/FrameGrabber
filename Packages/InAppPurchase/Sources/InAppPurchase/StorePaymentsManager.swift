import StoreKit

/// The store where purchased and restored products are stored, typically a persistent one.
public protocol PurchasedProductsStore {
    var purchasedProductIdentifiers: [String] { get set }
}

/// Initiates in-app purchase payments, handles restorations and transaction update
/// notifications.
///
/// The manager saves successful purchases to a store you provide.
///
/// The manager does not support receipt validation or refunds. As long as they are present in the
/// store, refunded purchases will continue to be reported as purchased.
public class StorePaymentsManager: NSObject {

    public static let shared = StorePaymentsManager()

    public var purchasedProductsStore: PurchasedProductsStore?

    public var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }

    public var simulatesAskToBuyInSandbox = false

    /// Is called on the main queue. Note: Cancellation reports as `.failed`.
    public var transactionDidUpdate: ((SKPaymentTransaction) -> ())?

    /// Is called on the main queue. Note: Cancellation reports as error.
    public var restoreDidFail: ((Error) -> ())?

    /// Is called on the main queue.
    public var restoreDidComplete: (() -> ())?

    /// Products that have been previously purchased.
    ///
    /// When a product is successfully purchased or restored, the manager adds  identifier to this
    /// list and saves it to `purchasedProductsStore`.
    private(set) public var persistedPurchasedProductIdentifiers: [String] {
        get { purchasedProductsStore?.purchasedProductIdentifiers ?? [] }
        set { purchasedProductsStore?.purchasedProductIdentifiers = Array(Set(newValue)) }
    }

    /// Transactions that were purchased during the lifecycle of the current manager
    /// instance. Previously purchased products are either recorded in
    /// `persistedPurchasedProductIdentifiers` or need to be restored via `restore`.
    private(set) public var purchased = [SKPaymentTransaction]() {
        didSet { purchased = Array(Set(purchased)) }
    }

    /// Transactions that were restored during the lifecycle of the current manager
    /// instance.
    private(set) public var restored = [SKPaymentTransaction]() {
        didSet { restored = Array(Set(restored)) }
    }

    private(set) public var isRestoring = false

    private let paymentQueue: SKPaymentQueue

    private init(paymentQueue: SKPaymentQueue = .default()) {
        self.paymentQueue = paymentQueue
        super.init()
    }

    public func startObservingPayments() {
        paymentQueue.add(self)
    }

    public func stopObservingPayments() {
        paymentQueue.remove(self)
    }

    /// It is not guaranteed that `finishTransaction` is called for all transactions in
    /// all cases (such as during a crash). This method can be used to batch complete
    /// transactions in the payment queue that have finished states.
    public func flushFinishedTransactions() {
        paymentQueue.transactions
            .filter { $0.isFinished }
            .forEach(paymentQueue.finishTransaction)
    }

    // MARK: Purchasing

    /// True if the product id is in `persistedPurchasedProductIdentifiers`, otherwise false.
    ///
    /// If false, it does not necessarily mean that the product has not been purchased.
    /// It might have been purchased but not yet restored, a purchase might be pending or
    /// it might not have been purchased at all.
    public func hasPurchasedProduct(withId identifier: String) -> Bool {
        persistedPurchasedProductIdentifiers.contains(identifier)
    }

    public func hasPendingUnfinishedTransactions(withId identifier: String) -> Bool {
        !paymentQueue.transactions
            .filter { $0.payment.productIdentifier == identifier }
            .filter { !$0.isFinished }
            .isEmpty
    }

    /// Adds a payment request to the payment queue.
    ///
    /// Has no effect and no callabacks are called in the following cases:
    ///   - the user is not authorized to make payments
    ///   - the product is known to have been purchased before
    ///   - there are pending unfinished transactions for this product
    public func purchase(_ product: SKProduct) {
        guard canMakePayments,
            !hasPurchasedProduct(withId: product.productIdentifier),
            !hasPendingUnfinishedTransactions(withId: product.productIdentifier) else { return }

        let payment = SKMutablePayment(product: product)
        payment.simulatesAskToBuyInSandbox = simulatesAskToBuyInSandbox
        paymentQueue.add(payment)
    }

    /// Restores all previously completed purchases.
    ///
    /// When the user is not authorized to make payments, this has no effect and no
    /// callbacks are called.
    public func restore() {
        guard canMakePayments,
            !isRestoring else { return }
        isRestoring = true
        paymentQueue.restoreCompletedTransactions()
    }

    private func persistPurchase(for transaction: SKPaymentTransaction) {
        let id = transaction.payment.productIdentifier
        persistedPurchasedProductIdentifiers = persistedPurchasedProductIdentifiers + [id]
    }
}

// MARK: - SKPaymentTransactionObserver

extension StorePaymentsManager: SKPaymentTransactionObserver {

    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        DispatchQueue.main.async { [weak self] in
            transactions.forEach {
                self?.handleTransactionUpdate(for: $0)
            }
        }
    }

    private func handleTransactionUpdate(for transaction: SKPaymentTransaction) {
        switch transaction.transactionState {

        case .purchasing, .deferred, .failed:
            break

        case .purchased:
            persistPurchase(for: transaction)
            purchased = purchased + [transaction]

        case .restored:
            persistPurchase(for: transaction)
            restored = restored + [transaction]

        @unknown default:
            fatalError("Unknown transaction state.")
        }

        if transaction.isFinished {
            paymentQueue.finishTransaction(transaction)
        }

        transactionDidUpdate?(transaction)
    }

    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isRestoring = false
            self?.restoreDidFail?(error)
        }
    }

    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        DispatchQueue.main.async { [weak self] in
            self?.isRestoring = false
            self?.restoreDidComplete?()
        }
    }
}
