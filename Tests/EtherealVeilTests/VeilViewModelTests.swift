// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Unit tests for VeilViewModel — canvas state, stroke lifecycle, palette cycling.

import XCTest
import SwiftUI
@testable import EtherealVeil

final class VeilViewModelTests: XCTestCase {

    private var sut: VeilViewModel!

    override func setUp() {
        super.setUp()
        sut = VeilViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsEmpty() {
        XCTAssertTrue(sut.glowTrails.isEmpty, "Canvas should start with no trails")
    }

    // MARK: - addPoint

    func testAddPointCreatesOneTrail() {
        sut.addPoint(CGPoint(x: 10, y: 20))
        XCTAssertEqual(sut.glowTrails.count, 1)
    }

    func testAddPointsWithinSameStrokeDoNotStackTrails() {
        sut.addPoint(CGPoint(x: 0, y: 0))
        sut.addPoint(CGPoint(x: 10, y: 10))
        sut.addPoint(CGPoint(x: 20, y: 20))
        // All three points belong to one stroke — should accumulate into 1 trail
        XCTAssertEqual(sut.glowTrails.count, 1, "Consecutive points in one stroke must share a trail")
    }

    func testEachTrailHasPositiveThickness() {
        sut.addPoint(CGPoint(x: 5, y: 5))
        XCTAssertGreaterThan(sut.glowTrails[0].thickness, 0)
    }

    func testTrailPathIsNotEmpty() {
        sut.addPoint(CGPoint(x: 100, y: 200))
        // A path with one point has a valid (possibly zero-size) bounding rect;
        // adding a second ensures a non-zero width.
        sut.addPoint(CGPoint(x: 150, y: 250))
        let updated = sut.glowTrails[0].path.boundingRect
        XCTAssertGreaterThan(updated.width + updated.height, 0, "Path bounding rect should have extent")
    }

    // MARK: - endStroke

    func testEndStrokeAllowsNewStrokeToStartFresh() {
        sut.addPoint(CGPoint(x: 0, y: 0))
        sut.endStroke()
        // After ending, a new addPoint starts a second trail
        sut.addPoint(CGPoint(x: 100, y: 100))
        XCTAssertEqual(sut.glowTrails.count, 2, "Each stroke should produce its own trail")
    }

    func testMultipleCompletedStrokes() {
        for i in 0..<4 {
            sut.addPoint(CGPoint(x: CGFloat(i * 10), y: 0))
            sut.endStroke()
        }
        XCTAssertEqual(sut.glowTrails.count, 4)
    }

    func testEndStrokeWithoutPointsIsHarmless() {
        XCTAssertNoThrow(sut.endStroke(), "endStroke on an empty stroke must not throw")
        XCTAssertTrue(sut.glowTrails.isEmpty)
    }

    // MARK: - clearCanvas

    func testClearCanvasRemovesAllTrails() {
        sut.addPoint(CGPoint(x: 0, y: 0))
        sut.endStroke()
        sut.addPoint(CGPoint(x: 50, y: 50))
        sut.endStroke()
        sut.clearCanvas()
        XCTAssertTrue(sut.glowTrails.isEmpty, "clearCanvas must remove all trails")
    }

    func testClearCanvasResetsStrokeCounter() {
        // Exhaust the palette once to advance strokeIndex, then clear and
        // verify the first trail after clearing uses the same colour slot
        // as a brand-new instance (palette[0]).
        let fresh = VeilViewModel()
        fresh.addPoint(.zero)
        let freshColor = fresh.glowTrails[0].color

        for _ in 0..<6 {
            sut.addPoint(CGPoint(x: 1, y: 1))
            sut.endStroke()
        }
        sut.clearCanvas()
        sut.addPoint(.zero)
        XCTAssertEqual(
            sut.glowTrails[0].color, freshColor,
            "After clearCanvas strokeIndex must reset so palette starts at index 0"
        )
    }

    func testClearCanvasThenDrawWorks() {
        sut.addPoint(CGPoint(x: 10, y: 10))
        sut.clearCanvas()
        sut.addPoint(CGPoint(x: 20, y: 20))
        XCTAssertEqual(sut.glowTrails.count, 1, "Drawing after clear should work normally")
    }

    // MARK: - Palette Cycling

    func testPaletteCyclesAfterSixStrokes() {
        var colors: [Color] = []
        for i in 0..<12 {
            sut.addPoint(CGPoint(x: CGFloat(i), y: 0))
            colors.append(sut.glowTrails.last!.color)
            sut.endStroke()
        }
        // Palette has 6 entries — colours at positions 0 and 6 must match
        XCTAssertEqual(colors[0], colors[6], "Palette must cycle every 6 strokes")
        XCTAssertEqual(colors[1], colors[7])
    }

    func testTrailIdsAreUnique() {
        for i in 0..<5 {
            sut.addPoint(CGPoint(x: CGFloat(i * 10), y: 0))
            sut.endStroke()
        }
        let ids = sut.glowTrails.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Every GlowTrail must have a unique id")
    }
}
