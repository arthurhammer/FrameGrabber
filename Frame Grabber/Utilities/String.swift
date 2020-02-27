extension String {
    /// Nil if the string is only whitespace, otherwise the string trimmed from whitespace.
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed != "") ? trimmed : nil
    }
}
