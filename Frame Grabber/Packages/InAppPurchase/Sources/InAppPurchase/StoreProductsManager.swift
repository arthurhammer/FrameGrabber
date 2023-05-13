import StoreKit

/// Fetches the available in-app purchases configured in App Store Connect.
public class StoreProductsManager: NSObject {

    private(set) public var fetchedProducts = [SKProduct]()
    private(set) public var invalidProductIdentifiers = [String]()

    /// Is called on the main queue.
    public var requestDidFail: ((SKRequest, Error) -> ())?
    /// Is called on the main queue.
    public var requestDidSucceed: ((SKRequest, SKProductsResponse) -> ())?

    public var isFetchingProducts: Bool {
        productRequest != nil
    }

    private var productRequest: SKProductsRequest?

    deinit {
        cancelFetchingProducts()
    }

    /// If a request is already in progress, it is cancelled.
    public func fetchProducts(with identifiers: [String]) {
        productRequest?.cancel()
        productRequest = SKProductsRequest(productIdentifiers: Set(identifiers))
        productRequest?.delegate = self
        productRequest?.start()
    }

    public func cancelFetchingProducts() {
        productRequest?.cancel()
    }
}

// MARK: - SKProductsRequestDelegate

extension StoreProductsManager: SKProductsRequestDelegate {

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.productRequest = nil
            self?.requestDidFail?(request, error)
        }
    }

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async { [weak self] in
            self?.productRequest = nil
            self?.fetchedProducts = response.products
            self?.invalidProductIdentifiers = response.invalidProductIdentifiers
            self?.requestDidSucceed?(request, response)
        }
    }
}
