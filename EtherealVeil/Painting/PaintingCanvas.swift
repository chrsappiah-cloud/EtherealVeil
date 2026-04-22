// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// PaintingCanvas — renders paint strokes with brush-specific styling.

import SwiftUI

struct PaintingCanvas: View {
    var vm: PaintingViewModel

    var body: some View {
        Canvas { context, _ in
            for stroke in vm.strokes {
                render(stroke: stroke, in: &context)
            }
        }
        .background(
            // Warm off-white watercolor paper texture
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.95, blue: 0.9),
                         Color(red: 0.93, green: 0.91, blue: 0.86)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    if value.translation == .zero {
                        vm.startStroke(at: value.location)
                    } else {
                        vm.addPoint(value.location)
                    }
                }
                .onEnded { _ in vm.endStroke() }
        )
        .drawingGroup()
    }

    private func render(stroke: PaintStroke, in context: inout GraphicsContext) {
        let count = stroke.brush.bristleCount

        switch stroke.brush {
        case .watercolor:
            // Multiple transparent washes
            for layer in 0..<3 {
                var ctx = context
                ctx.opacity = stroke.opacity * 0.35
                let offset = CGFloat(layer) * 1.5
                let shifted = stroke.path.offsetBy(dx: offset, dy: offset)
                ctx.stroke(shifted, with: .color(stroke.color),
                           style: StrokeStyle(lineWidth: stroke.size,
                                              lineCap: .round, lineJoin: .round))
            }

        case .flat, .palette:
            for i in 0..<count {
                var ctx = context
                ctx.opacity = stroke.opacity * 0.7
                let offset = CGFloat(i) * (stroke.size / CGFloat(count)) - stroke.size / 2
                let shifted = stroke.path.offsetBy(dx: offset * 0.5, dy: offset * 0.3)
                ctx.stroke(shifted, with: .color(stroke.color),
                           style: StrokeStyle(lineWidth: stroke.size / CGFloat(count) + 2,
                                              lineCap: .square, lineJoin: .miter))
            }

        case .fan:
            for i in 0..<count {
                var ctx = context
                ctx.opacity = stroke.opacity * 0.4
                let angle = Double(i - count / 2) * 0.08
                let transform = CGAffineTransform(rotationAngle: angle)
                let rotated = stroke.path.applying(transform)
                ctx.stroke(rotated, with: .color(stroke.color),
                           style: StrokeStyle(lineWidth: max(1, stroke.size / CGFloat(count)),
                                              lineCap: .round))
            }

        default:
            var ctx = context
            ctx.opacity = stroke.opacity
            ctx.stroke(stroke.path, with: .color(stroke.color),
                       style: StrokeStyle(lineWidth: stroke.size,
                                          lineCap: .round, lineJoin: .round))
        }
    }
}

private extension Path {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> Path {
        applying(CGAffineTransform(translationX: dx, y: dy))
    }
}
