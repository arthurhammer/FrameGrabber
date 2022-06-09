import Foundation

extension Bundle {

    public var name: String {
        info(for: "CFBundleDisplayName") ?? info(for: "CFBundleName") ?? ""
    }

    public var version: String {
        info(for: "CFBundleShortVersionString") ?? ""
    }

    public var build: String {
        info(for: "CFBundleVersion") ?? ""
    }

    /// Name, version and build.
    public var longFormattedVersion: String {
        "\(name) \(version) (\(build))"
    }

    /// Version and build.
    public var shortFormattedVersion: String {
        "\(version) (\(build))"
    }

    private func info<T>(for key: String) -> T? {
        (localizedInfoDictionary?[key] as? T)
            ?? (infoDictionary?[key] as? T)
    }
}
