import StoreKit

extension SKPaymentTransaction {
    var isFinished: Bool {
        [.purchased, .restored, .failed].contains(transactionState)
    }
}

extension Error {
    public var isStoreKitCancelledError: Bool {
        let nserror = self as NSError

        return (nserror.domain, nserror.code) == (CocoaError.errorDomain, CocoaError.Code.userCancelled.rawValue)
            || (nserror.domain, nserror.code) == (SKError.errorDomain, SKError.Code.paymentCancelled.rawValue)
    }
}

extension SKPaymentTransactionState: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case .deferred: return "SKPaymentTransactionState.deferred"
        case .failed: return "SKPaymentTransactionState.failed"
        case .purchased: return "SKPaymentTransactionState.purchased"
        case .purchasing: return "SKPaymentTransactionState.purchasing"
        case .restored: return "SKPaymentTransactionState.restored"
        @unknown default: return "Unknown SKPaymentTransactionState"
        }
    }
}
