// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Manages glow trail state; each stroke cycles through an ethereal palette.

import SwiftUI

struct GlowTrail: Identifiable {
    let id = UUID()
    var path: Path
    let color: Color
    let thickness: CGFloat
}

class VeilViewModel: ObservableObject {
    @Published var glowTrails: [GlowTrail] = []

    private var activePoints: [CGPoint] = []
    private var strokeIndex = 0

    private let palette: [Color] = [
        .cyan, .purple, Color(red: 0.6, green: 0.4, blue: 1.0),
        Color(red: 0.4, green: 0.8, blue: 1.0), .indigo,
        Color(red: 0.9, green: 0.7, blue: 1.0)
    ]

    func addPoint(_ point: CGPoint) {
        activePoints.append(point)

        var path = Path()
        path.addLines(activePoints)

        let color = palette[strokeIndex % palette.count]

        if glowTrails.last?.color == color, !glowTrails.isEmpty {
            glowTrails[glowTrails.count - 1].path = path
        } else {
            glowTrails.append(GlowTrail(path: path, color: color, thickness: 10))
        }
    }

    func endStroke() {
        activePoints.removeAll()
        strokeIndex += 1
    }

    func clearCanvas() {
        withAnimation(.easeOut(duration: 0.4)) {
            glowTrails.removeAll()
        }
        activePoints.removeAll()
        strokeIndex = 0
    }
}
