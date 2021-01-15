import CoreMedia
import XCTest
@testable import SampleTimeIndexer

final class SampleTimingsTest: XCTestCase {
    
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
