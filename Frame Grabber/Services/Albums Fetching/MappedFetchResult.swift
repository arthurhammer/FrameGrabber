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
        self.init(fetchResult: fetchResult,
                  array: Array(enumerating: fetchResult).map(transform),
                  transform: transform)
    }
}

extension Array where Element: PHObject {

    /// Initializes the array with a fetch result.
    ///
    /// The fetch result is enumerated (i.e. is contents fetched) synchronously. See
    /// `PHFetchResult` for more info.
    init(enumerating fetchResult: PHFetchResult<Element>) {
        var result = [Element]()
        result.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { object, _, _ in
            result.append(object)
        }

        self.init(result)
    }
}
