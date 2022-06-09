import UIKit

extension UIDevice {
    /// Device type, e.g. "iPhone7,2".
    public var type: String? {
        // From the world wide webs.
        var systemInfo = utsname()
        uname(&systemInfo)

        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
    }
}
