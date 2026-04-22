// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// PaintingViewModel — wet-paint strokes, textured brush simulation.

import SwiftUI
import Observation

// MARK: - Brush Type

enum PaintBrush: String, CaseIterable, Identifiable {
    case round, flat, fan, palette, watercolor, oil

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .round:      "paintbrush.fill"
        case .flat:       "rectangle.fill"
        case .fan:        "leaf.fill"
        case .palette:    "paintpalette.fill"
        case .watercolor: "drop.fill"
        case .oil:        "circle.lefthalf.filled.righthalf.strikethrough.circle"
        }
    }

    var label: String {
        switch self {
        case .round:      "Round"
        case .flat:       "Flat"
        case .fan:        "Fan"
        case .palette:    "Palette Knife"
        case .watercolor: "Watercolor"
        case .oil:        "Oil"
        }
    }

    var description: String {
        switch self {
        case .round:      "Smooth tapered strokes"
        case .flat:       "Wide angular fills"
        case .fan:        "Feathered texture"
        case .palette:    "Thick impasto smear"
        case .watercolor: "Soft translucent washes"
        case .oil:        "Rich opaque blending"
        }
    }

    // Scatter offsets simulate brush bristles
    var bristleCount: Int {
        switch self {
        case .round:      1
        case .flat:       6
        case .fan:        12
        case .palette:    8
        case .watercolor: 3
        case .oil:        5
        }
    }
}

// MARK: - Paint Stroke

struct PaintStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    let color: Color
    let size: CGFloat
    let opacity: Double
    let brush: PaintBrush

    var path: Path {
        var p = Path()
        guard points.count > 1 else {
            if let pt = points.first {
                p.addEllipse(in: CGRect(x: pt.x - size / 2, y: pt.y - size / 2,
                                        width: size, height: size))
            }
            return p
        }
        p.move(to: points[0])
        for i in 1..<points.count {
            let cp = CGPoint(
                x: (points[i].x + points[i - 1].x) / 2,
                y: (points[i].y + points[i - 1].y) / 2
            )
            p.addQuadCurve(to: cp, control: points[i - 1])
        }
        p.addLine(to: points.last!)
        return p
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class PaintingViewModel {
    var strokes: [PaintStroke] = []
    var currentBrush: PaintBrush = .round
    var paintColor: Color = Color(red: 0.2, green: 0.3, blue: 0.8)
    var brushSize: Double = 18
    var brushOpacity: Double = 0.85

    private var undoStack: [[PaintStroke]] = []
    private var redoStack: [[PaintStroke]] = []
    private var activeId: UUID?

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func startStroke(at point: CGPoint) {
        let stroke = PaintStroke(
            points: [point],
            color: paintColor,
            size: CGFloat(brushSize),
            opacity: brushOpacity,
            brush: currentBrush
        )
        activeId = stroke.id
        strokes.append(stroke)
    }

    func addPoint(_ point: CGPoint) {
        guard let id = activeId,
              let idx = strokes.firstIndex(where: { $0.id == id }) else { return }
        strokes[idx].points.append(point)
    }

    func endStroke() {
        undoStack.append(strokes.dropLast().map { $0 })
        redoStack.removeAll()
        activeId = nil
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(strokes)
        strokes = prev
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

    // MARK: - Palette

    static let artistPalette: [Color] = [
        Color(red: 0.95, green: 0.95, blue: 0.95),
        Color(red: 0.85, green: 0.7, blue: 0.5),   // raw sienna
        Color(red: 0.7, green: 0.3, blue: 0.1),    // burnt sienna
        Color(red: 0.4, green: 0.2, blue: 0.05),   // burnt umber
        Color(red: 0.9, green: 0.85, blue: 0.2),   // cadmium yellow
        Color(red: 0.95, green: 0.5, blue: 0.1),   // cadmium orange
        Color(red: 0.85, green: 0.1, blue: 0.15),  // cadmium red
        Color(red: 0.55, green: 0.1, blue: 0.4),   // quinacridone magenta
        Color(red: 0.1, green: 0.25, blue: 0.65),  // ultramarine
        Color(red: 0.0, green: 0.45, blue: 0.7),   // cerulean
        Color(red: 0.0, green: 0.55, blue: 0.45),  // viridian
        Color(red: 0.1, green: 0.4, blue: 0.15),   // sap green
        Color(red: 0.95, green: 0.92, blue: 0.82), // titanium white
        Color(red: 0.15, green: 0.12, blue: 0.1),  // ivory black
        Color(red: 0.6, green: 0.55, blue: 0.45),  // yellow ochre
        Color(red: 0.3, green: 0.55, blue: 0.7),   // cobalt blue
    ]
}
