import XCTest
@testable import SampleTimeIndexer

final class BinarySearchTests: XCTestCase {
    
    // MARK: - sortedFirstIndex(of:)
    
    func test_indexOf_empty_shouldBeNil() {
        let array = [Int]().sorted()
        
        let input = 4
        let actual = array.sortedFirstIndex(of: input)
        let expected = array.firstIndex(of: input)
        
        XCTAssertEqual(actual, expected)
    }
    
    func test_indexOf_noMatch_shouldBeNil() {
        let array = [2, 4, 60, 80, 140, 150, 300, 900].sorted()

        let input = 90
        let actual = array.sortedFirstIndex(of: input)
        let expected = array.firstIndex(of: input)

        XCTAssertEqual(actual, expected)
    }
    
    func test_indexOf_match_shouldBeLeftmostMatch() {
        let array = [2, 4, 60, 80, 140, 140, 140, 150, 300, 900].sorted()

        let input = 140
        let actual = array.sortedFirstIndex(of: input)
        let expected = array.firstIndex(of: input)

        XCTAssertEqual(actual, expected)
    }
    
    func test_indexOf_randomMatches() {
        let array = randomArray(withCount: .random(in: 0...1000)).sorted()
        
        print("Testing random array of size \(array.count)")
        
        array.forEach {
            let actual = array.sortedFirstIndex(of: $0)
            let expected = array.firstIndex(of: $0)
            
            XCTAssertEqual(actual, expected)
        }
    }
    
    // MARK: - sortedLastIndex(ofElementLessThanOrEqualTo:)
    
    func test_indexLessOrEqualOf_empty_shouldBeNil() {
        let array = [Int]().sorted()
        
        let actual = array.sortedLastIndex(ofElementLessThanOrEqualTo: 4)
        
        XCTAssertNil(actual)
    }
    
    func test_indexLessOrEqualOf_beforeFirst_shouldBeNil() {
        let array = [2, 4, 60, 80, 140, 150, 300, 900].sorted()
        
        let actual = array.sortedLastIndex(ofElementLessThanOrEqualTo: -1)
        
        XCTAssertNil(actual)
    }
    
    func test_indexLessOrEqualOf_afterLast_shouldBeLast() {
        let array = [2, 4, 60, 80, 140, 150, 300, 900].sorted()
        
        let actual = array.sortedLastIndex(ofElementLessThanOrEqualTo: 1000)
        
        XCTAssertEqual(actual, 7)
    }
    
    func test_indexLessOrEqualOf_match_shouldBeRightmostMatch() {
        let array = [2, 4, 60, 80, 80, 80, 140, 140, 140, 150, 300, 900].sorted()
        
        let actual = array.sortedLastIndex(ofElementLessThanOrEqualTo: 80)
        
        XCTAssertEqual(actual, 5)
    }
    
    func test_indexLessOrEqualOf_inBetween_shouldBeSmallerNeighbour() {
        let array = [2, 4, 60, 80, 80, 80, 140, 140, 140, 150, 300, 900].sorted()
        
        let actual = array.sortedLastIndex(ofElementLessThanOrEqualTo: 100)
        
        XCTAssertEqual(actual, 5)
    }
    
    // MARK: - sortedLeftInsertionIndex(for:by:) / sortedRightInsertionIndex(for:by:)

    func test_insertionIndex_empty_shouldBe0() {
        let array = [Int]().sorted()
        
        let input = 4
        let actualLeft = array.sortedLeftInsertionIndex(for: input, by: <)
        let actualRight = array.sortedRightInsertionIndex(for: input, by: <)
        
        XCTAssertEqual(actualLeft, 0)
        XCTAssertEqual(actualRight, 0)
    }
    
    func test_insertionIndex_beforeFirst_shouldBe0() {
        let array = [2, 2, 4, 60, 80, 140, 150, 300, 900, 900].sorted()
       
        let input = -1
        let actualLeft = array.sortedLeftInsertionIndex(for: input, by: <)
        let actualRight = array.sortedRightInsertionIndex(for: input, by: <)
        
        XCTAssertEqual(actualLeft, 0)
        XCTAssertEqual(actualRight, 0)
    }
    
    func test_insertionIndex_afterLast_shouldBeLast() {
        let array = [2, 2, 4, 60, 80, 140, 150, 300, 900, 900].sorted()

        let input = 1000
        let actualLeft = array.sortedLeftInsertionIndex(for: input, by: <)
        let actualRight = array.sortedRightInsertionIndex(for: input, by: <)
        
        XCTAssertEqual(actualLeft, 10)
        XCTAssertEqual(actualRight, 10)
    }
    
    func test_insertionIndex_inBetween_shouldBeInBetween() {
        let array = [2, 4, 60, 80, 80, 80, 140, 140, 140, 150, 300, 900].sorted()
        
        let input = 100
        let actualLeft = array.sortedLeftInsertionIndex(for: input, by: <)
        let actualRight = array.sortedRightInsertionIndex(for: input, by: <)
        
        XCTAssertEqual(actualLeft, 6)
        XCTAssertEqual(actualRight, 6)
    }
    
    func test_insertionIndex_match_shouldBeLeftmostOrRightmost() {
        let array = [2, 4, 60, 80, 80, 80, 140, 140, 140, 150, 300, 900].sorted()
        
        let input = 80
        let actualLeft = array.sortedLeftInsertionIndex(for: input, by: <)
        let actualRight = array.sortedRightInsertionIndex(for: input, by: <)
        
        XCTAssertEqual(actualLeft, 3)
        XCTAssertEqual(actualRight, 6)
    }
}

// MARK: - Util

private extension BinarySearchTests {
    
    func randomArray(withCount count: Int) -> [Double] {
        let values = -9999999.0 ..< 9999999.0
        
        var array = [Double]()
        array.reserveCapacity(count)
        
        for _ in 0..<count {
            array.append(.random(in: values))
        }
        
        return array
    }
}
