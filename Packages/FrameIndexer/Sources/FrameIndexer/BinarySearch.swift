// Binary search variants using partitioning.
//
// Follows ideas from:
//   Python bisect module:
//     https://docs.python.org/3/library/bisect.html
//   Swift evolution proposal for binary search:
//     https://github.com/apple/swift-evolution/blob/master/proposals/0074-binary-search.md

// MARK: - Comparable Elements

extension RandomAccessCollection where Element: Comparable {
    
    /// See `sortedFirstIndex(of:by)`.
    func sortedFirstIndex(of element: Element) -> Index? {
        sortedFirstIndex(of: element, by: <)
    }
    
    /// See `sortedLastIndex(ofElementLessThanOrEqualTo:by)`.
    func sortedLastIndex(ofElementLessThanOrEqualTo element: Element) -> Index? {
        sortedLastIndex(ofElementLessThanOrEqualTo: element, by: <)
    }
}

// MARK: - Non-Comparable Elements

extension RandomAccessCollection {
    
    /// The first index of `target`, according to the comparison predicate. Returns `nil` if the
    /// element does not exist.
    ///
    /// - Precondition: The collection is sorted according to `areInCreasingOrder` and
    ///   `areInCreasingOrder` establishes a **total order** on the elements.
    ///
    /// - Complexity: O(log(n)) where n is the size of the collection.
    func sortedFirstIndex(
        of target: Element,
        by areInCreasingOrder: (Element, Element) -> Bool
    ) -> Index? {
        
        let index = sortedLeftInsertionIndex(for: target, by: areInCreasingOrder)
        
        guard index != endIndex,
              !areInCreasingOrder(target, self[index]) else { return nil }
        
        return index
    }
    
    /// The index of the last element equal to or less than `target`, according to the comparison
    /// predicate. Returns `nil` if no such element exists.
    ///
    /// - Precondition: The collection is sorted according to `areInCreasingOrder` and
    ///   `areInCreasingOrder` establishes a **total order** on the elements.
    ///
    /// - Complexity: O(log(n)) where n is the size of the collection.
    func sortedLastIndex(
        ofElementLessThanOrEqualTo target: Element,
        by areInIncreasingOrder: (Element, Element) -> Bool
    ) -> Index? {
        
        let index = sortedRightInsertionIndex(for: target, by: areInIncreasingOrder)
        
        guard index != startIndex else { return nil }
        
        return self.index(before: index)
    }
}

// MARK: - Partitioning

extension RandomAccessCollection {
                
    /// The index of the first element that is equal to or greater than `target` according to the
    /// comparison predicate. If no such element exists, returns `endIndex`.
    ///
    /// The result corresponds to the insertion point for inserting `target` in the collection while
    /// maintaining the ordering. The insertion point is to the left of any existing occurrences of
    /// `target` in the collection.
    ///
    /// Corresponds to Python's `bisect.bisect_left`.
    ///
    /// - Precondition: The collection is sorted according to `areInCreasingOrder`.
    ///
    /// - Complexity: O(log(n)) where n is the size of the collection.
    func sortedLeftInsertionIndex(
        for target: Element,
        by areInIncreasingOrder: (Element, Element) -> Bool
    ) -> Index {
        
        partitionIndex { areInIncreasingOrder($0, target) }
    }
    
    /// The index of the first element that is greater than `target` according to the comparison
    /// predicate. If no such element exists, returns `endIndex`.
    ///
    /// The result corresponds to the insertion point for inserting `target` in the collection while
    /// maintaining the ordering. The insertion point is to the right of any existing occurrences of
    /// `target` in the collection.
    ///
    /// Corresponds to Python's `bisect.bisect_right`.
    ///
    /// - Precondition: The collection is sorted according to `areInCreasingOrder` and
    ///   `areInCreasingOrder` establishes a **total order** on the elements.
    ///
    /// - Complexity: O(log(n)) where n is the size of the collection.
    func sortedRightInsertionIndex(
        for target: Element,
        by areInIncreasingOder: (Element, Element) -> Bool
    ) -> Index {
        
        // "$0 <= target"
        // Requires total ordering: if `!(a < b) && !(b < a)` then `(a == b)`.
        partitionIndex {
            areInIncreasingOder($0, target)
                || (!areInIncreasingOder($0, target) && !areInIncreasingOder(target, $0))
        }
    }
    
    /// The index of the first element that does not match the predicate. If no such element exists,
    /// returns `endIndex`.
    ///
    /// - Precondition: The collection is partitioned according to the predicate, i.e. all elements
    ///   that match the predicate are ordered before all elements that do not match.
    ///
    /// - Complexity: O(log(n)) where n is the size of the collection.
    private func partitionIndex(where belongsInFirstPartition: (Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
                        
            if belongsInFirstPartition(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        
        return low
    }
}
