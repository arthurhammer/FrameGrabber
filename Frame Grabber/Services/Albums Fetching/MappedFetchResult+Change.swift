import Photos

/// A new fetch result with the given changes incrementally applied.
/// Synchronously executes the given fetch result's mapper on any new or inserted objects.
func applyIncrementalChanges<P, M>(_ changes: PHFetchResultChangeDetails<P>, to fetchResult: MappedFetchResult<P, M>) -> MappedFetchResult<P, M> where M: PhotosIdentifiable {
    // Rebuild everything. Expensive.
    if !changes.hasIncrementalChanges {
        return MappedFetchResult(fetchResult: changes.fetchResultAfterChanges, map: fetchResult.map)
    }

    // Workaround for handling moves. Reasonable.
    if changes.hasMoves {
        return applyIncrementalChangesWithMoves(changes, to: fetchResult)
    }

    // Without moves, apply changes directly. Fast.
    return applyIncrementalChangesWithoutMoves(changes, to: fetchResult)
}

private func applyIncrementalChangesWithoutMoves<P, M>(_ changes: PHFetchResultChangeDetails<P>, to fetchResult: MappedFetchResult<P, M>) -> MappedFetchResult<P, M> {
    let nsarray = NSMutableArray(array: fetchResult.array)
    let map = fetchResult.map

    if let removed = changes.removedIndexes, !removed.isEmpty {
        nsarray.removeObjects(at: removed)
    }

    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
        let mapped = changes.insertedObjects.map(map)
        nsarray.insert(mapped, at: inserted)
    }

    if let changed = changes.changedIndexes, !changed.isEmpty {
        let mapped = changes.changedObjects.map(map)
        nsarray.replaceObjects(at: changed, with: mapped)
    }

    let updatedFetchResult = changes.fetchResultAfterChanges
    let updatedArray = nsarray as! [M]

    return MappedFetchResult(fetchResult: updatedFetchResult, array: updatedArray, map: map)
}

/// Workaround to handle moves without resorting to a full rebuild. Ideally, we'd handle
/// moves directly like in `applyIncrementalChangesWithoutMoves` but something's bugged :(
private func applyIncrementalChangesWithMoves<P, M>(_ changes: PHFetchResultChangeDetails<P>, to fetchResult: MappedFetchResult<P, M>) -> MappedFetchResult<P, M> where M: PhotosIdentifiable {
    let originalsWithId = fetchResult.array.map { ($0.id, $0) }
    let changedWithId = changes.changedObjects.map { ($0.localIdentifier, $0) }

    let originalsById = Dictionary(originalsWithId, uniquingKeysWith: { a, _ in a })
    let changedById = Dictionary(changedWithId, uniquingKeysWith: { a, _ in a })

    let map = fetchResult.map
    let updatedFetchResult = changes.fetchResultAfterChanges

    // Enumerating the updated result handles moves and deletions implicitly.
    let updatedArray: [M] = enumerate(fetchResult: updatedFetchResult) { object in
        // Changed
        if let changedAlbum = changedById[object.localIdentifier] {
            return map(changedAlbum)
        }

        // Unchanged
        if let unchangedAlbum = originalsById[object.localIdentifier] {
            return unchangedAlbum
        }

        // Inserted
        return map(object)
    }

    return MappedFetchResult(fetchResult: updatedFetchResult, array: updatedArray, map: map)
}

// MARK: - Util

/// An array from a fetch result.
/// By enumerating the fetch result, its contents will be fetched synchronously.
func enumerate<P>(fetchResult: PHFetchResult<P>) -> [P] {
    enumerate(fetchResult: fetchResult, map: { $0 })
}

/// An array from a fetch result, mapping the contents.
/// By enumerating the fetch result, its contents will be fetched synchronously.
func enumerate<P, M>(fetchResult: PHFetchResult<P>, map: @escaping (P) -> M) -> [M] {
    var result = [M]()
    result.reserveCapacity(fetchResult.count)

    fetchResult.enumerateObjects { object, _, _ in
        result.append(map(object))
    }

    return result
}
