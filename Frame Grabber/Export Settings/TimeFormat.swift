enum TimeFormat: Int {
    case minutesSecondsMilliseconds
    case minutesSecondsFrameNumber
}

extension TimeFormat: CaseIterable, Hashable, Codable {}
