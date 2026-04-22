// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Creative Studio — text-to-image, voice-to-image prompt, photo upload, gallery.

import SwiftUI
import PhotosUI

struct CreativeStudioTab: View {
    @State private var vm = StudioViewModel()
    @State private var selectedSection: StudioSection = .generate

    var body: some View {
        ZStack {
            studioBackground

            VStack(spacing: 0) {
                sectionPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                switch selectedSection {
                case .generate: GenerateView(vm: vm)
                case .upload:   UploadView(vm: vm)
                case .gallery:  GalleryView(vm: vm)
                }
            }
        }
    }

    private var studioBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.0, blue: 0.12),
                     Color(red: 0.08, green: 0.03, blue: 0.18)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(StudioSection.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSection = section
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: section.icon)
                            .font(.system(size: 18))
                        Text(section.label)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(selectedSection == section ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedSection == section
                            ? LinearGradient(colors: [.indigo, .purple],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [.clear, .clear],
                                             startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
}

enum StudioSection: String, CaseIterable, Identifiable {
    case generate, upload, gallery
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .generate: "wand.and.stars"
        case .upload:   "photo.badge.plus"
        case .gallery:  "photo.stack"
        }
    }
    var label: String {
        switch self {
        case .generate: "Generate"
        case .upload:   "Upload"
        case .gallery:  "Gallery"
        }
    }
}

// MARK: - Generate View (text + voice → image)

struct GenerateView: View {
    @Bindable var vm: StudioViewModel
    @State private var promptText = ""
    @State private var selectedStyle: ImageStyle = .ethereal

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Prompt input
                VStack(alignment: .leading, spacing: 8) {
                    Label("Describe your vision", systemImage: "text.bubble")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.8))

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.07))
                            .frame(minHeight: 100)

                        TextEditor(text: $promptText)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .padding(10)
                            .frame(minHeight: 100)

                        if promptText.isEmpty {
                            Text("e.g. 'A moonlit garden with soft purple flowers…'")
                                .foregroundStyle(.white.opacity(0.3))
                                .font(.subheadline)
                                .padding(14)
                                .allowsHitTesting(false)
                        }
                    }
                }

                // Style selector
                VStack(alignment: .leading, spacing: 8) {
                    Label("Art Style", systemImage: "paintpalette")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.8))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ImageStyle.allCases) { style in
                                StyleChip(style: style, isSelected: selectedStyle == style) {
                                    selectedStyle = style
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }

                // Voice prompt button
                VStack(alignment: .leading, spacing: 8) {
                    Label("Or speak your vision", systemImage: "mic.circle")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.8))

                    Button {
                        vm.toggleVoiceRecording(updatePrompt: { transcribed in
                            promptText = transcribed
                        })
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(vm.isRecording
                                          ? Color.red.opacity(0.3)
                                          : Color.indigo.opacity(0.3))
                                    .frame(width: 50, height: 50)

                                Image(systemName: vm.isRecording ? "stop.circle.fill" : "mic.fill")
                                    .font(.title2)
                                    .foregroundStyle(vm.isRecording ? .red : .indigo)
                                    .scaleEffect(vm.isRecording ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                               value: vm.isRecording)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(vm.isRecording ? "Recording… tap to stop" : "Tap to record voice prompt")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                if !vm.voiceTranscript.isEmpty {
                                    Text(vm.voiceTranscript)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }

                // Generate button
                Button {
                    vm.generateImage(prompt: promptText.isEmpty ? vm.voiceTranscript : promptText,
                                     style: selectedStyle)
                } label: {
                    HStack(spacing: 10) {
                        if vm.isGenerating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(vm.isGenerating ? "Generating…" : "Generate Image")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.indigo, .purple],
                                       startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .foregroundStyle(.white)
                }
                .disabled(vm.isGenerating || (promptText.isEmpty && vm.voiceTranscript.isEmpty))

                // Generated result
                if let image = vm.latestGeneratedImage {
                    GeneratedImageCard(image: image, onSave: { vm.saveToGallery(image) })
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Upload View

struct UploadView: View {
    @Bindable var vm: StudioViewModel
    @State private var photoPickerItems: [PhotosPickerItem] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Photos picker
                PhotosPicker(selection: $photoPickerItems,
                             maxSelectionCount: 10,
                             matching: .images) {
                    VStack(spacing: 14) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(.indigo)
                        Text("Choose from Photo Library")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Select up to 10 images")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.indigo.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .buttonStyle(.plain)
                .onChange(of: photoPickerItems) { _, newItems in
                    Task { await vm.loadPickedPhotos(newItems) }
                }

                // Camera capture (real device only)
                Button {
                    vm.showCamera = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Take a Photo")
                                .font(.headline).foregroundStyle(.white)
                            Text("Capture and add directly to your gallery")
                                .font(.caption).foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $vm.showCamera) {
                    CameraView { image in
                        vm.addToGallery(image)
                        vm.showCamera = false
                    }
                }

                // Recently uploaded
                if !vm.gallery.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recently Added")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white.opacity(0.8))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                            ForEach(vm.gallery.prefix(6)) { item in
                                Image(uiImage: item.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Gallery View

struct GalleryView: View {
    var vm: StudioViewModel
    @State private var selected: GalleryItem?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 6)]

    var body: some View {
        ScrollView {
            if vm.gallery.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 52))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("No images yet")
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(vm.gallery) { item in
                        Image(uiImage: item.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .bottomTrailing) {
                                if item.source == .generated {
                                    Image(systemName: "wand.and.stars")
                                        .font(.caption2)
                                        .padding(4)
                                        .background(.ultraThinMaterial, in: Circle())
                                        .padding(4)
                                }
                            }
                            .onTapGesture { selected = item }
                    }
                }
                .padding(10)
            }
        }
        .sheet(item: $selected) { item in
            GalleryDetailView(item: item, onDelete: {
                vm.removeFromGallery(item)
                selected = nil
            })
        }
    }
}

// MARK: - Supporting Views

struct StyleChip: View {
    let style: ImageStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(style.label)
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple],
                                                       startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.white.opacity(0.08)),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

struct GeneratedImageCard: View {
    let image: UIImage
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .purple.opacity(0.4), radius: 16)

            HStack(spacing: 12) {
                Button(action: onSave) {
                    Label("Save to Gallery", systemImage: "square.and.arrow.down")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }

                ShareLink(item: Image(uiImage: image), preview: SharePreview("Ethereal Vision")) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.indigo.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct GalleryDetailView: View {
    let item: GalleryItem
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFit()
            }
            .navigationTitle(item.source == .generated ? "Generated" : "Uploaded")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: Image(uiImage: item.image),
                              preview: SharePreview("Ethereal Vision")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(.white)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
