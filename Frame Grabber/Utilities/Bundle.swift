import Foundation

extension Bundle {

    var name: String {
        info(for: "CFBundleDisplayName") ?? info(for: "CFBundleName") ?? ""
    }

    var version: String {
        info(for: "CFBundleShortVersionString") ?? ""
    }

    var build: String {
        info(for: "CFBundleVersion") ?? ""
    }

    /// Name, version and build.
    var longFormattedVersion: String {
        "\(name) \(version) (\(build))"
    }

    /// Version and build.
    var shortFormattedVersion: String {
        "\(version) (\(build))"
    }

    private func info<T>(for key: String) -> T? {
        (localizedInfoDictionary?[key] as? T)
            ?? (infoDictionary?[key] as? T)
    }
}
