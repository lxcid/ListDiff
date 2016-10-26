import Foundation
import XCTest
import ListDiff

extension Int : Diffable {
    public var diffIdentifier: AnyHashable {
        return String(self)
    }
}

extension String: Diffable {
    public var diffIdentifier: AnyHashable {
        return self
    }
}

class TestObject : Diffable, Equatable {
    let diffIdentifier: AnyHashable
    let value: Int
    
    init(diffIdentifier: AnyHashable, value: Int) {
        self.diffIdentifier = diffIdentifier
        self.value = value
    }
    
    static func ==(lhs: TestObject, rhs: TestObject) -> Bool {
        return (lhs === rhs) || (lhs.diffIdentifier == rhs.diffIdentifier && lhs.value == rhs.value)
    }
}

class TestObjectRef : Diffable, Equatable {
    let diffIdentifier: AnyHashable
    let value: Int
    
    init(diffIdentifier: AnyHashable, value: Int) {
        self.diffIdentifier = diffIdentifier
        self.value = value
    }
    
    static func ==(lhs: TestObjectRef, rhs: TestObjectRef) -> Bool {
        return lhs === rhs
    }
}

extension NSObject : Diffable {
    public var diffIdentifier: AnyHashable {
        return self.hash
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
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertFalse(result.hasChanges)
    }
    
    func test_whenDiffingFromEmptyArray_thatResultHasChanges() {
        let o = Array<Int>()
        let n = Array<Int>(arrayLiteral: 1)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.inserts, IndexSet(integer: 0))
        XCTAssertEqual(result.changeCount, 1)
    }

    func test_whenDiffingToEmptyArray_thatResultHasChanges() {
        let o = Array<Int>(arrayLiteral: 1)
        let n = Array<Int>()
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.deletes, IndexSet(integer: 0))
        XCTAssertEqual(result.changeCount, 1)
    }

    func test_whenSwappingObjects_thatResultHasMoves() {
        let o = Array<Int>(arrayLiteral: 1, 2)
        let n = Array<Int>(arrayLiteral: 2, 1)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 1, to: 0), List.MoveIndex(from: 0, to: 1)])
        XCTAssertEqual(result.changeCount, 2)
    }
    
    func test_whenMovingObjectsTogether_thatResultHasMoves() {
        // "tricks" is having multiple 3s
        let o = Array<Int>(arrayLiteral: 1, 2, 3, 3, 4)
        let n = Array<Int>(arrayLiteral: 2, 3, 1, 3, 4)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 1, to: 0), List.MoveIndex(from: 2, to: 1), List.MoveIndex(from: 0, to: 2)])
        XCTAssertEqual(result.changeCount, 3)
    }
    
    func test_whenSwappingObjects_thatResultHasMoves2() {
        let o = Array<Int>(arrayLiteral: 1, 2, 3, 4)
        let n = Array<Int>(arrayLiteral: 2, 4, 5, 3)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 3, to: 1), List.MoveIndex(from: 2, to: 3)])
    }
    
    func test_whenObjectEqualityChanges_thatResultHasUpdates() {
        let o = [
            TestObject(diffIdentifier: "0", value: 0),
            TestObject(diffIdentifier: "1", value: 1),
            TestObject(diffIdentifier: "2", value: 2),
        ]
        let n = [
            TestObject(diffIdentifier: "0", value: 0),
            TestObject(diffIdentifier: "1", value: 3), // value updated from 1 to 3
            TestObject(diffIdentifier: "2", value: 2),
        ]
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.updates, IndexSet(integer: 1))
        XCTAssertEqual(result.changeCount, 1)
    }
    
    func test_whenDiffingWordsFromPaper_thatInsertsMatchPaper() {
        // http://dl.acm.org/citation.cfm?id=359467&dl=ACM&coll=DL&CFID=529464736&CFTOKEN=43088172
        let oString = "much writing is like snow , a mass of long words and phrases falls upon the relevant facts covering up the details ."
        let nString = "a mass of latin words falls upon the relevant facts like soft snow , covering up the details ."
        let o = oString.characters.split(separator: " ").map(String.init)
        let n = nString.characters.split(separator: " ").map(String.init)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertEqual(result.inserts, IndexSet.from(array: [3, 11]))
    }
    
    func test_whenDiffingWordsFromPaper_thatDeletesMatchPaper() {
        // http://dl.acm.org/citation.cfm?id=359467&dl=ACM&coll=DL&CFID=529464736&CFTOKEN=43088172
        let oString = "much writing is like snow , a mass of long words and phrases falls upon the relevant facts covering up the details ."
        let nString = "a mass of latin words falls upon the relevant facts like soft snow , covering up the details ."
        let o = oString.characters.split(separator: " ").map(String.init)
        let n = nString.characters.split(separator: " ").map(String.init)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertEqual(result.deletes, IndexSet.from(array: [0, 1, 2, 9, 11, 12]))
    }
    
    func test_whenDeletingItems_withInserts_withMoves_thatResultHasInsertsMovesAndDeletes() {
        let o = Array<Int>(arrayLiteral: 0, 1, 2, 3, 4, 5, 6, 7, 8)
        let n = Array<Int>(arrayLiteral: 0, 2, 3, 4, 7, 6, 9, 5, 10)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.deletes, IndexSet.from(array: [1, 8]))
        XCTAssertEqual(result.inserts, IndexSet.from(array: [6, 8]))
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 7, to: 4), List.MoveIndex(from: 5, to: 7)])
    }
    
    func test_whenMovingItems_withEqualityChanges_thatResultsHasMovesAndUpdates() {
        let o = [
            TestObject(diffIdentifier: "0", value: 0),
            TestObject(diffIdentifier: "1", value: 1),
            TestObject(diffIdentifier: "2", value: 2),
            ]
        let n = [
            TestObject(diffIdentifier: "2", value: 3),
            TestObject(diffIdentifier: "1", value: 1),
            TestObject(diffIdentifier: "0", value: 0),
            ]
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.moves, [List.MoveIndex(from: 2, to: 0), List.MoveIndex(from: 0, to: 2)])
        XCTAssertEqual(result.updates, IndexSet(integer: 2))
        XCTAssertEqual(result.changeCount, 3)
    }
    
    func test_whenDiffingPointers_withObjectCopy_thatResultHasUpdate() {
        let o = [
            TestObjectRef(diffIdentifier: "0", value: 0),
            TestObjectRef(diffIdentifier: "1", value: 1),
            TestObjectRef(diffIdentifier: "2", value: 2),
            ]
        let n = [
            o[0],
            TestObjectRef(diffIdentifier: "1", value: 1), // new pointer
            o[2]
        ]
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(result.updates, IndexSet(integer: 1))
        XCTAssertEqual(result.changeCount, 1)
    }
    
    func test_whenDiffingPointers_withSameObjects_thatResultHasNoChanges() {
        let o = [
            TestObjectRef(diffIdentifier: "0", value: 0),
            TestObjectRef(diffIdentifier: "1", value: 1),
            TestObjectRef(diffIdentifier: "2", value: 2),
            ]
        let n = o.map { $0 }
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertFalse(result.hasChanges)
    }
    
    func test_whenDeletingObjects_withArrayOfEqualObjects_thatChangeCountMatches() {
        let o = Array<String>(arrayLiteral: "dog", "dog", "dog", "dog")
        let n = Array<String>(arrayLiteral: "dog", "dog")
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(o.count + result.inserts.count - result.deletes.count, 2)
    }
    
    func test_whenInsertingObjects_withArrayOfEqualObjects_thatChangeCountMatches() {
        let o = Array<String>(arrayLiteral: "dog", "dog")
        let n = Array<String>(arrayLiteral: "dog", "dog", "dog", "dog")
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(o.count + result.inserts.count - result.deletes.count, 4)
    }
    
    func test_whenInsertingObject_withOldArrayHavingMultiples_thatChangeCountMatches() {
        let o: [NSObject] = [
            NSObject(),
            NSObject(),
            NSObject(),
            NSNumber(integerLiteral: 49),
            NSNumber(integerLiteral: 33),
            NSString(string: "cat"),
            NSString(string: "cat"),
            NSNumber(integerLiteral: 0),
            NSNumber(integerLiteral: 14),
        ]
        var n = o
        n.insert(NSString(string: "cat"), at: 5)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(o.count + result.inserts.count - result.deletes.count, n.count)
    }
    
    func test_whenMovingDuplicateObjects_thatChangeCountMatches() {
        let o: [NSObject] = [
            NSNumber(integerLiteral: 1),
            NSNumber(integerLiteral: 20),
            NSNumber(integerLiteral: 14),
            NSObject(),
            NSString(string: "cat"),
            NSObject(),
            NSNumber(integerLiteral: 4),
            NSString(string: "dog"),
            NSString(string: "cat"),
            NSString(string: "cat"),
            NSString(string: "fish"),
            NSObject(),
            NSString(string: "fish"),
            NSObject(),
        ]
        let n: [NSObject] = [
            NSNumber(integerLiteral: 1),
            NSNumber(integerLiteral: 28),
            NSNumber(integerLiteral: 14),
            NSString(string: "cat"),
            NSString(string: "cat"),
            NSNumber(integerLiteral: 4),
            NSString(string: "dog"),
            o[3],
            NSString(string: "cat"),
            NSString(string: "fish"),
            o[11],
            NSString(string: "fish"),
            o[13],
        ]
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(o.count + result.inserts.count - result.deletes.count, n.count)
    }
    
    func test_whenDiffingDuplicatesAtTail_withDuplicateAtHead_thatResultHasNoChanges() {
        let o: [NSObject] = [
            NSString(string: "cat"),
            NSNumber(integerLiteral: 1),
            NSNumber(integerLiteral: 2),
            NSNumber(integerLiteral: 3),
            NSString(string: "cat"),
        ]
        let n: [NSObject] = [
            NSString(string: "cat"),
            NSNumber(integerLiteral: 1),
            NSNumber(integerLiteral: 2),
            NSNumber(integerLiteral: 3),
            NSString(string: "cat"),
        ]
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertFalse(result.hasChanges)
    }
    
    func test_whenDuplicateObjects_thatMovesAreUnique() {
        let o: [NSObject] = [
            NSString(string: "cat"),
            NSObject(),
            NSString(string: "dog"),
            NSString(string: "dog"),
            NSObject(),
            NSObject(),
            NSString(string: "cat"),
            NSNumber(integerLiteral: 65),
        ]
        let n: [NSObject] = [
            NSString(string: "cat"),
            o[1],
            NSString(string: "dog"),
            o[4],
            NSString(string: "dog"),
            o[5],
            NSString(string: "cat"),
            NSString(string: "cat"),
            NSString(string: "fish"),
            NSNumber(integerLiteral: 65),
        ]
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertEqual(Set(result.moves.map { $0.from }).count, result.moves.count)
    }
    
    func test_whenMovingObjectShiftsOthers_thatMovesContainRequiredMoves() {
        let o = Array<Int>(arrayLiteral: 1, 2, 3, 4, 5, 6, 7)
        let n = Array<Int>(arrayLiteral: 1, 4, 5, 2, 3, 6, 7)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertTrue(result.hasChanges)
        XCTAssertTrue(result.moves.contains(List.MoveIndex(from: 3, to: 1)))
        XCTAssertTrue(result.moves.contains(List.MoveIndex(from: 1, to: 3)))
    }

    func test_whenDiffing_thatOldIndexesMatch() {
        let o = Array<Int>(arrayLiteral: 1, 2, 3, 4, 5, 6, 7)
        let n = Array<Int>(arrayLiteral: 2, 9, 3, 1, 5, 6, 8)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertEqual(result.oldIndexFor(identifier: "1"), 0)
        XCTAssertEqual(result.oldIndexFor(identifier: "2"), 1)
        XCTAssertEqual(result.oldIndexFor(identifier: "3"), 2)
        XCTAssertEqual(result.oldIndexFor(identifier: "4"), 3)
        XCTAssertEqual(result.oldIndexFor(identifier: "5"), 4)
        XCTAssertEqual(result.oldIndexFor(identifier: "6"), 5)
        XCTAssertEqual(result.oldIndexFor(identifier: "7"), 6)
        XCTAssertEqual(result.oldIndexFor(identifier: "8"), nil)
        XCTAssertEqual(result.oldIndexFor(identifier: "9"), nil)
    }
    
    func test_whenDiffing_thatNewIndexesMatch() {
        let o = Array<Int>(arrayLiteral: 1, 2, 3, 4, 5, 6, 7)
        let n = Array<Int>(arrayLiteral: 2, 9, 3, 1, 5, 6, 8)
        let result = List.diffing(oldArray: o, newArray: n)
        XCTAssertEqual(result.newIndexFor(identifier: "1"), 3)
        XCTAssertEqual(result.newIndexFor(identifier: "2"), 0)
        XCTAssertEqual(result.newIndexFor(identifier: "3"), 2)
        XCTAssertEqual(result.newIndexFor(identifier: "4"), nil)
        XCTAssertEqual(result.newIndexFor(identifier: "5"), 4)
        XCTAssertEqual(result.newIndexFor(identifier: "6"), 5)
        XCTAssertEqual(result.newIndexFor(identifier: "7"), nil)
        XCTAssertEqual(result.newIndexFor(identifier: "8"), 6)
        XCTAssertEqual(result.newIndexFor(identifier: "9"), 1)
    }

    static var allTests : [(String, (ListDiffTests) -> () throws -> Void)] {
        return [
            ("test_whenDiffingEmptyArrays_thatResultHasNoChanges", test_whenDiffingEmptyArrays_thatResultHasNoChanges),
            ("test_whenDiffingFromEmptyArray_thatResultHasChanges", test_whenDiffingFromEmptyArray_thatResultHasChanges),
            ("test_whenDiffingToEmptyArray_thatResultHasChanges", test_whenDiffingToEmptyArray_thatResultHasChanges),
            ("test_whenSwappingObjects_thatResultHasMoves", test_whenSwappingObjects_thatResultHasMoves),
            ("test_whenMovingObjectsTogether_thatResultHasMoves", test_whenMovingObjectsTogether_thatResultHasMoves),
            ("test_whenSwappingObjects_thatResultHasMoves2", test_whenSwappingObjects_thatResultHasMoves2),
            ("test_whenObjectEqualityChanges_thatResultHasUpdates", test_whenObjectEqualityChanges_thatResultHasUpdates),
            ("test_whenDiffingWordsFromPaper_thatInsertsMatchPaper", test_whenDiffingWordsFromPaper_thatInsertsMatchPaper),
            ("test_whenDiffingWordsFromPaper_thatDeletesMatchPaper", test_whenDiffingWordsFromPaper_thatDeletesMatchPaper),
            ("test_whenDeletingItems_withInserts_withMoves_thatResultHasInsertsMovesAndDeletes", test_whenDeletingItems_withInserts_withMoves_thatResultHasInsertsMovesAndDeletes),
            ("test_whenMovingItems_withEqualityChanges_thatResultsHasMovesAndUpdates", test_whenMovingItems_withEqualityChanges_thatResultsHasMovesAndUpdates),
            ("test_whenDiffingPointers_withObjectCopy_thatResultHasUpdate", test_whenDiffingPointers_withObjectCopy_thatResultHasUpdate),
            ("test_whenDiffingPointers_withSameObjects_thatResultHasNoChanges", test_whenDiffingPointers_withSameObjects_thatResultHasNoChanges),
            ("test_whenDeletingObjects_withArrayOfEqualObjects_thatChangeCountMatches", test_whenDeletingObjects_withArrayOfEqualObjects_thatChangeCountMatches),
            ("test_whenInsertingObjects_withArrayOfEqualObjects_thatChangeCountMatches", test_whenInsertingObjects_withArrayOfEqualObjects_thatChangeCountMatches),
            ("test_whenInsertingObject_withOldArrayHavingMultiples_thatChangeCountMatches", test_whenInsertingObject_withOldArrayHavingMultiples_thatChangeCountMatches),
            ("test_whenMovingDuplicateObjects_thatChangeCountMatches", test_whenMovingDuplicateObjects_thatChangeCountMatches),
            ("test_whenDiffingDuplicatesAtTail_withDuplicateAtHead_thatResultHasNoChanges", test_whenDiffingDuplicatesAtTail_withDuplicateAtHead_thatResultHasNoChanges),
            ("test_whenDuplicateObjects_thatMovesAreUnique", test_whenDuplicateObjects_thatMovesAreUnique),
            ("test_whenMovingObjectShiftsOthers_thatMovesContainRequiredMoves", test_whenMovingObjectShiftsOthers_thatMovesContainRequiredMoves),
            ("test_whenDiffing_thatOldIndexesMatch", test_whenDiffing_thatOldIndexesMatch),
            ("test_whenDiffing_thatNewIndexesMatch", test_whenDiffing_thatNewIndexesMatch),
        ]
    }
}
