public enum FrameIndexError: Error {
    case cancelled
    case invalidVideo
    case frameLimitReached
    case readingFailed(_ underlying: Error?)
}
