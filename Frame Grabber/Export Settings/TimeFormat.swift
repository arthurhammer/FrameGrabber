enum TimeFormat: Int {
    case minutesSecondsMilliseconds
    case minutesSecondsFrameNumber
}

extension TimeFormat: CaseIterable, Hashable, Codable {}

extension TimeFormat {
    
    var displayString: String {
        switch self {
        case .minutesSecondsMilliseconds: return UserText.exportMillisecondsFormatTitle
        case .minutesSecondsFrameNumber: return UserText.exportFrameNumberFormatTitle
        }
    }
    
    var formatDisplayString: String {
        switch self {
        case .minutesSecondsMilliseconds: return UserText.exportMillisecondsFormat
        case .minutesSecondsFrameNumber: return UserText.exportFrameNumberFormat
        }
    }
}
