// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Infinite glow-trail canvas — each touch stroke unveils a memory.

import SwiftUI

struct VeilCanvas: View {
    @ObservedObject var viewModel: VeilViewModel

    var body: some View {
        Canvas { context, _ in
            for trail in viewModel.glowTrails {
                // Outer soft halo
                context.stroke(
                    trail.path,
                    with: .color(trail.color.opacity(0.12)),
                    lineWidth: trail.thickness * 2.5
                )
                // Core luminous trail
                let bounds = trail.path.boundingRect
                context.stroke(
                    trail.path,
                    with: .linearGradient(
                        Gradient(colors: [trail.color.opacity(0.3), trail.color]),
                        startPoint: CGPoint(x: bounds.minX, y: bounds.midY),
                        endPoint: CGPoint(x: bounds.maxX, y: bounds.midY)
                    ),
                    lineWidth: trail.thickness
                )
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    viewModel.addPoint(value.location)
                }
                .onEnded { _ in
                    viewModel.endStroke()
                }
        )
        .drawingGroup(opaque: false)
        .overlay(clearButton, alignment: .bottomTrailing)
    }

    private var clearButton: some View {
        Button {
            viewModel.clearCanvas()
        } label: {
            Image(systemName: "sparkles")
                .foregroundStyle(.white.opacity(0.4))
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .padding(12)
    }
}

#Preview {
    VeilCanvas(viewModel: VeilViewModel())
        .frame(height: 450)
        .background(Color.black)
}
