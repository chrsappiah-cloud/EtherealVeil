// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// Ethereal Veil™ is a trademark of World Class Scholars.
// Unauthorized reproduction or distribution is prohibited.
// Drawing system — futuristic neon UI with integrated music controls.

import SwiftUI

struct DrawingTab: View {
    var musicPlayer: MusicPlayer
    var onSave: (Int) -> Void = { _ in }
    var onOpenLibrary: () -> Void = {}
    var onOpenPlaylist: () -> Void = {}
    var onOpenCloud: () -> Void = {}
    @State private var vm = DrawingViewModel()
    @State private var showColorPicker = false

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 0) {
                header
                actionRail
                gildedToolbar
                canvasArea
                Spacer().frame(height: 12)
            }

            if showColorPicker { colorPickerOverlay }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var backgroundGradient: some View {
        if #available(macOS 15, iOS 18, *) {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .black, Color(red: 0.18, green: 0.11, blue: 0.03), .black,
                    Color(red: 0.12, green: 0.08, blue: 0.02), Color(red: 0.21, green: 0.15, blue: 0.06), Color(red: 0.14, green: 0.09, blue: 0.02),
                    .black, Color(red: 0.09, green: 0.06, blue: 0.02), .black
                ]
            )
        } else {
            LinearGradient(
                colors: [
                    .black,
                    Color(red: 0.16, green: 0.1, blue: 0.03),
                    Color(red: 0.24, green: 0.18, blue: 0.08),
                    Color(red: 0.11, green: 0.07, blue: 0.02),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DRAW")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(GoldStudioTheme.sparkle)
                Text("Spackled Gold Sketch Atelier")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.58))
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

    private var actionRail: some View {
        HStack(spacing: 10) {
            workspaceButton(title: "Save", icon: "square.and.arrow.down.fill") {
                onSave(vm.strokes.count)
            }
            workspaceButton(title: "Library", icon: "books.vertical.fill", action: onOpenLibrary)
            workspaceButton(title: "Playlist", icon: "music.note.list", action: onOpenPlaylist)
            workspaceButton(title: "Cloud", icon: "icloud.and.arrow.up.fill", action: onOpenCloud)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Toolbar

    private var gildedToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(DrawingTool.allCases) { tool in
                    gildedToolButton(tool: tool)
                }

                gildedDivider

                // Stroke size
                HStack(spacing: 4) {
                    Circle().fill(Color.white.opacity(0.3)).frame(width: 4, height: 4)
                    Slider(value: $vm.strokeWidth, in: 1...40)
                        .tint(Color(red: 0.92, green: 0.77, blue: 0.36))
                        .frame(width: 70)
                    Circle().fill(Color.white.opacity(0.5)).frame(width: 10, height: 10)
                }

                gildedDivider

                // Opacity
                HStack(spacing: 4) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Slider(value: $vm.opacity, in: 0.05...1)
                        .tint(Color(red: 0.8, green: 0.62, blue: 0.26))
                        .frame(width: 70)
                }

                gildedDivider

                // Color swatch
                Button { showColorPicker.toggle() } label: {
                    ZStack {
                        Circle()
                            .fill(vm.strokeColor)
                            .frame(width: 30, height: 30)
                        Circle()
                            .stroke(
                                LinearGradient(colors: [Color.white.opacity(0.9), Color(red: 0.88, green: 0.69, blue: 0.29)],
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
                .fill(Color.black.opacity(0.36))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(GoldStudioTheme.sparkle.opacity(0.24), lineWidth: 0.8)
                )
        )
        .padding(.horizontal, 12)
    }

    private func gildedToolButton(tool: DrawingTool) -> some View {
        let selected = vm.currentTool == tool
        let iconStyle = selected ? AnyShapeStyle(GoldStudioTheme.sparkle) : AnyShapeStyle(Color.white.opacity(0.5))
        let labelStyle = selected ? AnyShapeStyle(GoldStudioTheme.sparkle) : AnyShapeStyle(Color.white.opacity(0.3))
        let borderStyle = selected ? AnyShapeStyle(GoldStudioTheme.sparkle.opacity(0.5)) : AnyShapeStyle(Color.clear)
        return Button { vm.currentTool = tool } label: {
            VStack(spacing: 3) {
                Image(systemName: tool.icon)
                    .font(.system(size: 18, weight: selected ? .bold : .regular))
                    .foregroundStyle(iconStyle)
                Text(tool.label)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(labelStyle)
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color(red: 0.88, green: 0.69, blue: 0.29).opacity(0.16) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderStyle, lineWidth: 1)
                    )
            )
            .shadow(color: selected ? Color(red: 0.88, green: 0.69, blue: 0.29).opacity(0.25) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    private var gildedDivider: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color.white.opacity(0.4), Color(red: 0.88, green: 0.69, blue: 0.29).opacity(0.4)],
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
                        LinearGradient(colors: [Color.white.opacity(0.25), Color(red: 0.88, green: 0.69, blue: 0.29).opacity(0.3), .clear],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color(red: 0.88, green: 0.69, blue: 0.29).opacity(0.12), radius: 20)
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
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(GoldStudioTheme.sparkle)
                    )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(GoldStudioTheme.sparkle.opacity(0.35), lineWidth: 0.8)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.black.opacity(0.5).ignoresSafeArea())
        .onTapGesture { showColorPicker = false }
    }

    // MARK: - Helpers

    private func workspaceButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Capsule().fill(GoldStudioTheme.sparkle))
        }
        .buttonStyle(.plain)
    }

    private func glowButton(icon: String, enabled: Bool, tint: Color = Color(red: 0.88, green: 0.69, blue: 0.29), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(enabled ? tint : Color.white.opacity(0.2))
                .frame(width: 34, height: 34)
                .background(Circle().fill(tint.opacity(enabled ? 0.12 : 0)))
                .shadow(color: enabled ? tint.opacity(0.3) : .clear, radius: 6)
        }
        .disabled(!enabled)
    }
}
