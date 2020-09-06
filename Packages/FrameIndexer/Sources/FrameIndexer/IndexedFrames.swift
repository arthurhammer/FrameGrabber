import CoreMedia

/// The result of a successful frame index operation, a sorted list of frame presentation time stamps.
public struct IndexedFrames {

    /// Sorted list of frame presentation time stamps.
    public let times: [CMTime]

    /// - Parameter times: Precondition: Times must be sorted.
    public init(times: [CMTime]) {
        self.times = times
    }

    /// Returns the time of the nearest frame for the given target time.
    ///
    /// If `times` is empty, returns nil.
    public func frame(closestTo time: CMTime) -> CMTime? {
        guard let index = index(closestTo: time) else { return nil }

        return times[index]
    }

    /// Returns the time of the nearest frame for the given target time, aka the frame number.
    public func index(closestTo time: CMTime) -> Int? {
        // todo: implement binary search.

        guard let index = times.firstIndex(where: { time <= $0 }) else {
            return times.indices.last
        }

        if times.indices ~= index-1 {
            let target = times[index]
            let previous = times[index-1]

            let isTargetCloser = abs((target - time).seconds) <= abs((previous - time).seconds)

            return isTargetCloser ? index : (index-1)
        }

        return index
    }
}
