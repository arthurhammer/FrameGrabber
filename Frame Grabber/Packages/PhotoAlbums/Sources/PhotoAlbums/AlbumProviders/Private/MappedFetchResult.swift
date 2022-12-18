import Photos

/// A `PHFetchResult` and a corresponding array representation, with an optional map in between.
///
/// `PhotoKit` fetch results are difficult (or impossible) to work with for some use cases, e.g.
/// filtering its contents. Working with arrays is easier at the cost of having to keep both in sync.
///
/// This structure can be used to conveniently create an array representation of a fetch result and
/// keep it up to date when the photo library changes. Depending on the given mapping, the initial
/// creation of the array can be costly. However, subsequent updates are applied incrementally and
/// performant.
struct MappedFetchResult<P: PHObject, M> {
    
    typealias Mapping = (P) -> (M)
    
    /// The original fetch result.
    let fetchResult: PHFetchResult<P>
    
    /// An array representation of the fetch result.
    let mapped: [M]
    
    /// The mapping to apply to elements in the fetch result.
    let mapping: Mapping
}

extension MappedFetchResult {

    /// Initializes `array` from the given fetch result and mapping.
    ///
    /// The fetch result is enumerated and mapped synchronously.
    init(fetchResult: PHFetchResult<P>, mapping: @escaping Mapping) {
        let mapped = Array(enumerating: fetchResult).map(mapping)
        
        self.init(fetchResult: fetchResult, mapped: mapped, mapping: mapping)
    }
}

// MARK: - Updating Fetch Results

extension MappedFetchResult where M: AlbumProtocol  {

    /// An updated fetch result by applying the given photo library changes.
    ///
    /// If available, applies the mapping incrementally on any inserted or changed objects.
    /// Otherwise, applies the mapping to all elements of the updated fetch result.
    ///
    /// If the fetch result did not change, returns `nil`.
    func applying(change: PHChange) -> MappedFetchResult<P, M>? {
        guard let changes = change.changeDetails(for: fetchResult) else { return nil }
        
        return applying(changes: changes)
    }
    
    private func applying(changes: PHFetchResultChangeDetails<P>) -> MappedFetchResult<P, M> {
        changes.hasIncrementalChanges
            ? applyingIncrementally(changes: changes)
            : MappedFetchResult(fetchResult: changes.fetchResultAfterChanges, mapping: mapping)
    }

    /// An updated fetch result by incrementally applying the given photo library changes.
    ///
    /// Applies the mapping on any inserted or changed objects.
    ///
    /// - Note: The current algorithm is a workaround for several bugs in `PhotoKit`. When moves are
    /// involved, `PhotoKit` reports indices incorrectly (but unpredictably so). If indices were
    /// reported correctly, we could simply apply the changes directly without having to enumerate
    /// the fetch result.
    private func applyingIncrementally(changes: PHFetchResultChangeDetails<P>) -> MappedFetchResult<P, M> {
        let originalIds = mapped.map { ($0.id, $0) }
        let changedIds = changes.changedObjects.map { ($0.localIdentifier, $0) }

        let originals = Dictionary(originalIds, uniquingKeysWith: { a, _ in a })
        let changed = Dictionary(changedIds, uniquingKeysWith: { a, _ in a })

        let updatedResult = changes.fetchResultAfterChanges
        let mapping = self.mapping

        // Moves and deletions are handled implicitly by enumerating.
        let updatedArray: [M] = Array(enumerating: updatedResult).map { object in
            // Changed
            if let changedAlbum = changed[object.localIdentifier] {
                return mapping(changedAlbum)
            }

            // Unchanged
            if let unchangedAlbum = originals[object.localIdentifier] {
                return unchangedAlbum
            }

            // Inserted
            return mapping(object)
        }

        return MappedFetchResult(
            fetchResult: updatedResult,
            mapped: updatedArray,
            mapping: mapping
        )
    }
}

// MARK: - Utility

private extension Array where Element: PHObject {

    /// Initializes the array with a fetch result.
    ///
    /// The fetch result is enumerated and its contents fetched synchronously. See `PHFetchResult`
    /// for more info.
    init(enumerating fetchResult: PHFetchResult<Element>) {
        var result = [Element]()
        result.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { object, _, _ in
            result.append(object)
        }

        self.init(result)
    }
}
