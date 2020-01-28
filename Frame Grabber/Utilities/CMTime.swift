import CoreMedia

extension CMTime {
    init(seconds: Double, preferredTimeScale: CMTimeScale = CMTimeScale(NSEC_PER_SEC)) {
        self.init(seconds: seconds, preferredTimescale: preferredTimeScale)
    }
}

extension CMTime {
    var isValidVideoTime: Bool {
        isValid && isNumeric && !isNegativeInfinity && !isPositiveInfinity && !isIndefinite
    }

    var validOrZero: CMTime {
        isValidVideoTime ? self : .zero
    }
}
