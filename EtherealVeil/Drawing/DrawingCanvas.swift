// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// DrawingCanvas — renders stroke list via Canvas API with smooth Bezier paths.

import SwiftUI

struct DrawingCanvas: View {
    var vm: DrawingViewModel

    var body: some View {
        Canvas { context, _ in
            for stroke in vm.strokes {
                var ctx = context
                ctx.opacity = stroke.opacity
                ctx.blendMode = stroke.tool.blendMode

                ctx.stroke(
                    stroke.path,
                    with: .color(stroke.color),
                    style: StrokeStyle(
                        lineWidth: stroke.width,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
        }
        .background(Color(white: 0.08))
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
}
