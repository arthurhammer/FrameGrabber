import Combine
import Foundation
import InAppPurchase
import StoreKit
import UIKit

final class PurchaseViewModel {
    
    struct ButtonConfiguration: Hashable {
        let title: String?
        let subtitle: String?
        let isLoading: Bool
        let isUserInteractionEnabled: Bool
    }

    @Published private(set) var purchaseButtonConfiguration = ButtonConfiguration(
        title: Localized.Purchase.purchase,
        subtitle: nil,
        isLoading: false,
        isUserInteractionEnabled: false
    )
    
    @Published private(set) var restoreButtonConfiguration = ButtonConfiguration(
        title: Localized.Purchase.restore,
        subtitle: nil,
        isLoading: false,
        isUserInteractionEnabled: false
    )
    
    @Published private(set) var isPurchasedViewVisible = false
    
    private(set) lazy var confettiPublisher = PassthroughSubject<Void, Never>()
    // (Shouldn't publish a view controller but is kept for simplicity for now.)
    private(set) lazy var errorPublisher = PassthroughSubject<UIAlertController, Never>()
    
    private var hasPurchased: Bool {
        paymentsManager.hasPurchasedProduct(withId: productId)
    }

    private var product: SKProduct? {
        productsManager.fetchedProducts.first { $0.productIdentifier == productId }
    }
    
    private let productId = About.inAppPurchaseIdentifier
    private let productsManager: StoreProductsManager
    private let paymentsManager: StorePaymentsManager

    init(productsManager: StoreProductsManager = .init(), paymentsManager: StorePaymentsManager = .shared) {
        self.productsManager = productsManager
        self.paymentsManager = paymentsManager
        
        updateViewState()
    }
    
    // MARK: Actions
    
    func onViewDidLoad() {
        configureStoreManagers()
        fetchProductsIfNeeded()
    }
    
    func onRestore() {
        defer { updateViewState() }

        guard paymentsManager.canMakePayments else {
            errorPublisher.send(.restoreNotAllowed())
            return
        }

        paymentsManager.restore()
    }

    func onPurchase() {
        defer { updateViewState() }

        guard !hasPurchased,
              !paymentsManager.hasPendingUnfinishedTransactions(withId: productId)
        else {
            return
        }

        guard paymentsManager.canMakePayments else {
            errorPublisher.send(.purchaseNotAllowed())
            return
        }

        guard let product else {
            errorPublisher.send(.productNotFetched())
            fetchProductsIfNeeded()  // Retry.
            return
        }

        paymentsManager.purchase(product)
    }
    
    // MARK: View State

    private func updateViewState() {
        let isFetchingProducts = productsManager.isFetchingProducts
        let isPurchasing = paymentsManager.hasPendingUnfinishedTransactions(withId: productId)
        let isRestoring = paymentsManager.isRestoring
        
        let isPurchaseButtonLoading = isFetchingProducts || isPurchasing
        let isButtonInteractionEnabled = !isPurchaseButtonLoading && !isRestoring
        
        self.purchaseButtonConfiguration = .init(
            title: isPurchaseButtonLoading ? nil : Localized.Purchase.purchase,
            subtitle: isPurchaseButtonLoading ? nil : product.flatMap(formattedPrice),
            isLoading: isPurchaseButtonLoading,
            isUserInteractionEnabled: isButtonInteractionEnabled
        )
        
        self.restoreButtonConfiguration = .init(
            title: isRestoring ? nil : Localized.Purchase.restore,
            subtitle: nil,
            isLoading: isRestoring,
            isUserInteractionEnabled: isButtonInteractionEnabled
        )
        
        self.isPurchasedViewVisible = hasPurchased
    }
    
    private func formattedPrice(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let fallback = "\(product.price)"
        return formatter.string(from: product.price as NSNumber) ?? fallback
    }
    
    // MARK: Payment
    
    private func configureStoreManagers() {
        productsManager.requestDidFail = { [weak self] _, _ in
            self?.updateViewState()
        }

        productsManager.requestDidSucceed = { [weak self] _, _ in
            self?.updateViewState()
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
        defer { updateViewState() }

        guard transaction.error?.isStoreKitCancelledError != true else {
            return
        }

        if transaction.transactionState == .failed {
            errorPublisher.send(.purchaseFailed(error: transaction.error))
            return
        }

        if [.purchased, .restored].contains(transaction.transactionState) {
            confettiPublisher.send()
        }
    }

    private func handleRestoreDidFail(with error: Error) {
        defer { updateViewState() }
        
        if !error.isStoreKitCancelledError {
            errorPublisher.send(.restoreFailed(error: error))
        }
    }

    private func handleRestoreDidComplete() {
        defer { updateViewState() }
        
        if paymentsManager.restored.isEmpty {
            errorPublisher.send(.nothingToRestore())
        }
    }
    
    private func fetchProductsIfNeeded() {
        defer { updateViewState() }

        guard !hasPurchased,
              !productsManager.isFetchingProducts
        else {
            return
        }

        productsManager.fetchProducts(with: [productId])
    }
}
