// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Painting system — textured brushes, wet-paint smear, layered opacity.

import SwiftUI

struct PaintingTab: View {
    @State private var vm = PaintingViewModel()
    @State private var showColorPicker = false
    @State private var showBrushPicker = false

    var body: some View {
        ZStack {
            Color(white: 0.96).ignoresSafeArea() // light canvas like watercolor paper

            VStack(spacing: 0) {
                toolbar
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)

                PaintingCanvas(vm: vm)
                    .ignoresSafeArea(edges: .bottom)
            }

            if showColorPicker { colorPickerSheet }
            if showBrushPicker { brushPickerSheet }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {

                // Brush type
                Button { showBrushPicker.toggle() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: vm.currentBrush.icon)
                        Text(vm.currentBrush.label)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                }

                Divider().frame(height: 28)

                // Size
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.secondary)
                    Slider(value: $vm.brushSize, in: 2...80)
                        .tint(vm.paintColor)
                        .frame(width: 90)
                    Image(systemName: "circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                // Opacity
                HStack(spacing: 4) {
                    Image(systemName: "square.lefthalf.filled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: $vm.brushOpacity, in: 0.05...1)
                        .tint(.gray)
                        .frame(width: 80)
                }

                Divider().frame(height: 28)

                // Color swatch
                Button { showColorPicker.toggle() } label: {
                    Circle()
                        .fill(vm.paintColor)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1.5))
                        .shadow(color: vm.paintColor.opacity(0.4), radius: 4)
                }

                Divider().frame(height: 28)

                Button { vm.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundStyle(vm.canUndo ? .primary : .secondary)
                }
                .disabled(!vm.canUndo)

                Button { vm.redo() } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .foregroundStyle(vm.canRedo ? .primary : .secondary)
                }
                .disabled(!vm.canRedo)

                Button { vm.clear() } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Overlays

    private var colorPickerSheet: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Text("Paint Color").font(.headline)

                ColorPicker("", selection: $vm.paintColor, supportsOpacity: false)
                    .labelsHidden().scaleEffect(1.3)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 8), spacing: 8) {
                    ForEach(PaintingViewModel.artistPalette, id: \.self) { c in
                        Circle().fill(c).frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                            .onTapGesture { vm.paintColor = c; showColorPicker = false }
                    }
                }
                Button("Done") { showColorPicker = false }
                    .buttonStyle(.borderedProminent).tint(.indigo)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .background(Color.black.opacity(0.3).ignoresSafeArea())
        .onTapGesture { showColorPicker = false }
    }

    private var brushPickerSheet: some View {
        VStack {
            Spacer()
            VStack(spacing: 14) {
                Text("Brush Type").font(.headline)
                ForEach(PaintBrush.allCases) { brush in
                    Button {
                        vm.currentBrush = brush
                        showBrushPicker = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: brush.icon)
                                .font(.title3)
                                .foregroundStyle(vm.currentBrush == brush ? .indigo : .primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(brush.label).font(.subheadline.bold())
                                Text(brush.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if vm.currentBrush == brush {
                                Image(systemName: "checkmark").foregroundStyle(.indigo)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(vm.currentBrush == brush ? Color.indigo.opacity(0.1) : .clear,
                                    in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .background(Color.black.opacity(0.3).ignoresSafeArea())
        .onTapGesture { showBrushPicker = false }
    }
}
