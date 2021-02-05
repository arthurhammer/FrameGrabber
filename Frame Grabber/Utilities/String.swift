extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var nilIfEmpty: String? {
        let trimmed = self.trimmed
        return (trimmed != "") ? trimmed : nil
    }
}
