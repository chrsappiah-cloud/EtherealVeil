// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// DrawingViewModel — stroke-based canvas with undo/redo stack.

import SwiftUI
import Observation

// MARK: - Models

enum DrawingTool: String, CaseIterable, Identifiable {
    case pencil, brush, marker, eraser

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pencil:  "pencil.tip"
        case .brush:   "paintbrush.pointed.fill"
        case .marker:  "highlighter"
        case .eraser:  "eraser.fill"
        }
    }

    var label: String { rawValue.capitalized }

    var blendMode: GraphicsContext.BlendMode {
        self == .eraser ? .clear : .normal
    }

    var baseOpacity: Double {
        switch self {
        case .marker:  0.5
        default:       1.0
        }
    }
}

struct DrawStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    let color: Color
    let width: CGFloat
    let opacity: Double
    let tool: DrawingTool

    var path: Path {
        var p = Path()
        guard points.count > 1 else { return p }
        p.move(to: points[0])
        for i in 1..<points.count {
            let mid = CGPoint(
                x: (points[i].x + points[i - 1].x) / 2,
                y: (points[i].y + points[i - 1].y) / 2
            )
            p.addQuadCurve(to: mid, control: points[i - 1])
        }
        p.addLine(to: points.last!)
        return p
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class DrawingViewModel {
    var strokes: [DrawStroke] = []
    var currentTool: DrawingTool = .pencil
    var strokeColor: Color = .white
    var strokeWidth: Double = 6
    var opacity: Double = 1.0

    private var undoStack: [[DrawStroke]] = []
    private var redoStack: [[DrawStroke]] = []
    private var activeStroke: DrawStroke?

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    // MARK: - Gesture handlers

    func startStroke(at point: CGPoint) {
        let stroke = DrawStroke(
            points: [point],
            color: currentTool == .eraser ? .clear : strokeColor,
            width: resolvedWidth,
            opacity: opacity * currentTool.baseOpacity,
            tool: currentTool
        )
        activeStroke = stroke
        strokes.append(stroke)
    }

    func addPoint(_ point: CGPoint) {
        guard var stroke = activeStroke else { return }
        stroke.points.append(point)
        activeStroke = stroke

        if let idx = strokes.firstIndex(where: { $0.id == stroke.id }) {
            strokes[idx] = stroke
        } else {
            strokes.append(stroke)
        }
    }

    func endStroke() {
        guard let stroke = activeStroke else { return }
        undoStack.append(strokes.filter { $0.id != stroke.id })
        redoStack.removeAll()
        activeStroke = nil
    }

    // MARK: - Undo / Redo / Clear

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(strokes)
        strokes = previous
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(strokes)
        strokes = next
    }

    func clear() {
        undoStack.append(strokes)
        redoStack.removeAll()
        strokes.removeAll()
    }

    // MARK: - Helpers

    private var resolvedWidth: CGFloat {
        switch currentTool {
        case .pencil:  CGFloat(strokeWidth * 0.6)
        case .brush:   CGFloat(strokeWidth)
        case .marker:  CGFloat(strokeWidth * 1.8)
        case .eraser:  CGFloat(strokeWidth * 2.5)
        }
    }

    // MARK: - Quick Palette

    static let quickPalette: [Color] = [
        .white, Color(white: 0.75), Color(white: 0.45), .black,
        .red, .orange, .yellow, .green,
        .cyan, .blue, .indigo, .purple,
        Color(red: 1, green: 0.4, blue: 0.7),
        Color(red: 0.6, green: 0.9, blue: 0.6),
        Color(red: 0.4, green: 0.8, blue: 1),
        Color(red: 1, green: 0.85, blue: 0.4),
    ]
}
