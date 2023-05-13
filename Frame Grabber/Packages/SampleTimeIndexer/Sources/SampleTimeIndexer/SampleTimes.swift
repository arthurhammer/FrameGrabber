import CoreMedia

/// A sorted list of sample timing information of an asset and a mapping from playback time to exact
/// sample time.
public struct SampleTimes {

    /// Sorted by presentation time.
    public let values: [CMSampleTimingInfo]
    
    /// The natural time scale of the track the sample times were read from.
    public let trackTimeScale: CMTimeScale
    
    /// The id of the track the samples were read from.
    public let trackID: CMPersistentTrackID?
    
    /// - Parameter values: Precondition: Is sorted by presentation time.
    public init(
        values: [CMSampleTimingInfo],
        trackTimeScale: CMTimeScale,
        trackID: CMPersistentTrackID
    ) {
        self.values = values
        self.trackTimeScale = trackTimeScale
        self.trackID = trackID
    }
}

// MARK: - Finding Sample Times

extension SampleTimes {
    
    /// The presentation time (i.e. start time) of the sample being displayed at `playbackTime`
    /// during playback.
    ///
    /// The returned time is equal to or the largest value smaller than `playbackTime`. However,
    /// when `playbackTime` exceeds the left or right boundary of the values, returns the smallest
    /// or largest value (even if `playbackTime` is not a valid playback time). If the values are
    /// empty, returns `nil`.
    ///
    /// Before any comparisons are done, `playbackTime` is first converted to the track's timescale
    /// using `trackTime(for:)` to avoid rounding issues.
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
        
        // See `SampleTimingsTest` for a test case why first snapping to the track's timescale can
        // be important. It handles floating point comparisons implicitly.
        let target = referenceInfo(for: trackTime(for: playbackTime))
        
        let index = values.sortedLastIndex(ofElementLessThanOrEqualTo: target, by: {
            $0.presentationTimeStamp < $1.presentationTimeStamp
        })
        
        return index ?? 0
    }
    
    /// The index of the sample being displayed at `playbackTime` during playback relative to the
    /// containing second.
    ///
    /// Example: For the sample times `[0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8]`, the result for `1.8` is
    /// `2` because `1.8` is the third sample starting in second `1`.
    /// 
    /// `playbackTime` is first snapped to its corresponding sample time using `sampleTiming(for:)`.
    /// Thus, the reference second of the time at the returned index is not necessarily the same as
    ///  the one of `playbackTime`.
    ///
    /// Example: For the sample timings `[0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8]`, a query for `1.1`
    /// returns the index `3` for the time `0.9`.
    ///
    /// Similar to `sampleTiming(for:)`, gaps in timings are ignored.
    ///
    /// - Complexity: O(log(n)) where n is the length of `values`.
    public func sampleTimingIndexInSecond(for playbackTime: CMTime) -> Int? {
        guard let sampleTime = sampleTiming(for: playbackTime) else { return nil }
        
        let compareFullSecond = { (lhs: CMSampleTimingInfo, rhs: CMSampleTimingInfo) in
            // (Don't use `Int` constructor for rounding as it rounds negative values differently.)
            lhs.presentationTimeStamp.seconds.rounded(.down)
                < rhs.presentationTimeStamp.seconds.rounded(.down)
        }

        let left = values.sortedLeftInsertionIndex(for: sampleTime, by: compareFullSecond)
        let right = values.sortedRightInsertionIndex(for: sampleTime, by: compareFullSecond)
        let samplesInTargetSecond = values[left..<right]
                
        guard let indexInTargetSecond = samplesInTargetSecond.sortedFirstIndex(of: sampleTime, by: {
            $0.presentationTimeStamp < $1.presentationTimeStamp
        }) else { return nil }

        // Map slice index to array index.
        return indexInTargetSecond - samplesInTargetSecond.startIndex
    }
    
    /// The time scale of `playbackTime` converted to the natural time scale of the source track.
    ///
    /// The resulting time typically does not have the same seconds value than the given time due to
    /// rounding. The rounding method used is `CMTimeRoundingMethod.roundHalfAwayFromZero`.
    public func trackTime(for playbackTime: CMTime) -> CMTime {
        guard playbackTime.timescale != trackTimeScale else { return playbackTime }
        return playbackTime.convertScale(trackTimeScale, method: .roundHalfAwayFromZero)
    }
    
    private func referenceInfo(for time: CMTime) -> CMSampleTimingInfo {
        CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: time,  // We only compare this field.
            decodeTimeStamp: .invalid
        )
    }
}
