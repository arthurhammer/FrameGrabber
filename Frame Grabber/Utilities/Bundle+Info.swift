import Foundation

extension Bundle {

    var name: String {
        return info(for: "CFBundleDisplayName") ?? info(for: "CFBundleName") ?? ""
    }

    var version: String {
        return info(for: "CFBundleShortVersionString") ?? ""
    }

    var build: String {
        return info(for: "CFBundleVersion") ?? ""
    }

    var formattedVersion: String {
        let format = NSLocalizedString("%@ %@ (%@)", comment: "")
        return String(format: format, arguments: [name, version, build])
    }

    private func info<T>(for key: String) -> T? {
        return Bundle.main.infoDictionary?[key] as? T
    }
}
