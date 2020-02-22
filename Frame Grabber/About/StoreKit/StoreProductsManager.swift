import Foundation
import StoreKit

/// Fetches the available in-app purchases configured in App Store Connect.
class StoreProductsManager: NSObject {

    private(set) var fetchedProducts = [SKProduct]()
    private(set) var invalidProductIdentifiers = [String]()

    /// Is called on the main queue.
    var requestDidFail: ((SKRequest, Error) -> ())?
    /// Is called on the main queue.
    var requestDidSucceed: ((SKRequest, SKProductsResponse) -> ())?

    var isFetchingProducts: Bool {
        productRequest != nil
    }

    private var productRequest: SKProductsRequest?

    deinit {
        cancelFetchingProducts()
    }

    /// If a request is already in progress, it is cancelled.
    func fetchProducts(with identifiers: [String]) {
        productRequest?.cancel()
        productRequest = SKProductsRequest(productIdentifiers: Set(identifiers))
        productRequest?.delegate = self
        productRequest?.start()
    }

    func cancelFetchingProducts() {
        productRequest?.cancel()
    }
}

// MARK: - SKProductsRequestDelegate

extension StoreProductsManager: SKProductsRequestDelegate {

    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.productRequest = nil
            self?.requestDidFail?(request, error)
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async { [weak self] in
            self?.productRequest = nil
            self?.fetchedProducts = response.products
            self?.invalidProductIdentifiers = response.invalidProductIdentifiers
            self?.requestDidSucceed?(request, response)
        }
    }
}
