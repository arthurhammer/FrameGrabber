import CoreMedia

/// A sorted list of sample timing information of an asset and a mapping from playback time to exact
/// sample time.
public struct SampleTimes {

    /// Sorted by presentation time.
    public let values: [CMSampleTimingInfo]

    /// - Parameter values: Precondition: Is sorted by presentation time.
    public init(values: [CMSampleTimingInfo]) {
        self.values = values
    }
}

// MARK: - Convenience

extension SampleTimes {
    
    /// The presentation time (i.e. start time) of the sample being displayed at `playbackTime`
    /// during playback.
    ///
    /// The returned time is equal to or the largest value smaller than `playbackTime`. However,
    /// when `playbackTime` exceeds the left or right boundary of the values, returns the smallest
    /// or largest value (even if `playbackTime` is not a valid playback time). If the values are
    /// empty, returns `nil`.
    ///
    /// Gaps in timings are ignored. Example: If a sample starts at 4 s, ends at 4.5 s and the next
    /// sample starts at 5 s, a query for the playback time 4.8 s still returns the previous sample
    /// starting at 4 s.
    ///
    /// - Complexity: O(log(n)) where n is the length of `values`.
    public func sampleTiming(for playbackTime: CMTime) -> CMSampleTimingInfo? {
        guard let index = sampleTimingIndex(for: playbackTime) else { return nil }

        return values[index]
    }
    
    /// Like `sampleTime(for:)` but returning the corresponding index.
    public func sampleTimingIndex(for playbackTime: CMTime) -> Int? {
        guard !values.isEmpty else { return nil }
        
        // We are comparing `CMTime` to `CMSampleTimingInfo`.
        let reference = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: playbackTime,  // We only compare this field.
            decodeTimeStamp: .invalid
        )
        
        let index = values.sortedLastIndex(ofElementLessThanOrEqualTo: reference, by: {
            $0.presentationTimeStamp < $1.presentationTimeStamp
        })
        
        return index ?? 0
    }
}
