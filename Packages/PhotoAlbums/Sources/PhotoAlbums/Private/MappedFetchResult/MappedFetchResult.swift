import Photos

/// A `PHFetchResult` and a corresponding array representation, applying a transform.
struct MappedFetchResult<P, M> where P: PHObject {
    let fetchResult: PHFetchResult<P>
    let array: [M]
    let transform: (P) -> (M)
}

extension MappedFetchResult {

    /// Initializes `array` from the given fetch result and transform.
    ///
    /// The fetch result is enumerated (i.e. is contents fetched) and transformed
    /// synchronously .
    init(fetchResult: PHFetchResult<P>, transform: @escaping (P) -> (M)) {
        self.init(
            fetchResult: fetchResult,
            array: Array(enumerating: fetchResult).map(transform),
            transform: transform
        )
    }
}

// MARK: - Applying Photo Library Changes

extension MappedFetchResult where M: AlbumProtocol  {

    /// A new mapped fetch result by incrementally applying the given photo library changes to the
    /// receiver.
    ///
    /// Executes the receiver's transform on any changed and inserted objects synchronously.
    func applyChanges(_ changes: PHFetchResultChangeDetails<P>) -> MappedFetchResult<P, M> {
        changes.hasIncrementalChanges
            ? applyIncrementalChanges(changes)
            : MappedFetchResult(fetchResult: changes.fetchResultAfterChanges, transform: transform)
    }

    /// A new mapped fetch result by incrementally applying the given photo library changes to the
    /// receiver.
    ///
    /// - Note: A more efficient solution would be to apply the changes directly on the receiver's
    ///  `array`. That solution would also not require the `M: Album` restriction. However there
    ///  are constant issues when moves are involved (e.g. indexes are reported incorrectly) which
    ///  seems to be a bug in PhotosKit.
    private func applyIncrementalChanges(_ changes: PHFetchResultChangeDetails<P>) -> MappedFetchResult<P, M> {
        let originalIds = array.map { ($0.id, $0) }
        let changedIds = changes.changedObjects.map { ($0.localIdentifier, $0) }

        let originals = Dictionary(originalIds, uniquingKeysWith: { a, _ in a })
        let changed = Dictionary(changedIds, uniquingKeysWith: { a, _ in a })

        let updatedResult = changes.fetchResultAfterChanges
        let transform = self.transform

        // Moves and deletions are handled implicitly by enumerating.
        let updatedArray: [M] = Array(enumerating: updatedResult).map { object in
            // Changed
            if let changedAlbum = changed[object.localIdentifier] {
                return transform(changedAlbum)
            }

            // Unchanged
            if let unchangedAlbum = originals[object.localIdentifier] {
                return unchangedAlbum
            }

            // Inserted
            return transform(object)
        }

        return MappedFetchResult(
            fetchResult: updatedResult,
            array: updatedArray,
            transform: transform
        )
    }
}

// MARK: - Utility

extension Array where Element: PHObject {

    /// Initializes the array with a fetch result.
    ///
    /// The fetch result is enumerated (i.e. is contents fetched) synchronously. See `PHFetchResult`
    /// for more info.
    fileprivate init(enumerating fetchResult: PHFetchResult<Element>) {
        var result = [Element]()
        result.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { object, _, _ in
            result.append(object)
        }

        self.init(result)
    }
}
