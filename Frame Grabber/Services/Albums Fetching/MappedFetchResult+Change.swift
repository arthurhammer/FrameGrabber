import Photos

extension MappedFetchResult where M: PhotosIdentifiable {

    /// A new mapped fetch result by applying the given photo library changes to the
    /// receiver.
    ///
    /// Executes the receiver's transform on any changed and inserted objects synchronously.
    func applyChanges(_ changes: PHFetchResultChangeDetails<P>) -> MappedFetchResult<P, M> {
        changes.hasIncrementalChanges
            ? applyIncrementalChanges(changes)
            : MappedFetchResult(fetchResult: changes.fetchResultAfterChanges, transform: transform)
    }

    /// A new mapped fetch result by applying the given photo library changes to the
    /// receiver.
    ///
    /// - Note: A more efficient solution would be to apply the changes directly on the
    ///   receiver's `array`. But there are constant issues when moves are involved,
    ///   indexes are reported incorrectly etc. This seems to be a bug in PhotosKit.
    private func applyIncrementalChanges(_ changes: PHFetchResultChangeDetails<P>) -> MappedFetchResult<P, M> {
        let originalIds = array.map { ($0.id, $0) }
        let changedIds = changes.changedObjects.map { ($0.localIdentifier, $0) }

        let originals = Dictionary(originalIds, uniquingKeysWith: { a, _ in a })
        let changed = Dictionary(changedIds, uniquingKeysWith: { a, _ in a })

        let updatedResult = changes.fetchResultAfterChanges
        let transform = self.transform

        // Moves and deletions are handled implicitly in the enumeration.
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

        return MappedFetchResult(fetchResult: updatedResult, array: updatedArray, transform: transform)
    }
}
