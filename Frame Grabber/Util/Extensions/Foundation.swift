import Foundation

extension NSObject {
    static var className: String {
        return String(describing: self)
    }
}

extension Sequence where Element == IndexPath {
    /// An `IndexSet` from a sequence of `IndexPath`s ignoring sections.
    var indexSet: IndexSet {
        return IndexSet(map { $0.item })
    }
}
