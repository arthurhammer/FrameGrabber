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
}
    
// MARK: - Utilities
    
private extension SampleTimingsTest {
        
    func time(forSeconds seconds: Double) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
    
    func timingInfo(forSeconds seconds: Double, duration: CMTime = .invalid) -> CMSampleTimingInfo {
        CMSampleTimingInfo(
            duration: duration,
            presentationTimeStamp: time(forSeconds: seconds),
            decodeTimeStamp: .invalid
        )
    }
    
    func timings(forSeconds seconds: [Double], duration: CMTime = .invalid) -> SampleTimes {
        let timings = seconds.sorted().map {
            timingInfo(forSeconds: $0, duration: duration)
        }

        return SampleTimes(values: timings)
    }
}
