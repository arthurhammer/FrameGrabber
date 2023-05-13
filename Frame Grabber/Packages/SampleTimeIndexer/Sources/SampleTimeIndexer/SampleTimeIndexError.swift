import AVFoundation

public enum SampleTimeIndexError: Error {
    case invalidVideo
    case cancelled
    case interrupted
    case sampleLimitReached
    case readingFailed(_ underlying: Error?)
}

extension SampleTimeIndexError {
    
    /// The appropriate index error from the underlying error: `.interrupted` if the error is
    /// `AVError.operationInterrupted`, otherwise `.readingFailed`.
    init(underlying: Error?) {
        let nsError = underlying as NSError?
        
        if nsError?.domain == AVError.errorDomain,
           nsError?.code == AVError.operationInterrupted.rawValue {
            self = .interrupted
        } else {
            self = .readingFailed(underlying)
        }
    }
    
    var isInterrupted: Bool {
        switch self {
        case .interrupted: return true
        default: return false
        }
    }
}
