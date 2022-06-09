extension String {

    public var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var nilIfEmpty: String? {
        let trimmed = self.trimmed
        return (trimmed != "") ? trimmed : nil
    }
}
