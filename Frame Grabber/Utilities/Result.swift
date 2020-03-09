import Foundation

/// Allow optional errors in `Result`.
extension Optional: Error where Wrapped: Error {}

extension Error {
    var isCocoaCancelledError: Bool {
        (self as? CocoaError) == CocoaError(.userCancelled)
    }
}

extension Result {
    var value: Success? {
        if case let .success(value) = self {
            return value
        }
        return nil
    }
}
