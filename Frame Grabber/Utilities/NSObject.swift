import Foundation

extension NSObject {
    static var name: String {
        String(describing: self)
    }
}
