// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// DrawingViewModel tests (replaces VeilViewModel tests — class was renamed in the redesign).

import XCTest
import SwiftUI
@testable import EtherealVeil

@MainActor
final class VeilViewModelTests: XCTestCase {

    private var sut: DrawingViewModel!

    override func setUp() {
        super.setUp()
        sut = DrawingViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsEmpty() {
        XCTAssertTrue(sut.strokes.isEmpty)
    }

    // MARK: - addPoint (via startStroke + addPoint)

    func testAddPointCreatesOneTrail() {
        sut.startStroke(at: CGPoint(x: 10, y: 20))
        sut.addPoint(CGPoint(x: 15, y: 25))
        sut.endStroke()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    func testAddPointsWithinSameStrokeDoNotStackTrails() {
        sut.startStroke(at: CGPoint(x: 0, y: 0))
        sut.addPoint(CGPoint(x: 10, y: 10))
        sut.addPoint(CGPoint(x: 20, y: 20))
        XCTAssertEqual(sut.strokes.count, 1)
    }

    func testEachTrailHasPositiveThickness() {
        sut.startStroke(at: CGPoint(x: 5, y: 5))
        XCTAssertGreaterThan(sut.strokes.first?.width ?? 0, 0)
    }

    func testTrailPathGrowsWithPoints() {
        sut.startStroke(at: CGPoint(x: 100, y: 200))
        sut.addPoint(CGPoint(x: 150, y: 250))
        sut.endStroke()
        let bounds = sut.strokes[0].path.boundingRect
        XCTAssertGreaterThan(bounds.width + bounds.height, 0)
    }

    // MARK: - endStroke

    func testEndStrokeAllowsNewStrokeToStartFresh() {
        sut.startStroke(at: CGPoint(x: 0, y: 0))
        sut.addPoint(CGPoint(x: 5, y: 5))
        sut.endStroke()
        sut.startStroke(at: CGPoint(x: 100, y: 100))
        sut.addPoint(CGPoint(x: 110, y: 110))
        sut.endStroke()
        XCTAssertEqual(sut.strokes.count, 2)
    }

    func testMultipleCompletedStrokes() {
        for i in 0..<4 {
            sut.startStroke(at: CGPoint(x: CGFloat(i * 10), y: 0))
            sut.addPoint(CGPoint(x: CGFloat(i * 10 + 5), y: 5))
            sut.endStroke()
        }
        XCTAssertEqual(sut.strokes.count, 4)
    }

    func testEndStrokeWithoutPointsIsHarmless() {
        XCTAssertNoThrow(sut.endStroke())
        XCTAssertTrue(sut.strokes.isEmpty)
    }

    // MARK: - clearCanvas

    func testClearCanvasRemovesAllTrails() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        sut.startStroke(at: CGPoint(x: 50, y: 50)); sut.addPoint(CGPoint(x: 55, y: 55)); sut.endStroke()
        sut.clear()
        XCTAssertTrue(sut.strokes.isEmpty)
    }

    func testClearCanvasThenDrawWorks() {
        sut.startStroke(at: CGPoint(x: 10, y: 10)); sut.addPoint(CGPoint(x: 15, y: 15)); sut.endStroke()
        sut.clear()
        sut.startStroke(at: CGPoint(x: 20, y: 20)); sut.addPoint(CGPoint(x: 25, y: 25)); sut.endStroke()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    // MARK: - Undo / Redo

    func testUndoRedoCycle() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        XCTAssertTrue(sut.canUndo)
        sut.undo()
        XCTAssertTrue(sut.strokes.isEmpty)
        XCTAssertTrue(sut.canRedo)
        sut.redo()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    func testTrailIdsAreUnique() {
        for i in 0..<5 {
            sut.startStroke(at: CGPoint(x: CGFloat(i * 10), y: 0))
            sut.addPoint(CGPoint(x: CGFloat(i * 10 + 5), y: 5))
            sut.endStroke()
        }
        let ids = sut.strokes.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
