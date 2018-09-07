import Photos

/// A fetch result and a corresponding array representation.
struct MappedFetchResult<P, M> where P: PHObject {
    let fetchResult: PHFetchResult<P>
    let array: [M]
    let map: (P) -> (M)
}

extension MappedFetchResult {
    /// Initializes `array` from the given fetch result and map.
    /// By enumerating the fetch result, its contents will be fetched synchronously.
    init(fetchResult: PHFetchResult<P>, map: @escaping (P) -> (M)) {
        let array = enumerate(fetchResult: fetchResult, map: map)
        self.init(fetchResult: fetchResult, array: array, map: map)
    }
}
