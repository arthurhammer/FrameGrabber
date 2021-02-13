import CoreMedia
import XCTest
@testable import SampleTimeIndexer

final class SampleTimingsTest: XCTestCase {
    
    // MARK: - sampleTiming(for:)/sampleTimingIndex(for:)
    
    func test_sampleTiming_empty_shouldBeNil() {
        let timings = self.timings(forSeconds: [])
        
        let input = time(forSeconds: 4)
        let actual = timings.sampleTiming(for: input)
        
        XCTAssertNil(actual)
    }
    
    func test_sampleTiming_beforeFirst_shouldBeFirst() {
        let timings = self.timings(forSeconds: [1, 2, 4, 4, 5, 5, 5, 8, 12])
        
        let input = time(forSeconds: 0)
        let actual = timings.sampleTiming(for: input)?.presentationTimeStamp
        
        XCTAssertEqual(actual, time(forSeconds: 1))
    }
    
    func test_sampleTiming_afterLast_shouldBeLast() {
        let timings = self.timings(forSeconds: [0, 100, 500, 1000])
        
        let input = time(forSeconds: 1500)
        let actual = timings.sampleTiming(for: input)?.presentationTimeStamp
        
        XCTAssertEqual(actual, time(forSeconds: 1000))
    }
    
    func test_sampleTiming_match_shouldBeRightmost() {
        let timings = self.timings(forSeconds: [8, 20, 30, 30, 70, 70, 70, 80, 120])
        
        let input = time(forSeconds: 30)
        let actual = timings.sampleTiming(for: input)?.presentationTimeStamp
        let actualIndex = timings.sampleTimingIndex(for: input)
        
        XCTAssertEqual(actual, input)
        XCTAssertEqual(actualIndex, 3)
    }
    
    func test_sampleTiming_inBetween_shouldBeLeftNeighbour() {
        let timings = self.timings(forSeconds: [8, 20, 30, 30, 70, 70, 70, 80, 120])

        let input = time(forSeconds: 69.9)
        let actual = timings.sampleTiming(for: input)?.presentationTimeStamp
        let actualIndex = timings.sampleTimingIndex(for: input)
        
        XCTAssertEqual(actual, time(forSeconds: 30))
        XCTAssertEqual(actualIndex, 3)
    }
    
    func test_sampleTiming_durationGaps_areIgnored() {
        let duration = time(forSeconds: 0.5)
        let timings = self.timings(forSeconds: [0, 1, 2, 3, 4, 5], duration: duration)
        
        let input = time(forSeconds: 1.9)
        let actual = timings.sampleTiming(for: input)?.presentationTimeStamp
        let actualIndex = timings.sampleTimingIndex(for: input)
        
        XCTAssertEqual(actual, time(forSeconds: 1))
        XCTAssertEqual(actualIndex, 1)
    }
    
    // MARK: - sampleTimingIndexInSecond(for:)
    
    func test_sampleIndexInSecond_empty_shouldBeNil() {
        let timings = self.timings(forSeconds: [])
        
        let input = time(forSeconds: 4)
        let actual = timings.sampleTimingIndexInSecond(for: input)
        
        XCTAssertNil(actual)
    }

    func test_sampleIndexInSecond_beforeFirst_shouldBeFirst() {
        let timings = self.timings(forSeconds: [1.2, 1.3, 1.6, 1.9, 2.2, 2.5, 2.8, 3.2, 3.5])
        
        let input = time(forSeconds: -5.9)
        let actual = timings.sampleTimingIndexInSecond(for: input)
        
        XCTAssertEqual(actual, 0)  // value 1.2
    }
    
    func test_sampleIndexInSecond_afterLast_shouldBeLast() {
        let timings = self.timings(forSeconds: [0.2, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8, 3.2, 3.5])
        
        let input = time(forSeconds: 4)
        let actual = timings.sampleTimingIndexInSecond(for: input)
        
        XCTAssertEqual(actual, 1)  // value 3.5
    }
        
    func test_sampleIndexInSecond_noneOfSameSecond_shouldReturnPreviousSecond() {
        let timings = self.timings(forSeconds: [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8, 3.2, 3.5])
        
        let input = time(forSeconds: 2.1)
        let actual = timings.sampleTimingIndexInSecond(for: input)
        
        XCTAssertEqual(actual, 2)  // value 1.8
    }
    
    func test_sampleIndexInSecond_smallestOfSameSecond_shouldReturnPreviousSecond() {
        let timings = self.timings(forSeconds: [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8, 2.1, 2.4, 2.7])
        
        let input = time(forSeconds: 2.05)
        let actual = timings.sampleTimingIndexInSecond(for: input)
        
        XCTAssertEqual(actual, 2) // value 1.8
    }
    
    func test_sampleIndexInSecond_inBetweenSameSecond_shouldReturnSameSecond() {
        let timings = self.timings(forSeconds: [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8, 2.1, 2.4, 2.7])
        
        let input = time(forSeconds: 2.2)
        let actual = timings.sampleTimingIndexInSecond(for: input)
        
        XCTAssertEqual(actual, 0) // value 2.1
    }
    
    func test_sampleIndexInSecond_exactMatch_shouldReturnMatch() {
        let timings = self.timings(forSeconds: [0, 0.3, 0.6, 0.9, 1.2, 1.5, 1.8, 2.1, 2.4, 2.7])
        
        let input = time(forSeconds: 2.4)
        let actual = timings.sampleTimingIndexInSecond(for: input)
        
        XCTAssertEqual(actual, 1) // value 2.4
    }
    
    /// This tests an implementation detail in `sampleTimingIndexInSecond(for:)`. It is included
    /// as a sanity check.
    ///
    /// `SampleTimes.values` are sorted by their `CMTime` values (fractional seconds). Ensure that
    /// this implies they are also sorted by their rounded down to seconds values (full seconds).
    /// This is the precondition for `sortedLeftInsertionIndex`/`sortedRightInsertionIndex`.
    func test_sampleIndexInSecond_partitionPrecondition_isMet() {
        let timings = self.timings(forSeconds: [-0.5, -0.5, -0.4, 0.0, 8.4, 8.4, 20.1, 30.1, 30.2, 30.3, 70.1, 70.2, 70.6, 70.9, 80.7, 120.0])
        let values = timings.values
        
        let actual = values
            .sorted { $0.presentationTimeStamp.seconds.rounded(.down) < $1.presentationTimeStamp.seconds.rounded(.down) }
                    
        let expected = values
            .sorted { $0.presentationTimeStamp < $1.presentationTimeStamp }
        
        // `CMTimingInfo` doesn't conform to `Equatable`, so compare time stamps.
        XCTAssertEqual(
            actual.map { $0.presentationTimeStamp },
            expected.map { $0.presentationTimeStamp }
        )
    }
    
    // MARK: - Timescale Rounding in sampleTiming(for:)/sampleTimingIndex(for:)
    
    func test_sampleTiming_closeMatchInDifferentTimescale_shouldReturnMatch() {
        let sampleTimescale = CMTimeScale(15360)
        
        // Subset of the video's samples as read from its track.
        let timings = SampleTimes(
            values: [
                CMTime(value: 2473728, timescale: sampleTimescale),  // 161.05 s
                CMTime(value: 2473984, timescale: sampleTimescale),  // 161.06666666666666 s
                CMTime(value: 2474240, timescale: sampleTimescale),  // 161.08333333333334 s
                CMTime(value: 2474496, timescale: sampleTimescale)   // 161.1 s
            ].map { info(for: $0) },
            
            // Input times are converted to this timescale.
            trackTimeScale: sampleTimescale,
            trackID: -1
        )
        
        // This time was the `AVPlayer`s current playback item's playback time after calling
        // `step(byCount: 1)`, i.e. the player stepped to the desired sample but returned this time.
        let input = CMTime(value: 161083333333, timescale: CMTimeScale(NSEC_PER_SEC))
        
        // This is the actual desired sample time.
        let expected = CMTime(value: 2474240, timescale: sampleTimescale)

        // The difference is miniscule.
        //
        // Technically, `input` is indeed smaller than `expected`. Therefore, according to its
        // specification, `sampleTiming(for:)` should (and did) round down to the previous sample.
        //
        // The issue arises because `AVPlayer` steps to the actually expected sample but uses a
        // timescale of `NSEC_PER_SEC` which loses the exact precision for both times to match.
        //
        // We could use an epsilon for comparisons but instead we changed `sampleTiming(for:)` to
        // first convert to the track's timescale.
        XCTAssertLessThan(abs(expected.seconds - input.seconds), 0.000000001)
        
        let actual = timings.sampleTiming(for: input)?.presentationTimeStamp
        let actualIndex = timings.sampleTimingIndex(for: input)
                
        // Returns the desired sample.
        XCTAssertEqual(actual, expected)
        XCTAssertEqual(actualIndex, 2)
    }
    
    /// A witness of the wrong behaviour of `sampleTiming(for:)` before it was fixed. See the
    /// previous test for the correct behaviour.
    func test_sampleTiming_closeMatchInDifferentTimescale_didReturnPreviousSample() {
        let sampleTimescale = CMTimeScale(15360)

        // Subset of the video's samples as read from its track.
        let timings = SampleTimes(
            values: [
                CMTime(value: 2473728, timescale: sampleTimescale),  // 161.05 s
                CMTime(value: 2473984, timescale: sampleTimescale),  // 161.06666666666666 s
                CMTime(value: 2474240, timescale: sampleTimescale),  // 161.08333333333334 s
                CMTime(value: 2474496, timescale: sampleTimescale)   // 161.1 s
            ].map { info(for: $0) },
            
            // Old behaviour: No conversion of input times to the track's timescale.
            trackTimeScale: CMTimeScale(NSEC_PER_SEC),
            trackID: -1
        )
        
        // This time was the `AVPlayer`s current playback item's playback time after calling
        // `step(byCount: 1)`, i.e. the player stepped to the desired sample but returned this time.
        let input = CMTime(value: 161083333333, timescale: CMTimeScale(NSEC_PER_SEC))
                
        // This is the actual desired sample time.
        let expected = CMTime(value: 2474240, timescale: sampleTimescale)
        
        // The directly preceeding sample to the expected one.
        let notExpected = CMTime(value: 2473984, timescale: sampleTimescale)

        // Input is much closer to the expected sample than the preceding one.
        XCTAssertLessThan(abs(expected.seconds - input.seconds), 0.000000001)
        XCTAssertGreaterThan(abs(notExpected.seconds - input.seconds), 0.01)
        
        let actual = timings.sampleTiming(for: input)?.presentationTimeStamp
        let actualIndex = timings.sampleTimingIndex(for: input)
                
        // Returns the preceding sample (technically correct but semantically wrong).
        XCTAssertEqual(actual, notExpected)
        XCTAssertEqual(actualIndex, 1)
    }
}
    
// MARK: - Utilities

private let defaultTimeScale = CMTimeScale(NSEC_PER_SEC)
    
private extension SampleTimingsTest {
        
    func time(forSeconds seconds: Double, timeScale: CMTimeScale = defaultTimeScale) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: timeScale)
    }

    func timings(
        forSeconds seconds: [Double],
        duration: CMTime = .invalid,
        samplesTimeScale: CMTimeScale = defaultTimeScale,
        trackTimeScale: CMTimeScale = defaultTimeScale
    ) -> SampleTimes {
        
        let timings = seconds.sorted().map {
            info(
                for: CMTime(seconds: $0, preferredTimescale: samplesTimeScale),
                duration: duration
            )
        }

        return SampleTimes(values: timings, trackTimeScale: trackTimeScale, trackID: -1)
    }
    
    func info(for time: CMTime, duration: CMTime = .invalid) -> CMSampleTimingInfo {
        CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: time,
            decodeTimeStamp: .invalid
        )
    }
}
