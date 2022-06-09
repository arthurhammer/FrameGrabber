import Foundation

extension NSObject {
    public static var className: String {
        String(describing: self)
    }
}
