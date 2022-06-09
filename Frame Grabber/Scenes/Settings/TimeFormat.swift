enum TimeFormat: Int {
    case minutesSecondsMilliseconds
    case minutesSecondsFrameNumber
}

extension TimeFormat: CaseIterable, Hashable, Codable {}

extension TimeFormat {
    
    var displayString: String {
        switch self {
        case .minutesSecondsMilliseconds: return Localized.exportMillisecondsFormatTitle
        case .minutesSecondsFrameNumber: return Localized.exportFrameNumberFormatTitle
        }
    }
    
    var formatDisplayString: String {
        switch self {
        case .minutesSecondsMilliseconds: return Localized.exportMillisecondsFormat
        case .minutesSecondsFrameNumber: return Localized.exportFrameNumberFormat
        }
    }
}
