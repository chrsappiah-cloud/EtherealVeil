// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Painting system — futuristic neon UI with textured brushes.

import SwiftUI

struct PaintingTab: View {
    var musicPlayer: MusicPlayer
    @State private var vm = PaintingViewModel()
    @State private var showColorPicker = false
    @State private var showBrushPicker = false

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .black, Color(red: 0.1, green: 0, blue: 0.08), .black,
                    Color(red: 0.06, green: 0, blue: 0.12), Color(red: 0.08, green: 0.02, blue: 0.06), Color(red: 0.1, green: 0, blue: 0.05),
                    .black, Color(red: 0.05, green: 0, blue: 0.1), .black
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
            if showBrushPicker { brushPickerOverlay }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PAINT")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .pink, .purple],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                Text("Textured Brush Studio")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            HStack(spacing: 14) {
                glowButton(icon: "arrow.uturn.backward", enabled: vm.canUndo, tint: .orange) { vm.undo() }
                glowButton(icon: "arrow.uturn.forward", enabled: vm.canRedo, tint: .orange) { vm.redo() }
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
                // Brush picker button
                Button { showBrushPicker.toggle() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: vm.currentBrush.icon)
                            .font(.system(size: 14, weight: .bold))
                        Text(vm.currentBrush.label)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.12))
                            .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
                    )
                    .shadow(color: .orange.opacity(0.2), radius: 6)
                }

                neonDivider

                HStack(spacing: 4) {
                    Circle().fill(.white.opacity(0.3)).frame(width: 4, height: 4)
                    Slider(value: $vm.brushSize, in: 2...80)
                        .tint(.orange)
                        .frame(width: 80)
                    Circle().fill(.white.opacity(0.5)).frame(width: 10, height: 10)
                }

                HStack(spacing: 4) {
                    Image(systemName: "square.lefthalf.filled")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                    Slider(value: $vm.brushOpacity, in: 0.05...1)
                        .tint(.pink)
                        .frame(width: 70)
                }

                neonDivider

                Button { showColorPicker.toggle() } label: {
                    ZStack {
                        Circle().fill(vm.paintColor).frame(width: 30, height: 30)
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.orange.opacity(0.8), .pink.opacity(0.8)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                            .frame(width: 34, height: 34)
                    }
                    .shadow(color: vm.paintColor.opacity(0.5), radius: 6)
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.4))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.15), lineWidth: 0.5))
        )
        .padding(.horizontal, 12)
    }

    private var neonDivider: some View {
        Rectangle()
            .fill(LinearGradient(colors: [.orange.opacity(0.3), .pink.opacity(0.3)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 1, height: 28)
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        PaintingCanvas(vm: vm)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(colors: [.orange.opacity(0.2), .pink.opacity(0.2), .clear],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: .orange.opacity(0.1), radius: 20)
            .padding(.horizontal, 12)
            .padding(.top, 6)
    }

    // MARK: - Color Picker

    private var colorPickerOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Text("Paint Color")
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                ColorPicker("", selection: $vm.paintColor, supportsOpacity: false)
                    .labelsHidden().scaleEffect(1.3)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 8), spacing: 8) {
                    ForEach(PaintingViewModel.artistPalette, id: \.self) { c in
                        Circle().fill(c).frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .shadow(color: c.opacity(0.4), radius: 4)
                            .onTapGesture { vm.paintColor = c; showColorPicker = false }
                    }
                }

                Button("Done") { showColorPicker = false }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [.orange, .pink],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                    )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.orange.opacity(0.2), lineWidth: 0.5))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .background(Color.black.opacity(0.5).ignoresSafeArea())
        .onTapGesture { showColorPicker = false }
    }

    // MARK: - Brush Picker

    private var brushPickerOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Text("Brush Type")
                    .font(.headline.bold())
                    .foregroundStyle(.white)

                ForEach(PaintBrush.allCases) { brush in
                    Button {
                        vm.currentBrush = brush
                        showBrushPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: brush.icon)
                                .font(.title3)
                                .foregroundStyle(vm.currentBrush == brush ? .orange : .white.opacity(0.6))
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(brush.label).font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                Text(brush.description).font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            Spacer()
                            if vm.currentBrush == brush {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(vm.currentBrush == brush ? Color.orange.opacity(0.12) : .clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(vm.currentBrush == brush ? Color.orange.opacity(0.3) : .clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.orange.opacity(0.2), lineWidth: 0.5))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .background(Color.black.opacity(0.5).ignoresSafeArea())
        .onTapGesture { showBrushPicker = false }
    }

    // MARK: - Helpers

    private func glowButton(icon: String, enabled: Bool, tint: Color = .orange, action: @escaping () -> Void) -> some View {
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
