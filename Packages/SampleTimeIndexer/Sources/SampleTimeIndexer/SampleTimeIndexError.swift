public enum SampleTimeIndexError: Error {
    case cancelled
    case invalidVideo
    case sampleLimitReached
    case readingFailed(_ underlying: Error?)
}
