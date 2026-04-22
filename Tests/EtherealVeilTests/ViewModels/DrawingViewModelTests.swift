// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// DrawingViewModel + PaintingViewModel comprehensive tests.

import XCTest
import SwiftUI
@testable import EtherealVeil

// MARK: - DrawingViewModel

@MainActor
final class DrawingViewModelTests: XCTestCase {

    private var sut: DrawingViewModel!

    override func setUp() { super.setUp(); sut = DrawingViewModel() }
    override func tearDown() { sut = nil; super.tearDown() }

    // Initial state
    func testInitialStrokesEmpty() { XCTAssertTrue(sut.strokes.isEmpty) }
    func testInitialToolIsPencil() { XCTAssertEqual(sut.currentTool, .pencil) }
    func testInitialStrokeWidthIsPositive() { XCTAssertGreaterThan(sut.strokeWidth, 0) }
    func testInitialOpacityIsOne() { XCTAssertEqual(sut.opacity, 1.0) }
    func testInitialCanUndoFalse() { XCTAssertFalse(sut.canUndo) }
    func testInitialCanRedoFalse() { XCTAssertFalse(sut.canRedo) }

    // Stroke lifecycle
    func testStartAndEndStrokeAddsToStrokes() {
        sut.startStroke(at: CGPoint(x: 10, y: 10))
        sut.addPoint(CGPoint(x: 20, y: 20))
        sut.endStroke()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    func testCanUndoAfterStroke() {
        sut.startStroke(at: .zero)
        sut.addPoint(CGPoint(x: 5, y: 5))
        sut.endStroke()
        XCTAssertTrue(sut.canUndo)
    }

    func testUndoRemovesLastStroke() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        sut.startStroke(at: CGPoint(x: 10, y: 10)); sut.addPoint(CGPoint(x: 15, y: 15)); sut.endStroke()
        sut.undo()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    func testRedoReappliesUndoneStroke() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        sut.undo()
        sut.redo()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    func testRedoClearedAfterNewStroke() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        sut.undo()
        sut.startStroke(at: CGPoint(x: 1, y: 1)); sut.addPoint(CGPoint(x: 2, y: 2)); sut.endStroke()
        XCTAssertFalse(sut.canRedo)
    }

    func testClearRemovesAllStrokes() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        sut.clear()
        XCTAssertTrue(sut.strokes.isEmpty)
    }

    func testClearEnablesUndo() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        sut.clear()
        XCTAssertTrue(sut.canUndo)
    }

    func testUndoClearRestoresStrokes() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        sut.clear()
        sut.undo()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    // Tool types
    func testEraserToolBlendMode() {
        XCTAssertEqual(DrawingTool.eraser.blendMode, .clear)
    }

    func testNonEraserToolsNormalBlendMode() {
        [DrawingTool.pencil, .brush, .marker].forEach {
            XCTAssertEqual($0.blendMode, .normal)
        }
    }

    func testMarkerHasLowerBaseOpacity() {
        XCTAssertLessThan(DrawingTool.marker.baseOpacity, 1.0)
    }

    func testAllToolsHaveNonEmptyIcons() {
        DrawingTool.allCases.forEach { XCTAssertFalse($0.icon.isEmpty) }
    }

    func testAllToolsHaveNonEmptyLabels() {
        DrawingTool.allCases.forEach { XCTAssertFalse($0.label.isEmpty) }
    }

    // Quick palette
    func testQuickPaletteHas16Colors() {
        XCTAssertEqual(DrawingViewModel.quickPalette.count, 16)
    }

    // Eraser stroke color is clear
    func testEraserStrokeColorIsClear() {
        sut.currentTool = .eraser
        sut.startStroke(at: .zero)
        sut.addPoint(CGPoint(x: 5, y: 5))
        sut.endStroke()
        XCTAssertEqual(sut.strokes.last?.color, .clear)
    }

    // Edge: single point stroke
    func testSinglePointStrokePathIsValid() {
        sut.startStroke(at: CGPoint(x: 100, y: 100))
        sut.endStroke()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    // Edge: many undos beyond stack depth
    func testUndoBeyondStackIsHarmless() {
        for _ in 0..<100 { sut.undo() }
        XCTAssertTrue(sut.strokes.isEmpty)
    }
}

// MARK: - PaintingViewModel

@MainActor
final class PaintingViewModelTests: XCTestCase {

    private var sut: PaintingViewModel!

    override func setUp() { super.setUp(); sut = PaintingViewModel() }
    override func tearDown() { sut = nil; super.tearDown() }

    func testInitialStrokesEmpty() { XCTAssertTrue(sut.strokes.isEmpty) }
    func testDefaultBrushIsRound() { XCTAssertEqual(sut.currentBrush, .round) }
    func testDefaultBrushSizePositive() { XCTAssertGreaterThan(sut.brushSize, 0) }
    func testDefaultOpacityPositive() { XCTAssertGreaterThan(sut.brushOpacity, 0) }

    func testAddStrokeCreatesEntry() {
        sut.startStroke(at: .zero)
        sut.addPoint(CGPoint(x: 10, y: 10))
        sut.endStroke()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    func testBrushTypesAllHaveDescriptions() {
        PaintBrush.allCases.forEach { XCTAssertFalse($0.description.isEmpty) }
    }

    func testArtistPaletteHas16Colors() {
        XCTAssertEqual(PaintingViewModel.artistPalette.count, 16)
    }

    func testUndoRedoCycle() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        XCTAssertTrue(sut.canUndo)
        sut.undo()
        XCTAssertTrue(sut.canRedo)
        sut.redo()
        XCTAssertEqual(sut.strokes.count, 1)
    }

    func testClearRemovesAll() {
        sut.startStroke(at: .zero); sut.addPoint(CGPoint(x: 5, y: 5)); sut.endStroke()
        sut.clear()
        XCTAssertTrue(sut.strokes.isEmpty)
    }

    func testAllBrushesHaveIcons() {
        PaintBrush.allCases.forEach { XCTAssertFalse($0.icon.isEmpty) }
    }

    func testAllBrushesHaveLabels() {
        PaintBrush.allCases.forEach { XCTAssertFalse($0.label.isEmpty) }
    }

    func testBrushBristleCountPositive() {
        PaintBrush.allCases.forEach { XCTAssertGreaterThan($0.bristleCount, 0) }
    }
}
