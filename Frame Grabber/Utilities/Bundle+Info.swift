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

    var formattedVersion: String {
        let format = NSLocalizedString("bundle.formattedVersion", value: "%@ %@ (%@)", comment: "<App Name> <Version Number> (<Build Number>)")
        return String.localizedStringWithFormat(format, name, version, build)
    }

    private func info<T>(for key: String) -> T? {
        (localizedInfoDictionary?[key] as? T)
            ?? (infoDictionary?[key] as? T)
    }
}
