import CoreMedia

extension CMTime {
    var isValidVideoTime: Bool {
        isValid && isNumeric && !isNegativeInfinity && !isPositiveInfinity && !isIndefinite
    }

    var validOrZero: CMTime {
        isValidVideoTime ? self : .zero
    }
}
