import Foundation
import UIKit

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

    var appIcon: UIImage? {
        guard let icons: [String: Any] = info(for: "CFBundleIcons"),
              let primaryIcons = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcons["CFBundleIconFiles"] as? [String],
              let icon = iconFiles.last else { return nil }
        return UIImage(named: icon)
    }

    private func info<T>(for key: String) -> T? {
        (localizedInfoDictionary?[key] as? T)
            ?? (infoDictionary?[key] as? T)
    }
}
