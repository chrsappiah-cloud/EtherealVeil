// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Drawing system — pencil, brush, marker, eraser with full toolbar.

import SwiftUI

struct DrawingTab: View {
    @State private var vm = DrawingViewModel()
    @State private var showColorPicker = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                toolbar
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)

                DrawingCanvas(vm: vm)
                    .ignoresSafeArea(edges: .bottom)
            }

            if showColorPicker {
                colorPickerOverlay
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Tool picker
                HStack(spacing: 8) {
                    ForEach(DrawingTool.allCases) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: vm.currentTool == tool,
                            action: { vm.currentTool = tool }
                        )
                    }
                }

                Divider().frame(height: 28)

                // Stroke size
                HStack(spacing: 6) {
                    Image(systemName: "minus")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Slider(value: $vm.strokeWidth, in: 1...40)
                        .tint(.purple)
                        .frame(width: 80)
                    Image(systemName: "plus")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Divider().frame(height: 28)

                // Opacity
                HStack(spacing: 6) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Slider(value: $vm.opacity, in: 0.05...1)
                        .tint(.indigo)
                        .frame(width: 80)
                }

                Divider().frame(height: 28)

                // Color swatch
                Button {
                    showColorPicker.toggle()
                } label: {
                    Circle()
                        .fill(vm.strokeColor)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))
                        .shadow(color: vm.strokeColor.opacity(0.6), radius: 6)
                }

                Divider().frame(height: 28)

                // Undo / Redo / Clear
                Button { vm.undo() } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundStyle(vm.canUndo ? .white : .white.opacity(0.3))
                }
                .disabled(!vm.canUndo)

                Button { vm.redo() } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .foregroundStyle(vm.canRedo ? .white : .white.opacity(0.3))
                }
                .disabled(!vm.canRedo)

                Button { vm.clear() } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var colorPickerOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Text("Color")
                    .font(.headline)
                    .foregroundStyle(.white)

                ColorPicker("", selection: $vm.strokeColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.4)

                // Quick palette
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 8), spacing: 8) {
                    ForEach(DrawingViewModel.quickPalette, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().stroke(.white.opacity(0.25), lineWidth: 1)
                            )
                            .onTapGesture { vm.strokeColor = color; showColorPicker = false }
                    }
                }

                Button("Done") { showColorPicker = false }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
        .onTapGesture { showColorPicker = false }
    }
}

// MARK: - Tool Button

private struct ToolButton: View {
    let tool: DrawingTool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tool.icon)
                    .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .purple : .white.opacity(0.6))
                Text(tool.label)
                    .font(.system(size: 9))
                    .foregroundStyle(isSelected ? .purple : .white.opacity(0.4))
            }
            .frame(width: 44, height: 44)
            .background(isSelected ? Color.purple.opacity(0.2) : .clear,
                        in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
