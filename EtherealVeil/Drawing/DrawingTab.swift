// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Drawing system — futuristic neon UI with integrated music controls.

import SwiftUI

struct DrawingTab: View {
    var musicPlayer: MusicPlayer
    @State private var vm = DrawingViewModel()
    @State private var showColorPicker = false

    var body: some View {
        ZStack {
            // Animated gradient background
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .black, Color(red: 0.05, green: 0, blue: 0.15), .black,
                    Color(red: 0, green: 0.05, blue: 0.12), Color(red: 0.06, green: 0.02, blue: 0.1), Color(red: 0.08, green: 0, blue: 0.1),
                    .black, Color(red: 0.03, green: 0, blue: 0.08), .black
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                neonToolbar
                canvasArea
                Spacer().frame(height: 110)
            }

            if showColorPicker { colorPickerOverlay }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DRAW")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .white],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                Text("Digital Sketch Studio")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            // Undo / Redo / Clear
            HStack(spacing: 14) {
                glowButton(icon: "arrow.uturn.backward", enabled: vm.canUndo) { vm.undo() }
                glowButton(icon: "arrow.uturn.forward", enabled: vm.canRedo) { vm.redo() }
                glowButton(icon: "trash", enabled: true, tint: .red) { vm.clear() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Neon Toolbar

    private var neonToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DrawingTool.allCases) { tool in
                    neonToolButton(tool: tool)
                }

                neonDivider

                // Stroke size
                HStack(spacing: 4) {
                    Circle().fill(.white.opacity(0.3)).frame(width: 4, height: 4)
                    Slider(value: $vm.strokeWidth, in: 1...40)
                        .tint(.cyan)
                        .frame(width: 70)
                    Circle().fill(.white.opacity(0.5)).frame(width: 10, height: 10)
                }

                neonDivider

                // Opacity
                HStack(spacing: 4) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                    Slider(value: $vm.opacity, in: 0.05...1)
                        .tint(.purple)
                        .frame(width: 70)
                }

                neonDivider

                // Color swatch
                Button { showColorPicker.toggle() } label: {
                    ZStack {
                        Circle()
                            .fill(vm.strokeColor)
                            .frame(width: 30, height: 30)
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.cyan.opacity(0.8), .purple.opacity(0.8)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                            .frame(width: 34, height: 34)
                    }
                    .shadow(color: vm.strokeColor.opacity(0.5), radius: 6)
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.15), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 12)
    }

    private func neonToolButton(tool: DrawingTool) -> some View {
        let selected = vm.currentTool == tool
        return Button { vm.currentTool = tool } label: {
            VStack(spacing: 3) {
                Image(systemName: tool.icon)
                    .font(.system(size: 18, weight: selected ? .bold : .regular))
                    .foregroundStyle(selected ? .cyan : .white.opacity(0.5))
                Text(tool.label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(selected ? .cyan : .white.opacity(0.3))
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color.cyan.opacity(0.15) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selected ? Color.cyan.opacity(0.4) : .clear, lineWidth: 1)
                    )
            )
            .shadow(color: selected ? .cyan.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    private var neonDivider: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 1, height: 28)
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        DrawingCanvas(vm: vm)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(colors: [.cyan.opacity(0.2), .purple.opacity(0.2), .clear],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: .cyan.opacity(0.1), radius: 20)
            .padding(.horizontal, 12)
            .padding(.top, 6)
    }

    // MARK: - Color Picker Overlay

    private var colorPickerOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Text("Color")
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                ColorPicker("", selection: $vm.strokeColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.4)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 8), spacing: 8) {
                    ForEach(DrawingViewModel.quickPalette, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: color.opacity(0.5), radius: 4)
                            .onTapGesture { vm.strokeColor = color; showColorPicker = false }
                    }
                }

                Button("Done") { showColorPicker = false }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [.cyan, .purple],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                    )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .background(Color.black.opacity(0.5).ignoresSafeArea())
        .onTapGesture { showColorPicker = false }
    }

    // MARK: - Helpers

    private func glowButton(icon: String, enabled: Bool, tint: Color = .cyan, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(enabled ? tint : .white.opacity(0.2))
                .frame(width: 34, height: 34)
                .background(Circle().fill(tint.opacity(enabled ? 0.12 : 0)))
                .shadow(color: enabled ? tint.opacity(0.3) : .clear, radius: 6)
        }
        .disabled(!enabled)
    }
}
