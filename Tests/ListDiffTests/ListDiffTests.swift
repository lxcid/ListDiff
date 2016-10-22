import Foundation
import XCTest
@testable import ListDiff

extension Int : Diffable {
    var diffIdentifier: AnyHashable {
        return String(self)
    }
}

extension String: Diffable {
    var diffIdentifier: AnyHashable {
        return self
    }
}

extension IndexSet {
    static func from(array: Array<Int>) -> IndexSet {
        var indexSet = IndexSet()
        array.forEach { indexSet.insert($0) }
        return indexSet
    }
}

class ListDiffTests : XCTestCase {
    func test_whenDiffingEmptyArrays_thatResultHasNoChanges() {
        let o = Array<Int>()
        let n = Array<Int>()
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertFalse(result.hasChanges)
    }
    
    func test_whenDiffingFromEmptyArray_thatResultHasChanges() {
        let o = Array<Int>()
        let n = Array<Int>(arrayLiteral: 1)
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.inserts, IndexSet(integer: 0))
        XCTAssertEqual(result.changeCount, 1)
    }

    func test_whenDiffingToEmptyArray_thatResultHasChanges() {
        let o = Array<Int>(arrayLiteral: 1)
        let n = Array<Int>()
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.deletes, IndexSet(integer: 0))
        XCTAssertEqual(result.changeCount, 1)
    }

    func test_whenSwappingObjects_thatResultHasMoves() {
        let o = Array<Int>(arrayLiteral: 1, 2)
        let n = Array<Int>(arrayLiteral: 2, 1)
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 1, to: 0), List.MoveIndex(from: 0, to: 1)])
        XCTAssertEqual(result.changeCount, 2)
    }
    
    func test_whenMovingObjectsTogether_thatResultHasMoves() {
        // "tricks" is having multiple 3s
        let o = Array<Int>(arrayLiteral: 1, 2, 3, 3, 4)
        let n = Array<Int>(arrayLiteral: 2, 3, 1, 3, 4)
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 1, to: 0), List.MoveIndex(from: 2, to: 1), List.MoveIndex(from: 0, to: 2)])
        XCTAssertEqual(result.changeCount, 3)
    }
    
    func test_whenSwappingObjects_thatResultHasMoves2() {
        let o = Array<Int>(arrayLiteral: 1, 2, 3, 4)
        let n = Array<Int>(arrayLiteral: 2, 4, 5, 3)
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 3, to: 1), List.MoveIndex(from: 2, to: 3)])
    }
    
    // TODO: (stan@trifia.com) test_whenObjectEqualityChanges_thatResultHasUpdates
    
    func test_whenDiffingWordsFromPaper_thatInsertsMatchPaper() {
        // http://dl.acm.org/citation.cfm?id=359467&dl=ACM&coll=DL&CFID=529464736&CFTOKEN=43088172
        let oString = "much writing is like snow , a mass of long words and phrases falls upon the relevant facts covering up the details ."
        let nString = "a mass of latin words falls upon the relevant facts like soft snow , covering up the details ."
        let o = oString.characters.split(separator: " ").map(String.init)
        let n = nString.characters.split(separator: " ").map(String.init)
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertEqual(result.inserts, IndexSet.from(array: [3, 11]))
    }
    
    func test_whenDiffingWordsFromPaper_thatDeletesMatchPaper() {
        // http://dl.acm.org/citation.cfm?id=359467&dl=ACM&coll=DL&CFID=529464736&CFTOKEN=43088172
        let oString = "much writing is like snow , a mass of long words and phrases falls upon the relevant facts covering up the details ."
        let nString = "a mass of latin words falls upon the relevant facts like soft snow , covering up the details ."
        let o = oString.characters.split(separator: " ").map(String.init)
        let n = nString.characters.split(separator: " ").map(String.init)
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertEqual(result.deletes, IndexSet.from(array: [0, 1, 2, 9, 11, 12]))
    }
    
    func test_whenDeletingItems_withInserts_withMoves_thatResultHasInsertsMovesAndDeletes() {
        let o = Array<Int>(arrayLiteral: 0, 1, 2, 3, 4, 5, 6, 7, 8)
        let n = Array<Int>(arrayLiteral: 0, 2, 3, 4, 7, 6, 9, 5, 10)
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.deletes, IndexSet.from(array: [1, 8]))
        XCTAssertEqual(result.inserts, IndexSet.from(array: [6, 8]))
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 7, to: 4), List.MoveIndex(from: 5, to: 7)])
    }
    
    func test_whenDeletingObjects_withArrayOfEqualObjects_thatChangeCountMatches() {
        let o = Array<String>(arrayLiteral: "dog", "dog", "dog", "dog")
        let n = Array<String>(arrayLiteral: "dog", "dog")
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(o.count + result.inserts.count - result.deletes.count, 2)
    }
    
    func test_whenInsertingObjects_withArrayOfEqualObjects_thatChangeCountMatches() {
        let o = Array<String>(arrayLiteral: "dog", "dog")
        let n = Array<String>(arrayLiteral: "dog", "dog", "dog", "dog")
        let result = List.Diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(o.count + result.inserts.count - result.deletes.count, 4)
    }

    static var allTests : [(String, (ListDiffTests) -> () throws -> Void)] {
        return [
            ("test_whenDiffingEmptyArrays_thatResultHasNoChanges", test_whenDiffingEmptyArrays_thatResultHasNoChanges),
            ("test_whenDiffingFromEmptyArray_thatResultHasChanges", test_whenDiffingFromEmptyArray_thatResultHasChanges),
            ("test_whenDiffingToEmptyArray_thatResultHasChanges", test_whenDiffingToEmptyArray_thatResultHasChanges),
            ("test_whenSwappingObjects_thatResultHasMoves", test_whenSwappingObjects_thatResultHasMoves),
            ("test_whenMovingObjectsTogether_thatResultHasMoves", test_whenMovingObjectsTogether_thatResultHasMoves),
            ("test_whenSwappingObjects_thatResultHasMoves2", test_whenSwappingObjects_thatResultHasMoves2),
            ("test_whenDiffingWordsFromPaper_thatInsertsMatchPaper", test_whenDiffingWordsFromPaper_thatInsertsMatchPaper),
            ("test_whenDiffingWordsFromPaper_thatDeletesMatchPaper", test_whenDiffingWordsFromPaper_thatDeletesMatchPaper),
            ("test_whenDeletingItems_withInserts_withMoves_thatResultHasInsertsMovesAndDeletes", test_whenDeletingItems_withInserts_withMoves_thatResultHasInsertsMovesAndDeletes),
            ("test_whenDeletingObjects_withArrayOfEqualObjects_thatChangeCountMatches", test_whenDeletingObjects_withArrayOfEqualObjects_thatChangeCountMatches),
            ("test_whenInsertingObjects_withArrayOfEqualObjects_thatChangeCountMatches", test_whenInsertingObjects_withArrayOfEqualObjects_thatChangeCountMatches),
        ]
    }
}
