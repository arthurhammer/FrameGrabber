import Foundation

/// Allow optional errors in `Result`.
extension Optional: Error where Wrapped: Error {}

extension Error {
    public var isCocoaCancelledError: Bool {
        (self as? CocoaError) == CocoaError(.userCancelled)
    }
}

extension Result {
    
    public var value: Success? {
        try? get()
    }
    
    public var error: Error? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}
