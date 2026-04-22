// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Creative Studio — multi-provider image generation, voice, upload, gallery.

import SwiftUI
import PhotosUI
import SwiftData

struct CreativeStudioTab: View {
    @State private var vm = StudioViewModel()
    @State private var selectedSection: StudioSection = .generate
    @Environment(\.modelContext) private var modelContext

    // Bindable proxy so child views can use $vm bindings
    private var bindableVM: Bindable<StudioViewModel> { Bindable(vm) }

    var body: some View {
        ZStack {
            studioBackground
            VStack(spacing: 0) {
                sectionPicker.padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)
                switch selectedSection {
                case .generate: GenerateView(vm: vm)
                case .upload:   UploadView(vm: vm)
                case .gallery:  GalleryView(vm: vm)
                }
            }
        }
        .onAppear {
            vm.modelContext = modelContext
            vm.loadGalleryFromDatabase()
        }
        .sheet(isPresented: bindableVM.showAPIKeySettings) {
            APIKeySettingsView(vm: vm)
        }
    }

    private var studioBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.05, green: 0.0, blue: 0.12),
                     Color(red: 0.08, green: 0.03, blue: 0.18)],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(StudioSection.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedSection = section }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: section.icon).font(.system(size: 18))
                        Text(section.label).font(.caption.bold())
                    }
                    .foregroundStyle(selectedSection == section ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(
                        selectedSection == section
                            ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple],
                                                           startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.clear),
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

// MARK: - Section enum

enum StudioSection: String, CaseIterable, Identifiable {
    case generate, upload, gallery
    var id: String { rawValue }
    var icon: String {
        switch self { case .generate: "wand.and.stars"; case .upload: "photo.badge.plus"; case .gallery: "photo.stack" }
    }
    var label: String {
        switch self { case .generate: "Generate"; case .upload: "Upload"; case .gallery: "Gallery" }
    }
}

// MARK: - Generate View

struct GenerateView: View {
    @Bindable var vm: StudioViewModel
    @State private var promptText = ""
    @State private var selectedStyle: ImageStyle = .ethereal

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Provider selector
                providerRow

                // Prompt
                promptInput

                // Style
                styleRow

                // Size
                sizeRow

                // Voice
                voiceRow

                // Error banner
                if let err = vm.generationError {
                    ErrorBanner(message: err, onDismiss: { vm.generationError = nil })
                }

                // Generate button
                generateButton

                // Result
                if let image = vm.latestGeneratedImage {
                    GeneratedImageCard(image: image,
                                       onSave: { vm.addToGallery(image, source: "generated") })
                }
            }
            .padding(16)
        }
    }

    private var providerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("AI Provider", systemImage: "cpu").font(.subheadline.bold()).foregroundStyle(.white.opacity(0.8))
                Spacer()
                Button { vm.showAPIKeySettings = true } label: {
                    Label("API Keys", systemImage: "key.fill")
                        .font(.caption)
                        .foregroundStyle(vm.currentAPIKeyIsSet ? .green : .orange)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AIProvider.allCases) { provider in
                        ProviderChip(provider: provider,
                                     isSelected: vm.selectedProvider == provider,
                                     hasKey: KeychainService.hasKey(provider.keychainKey)) {
                            vm.selectedProvider = provider
                        }
                    }
                }
            }
        }
    }

    private var promptInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Describe your vision", systemImage: "text.bubble")
                .font(.subheadline.bold()).foregroundStyle(.white.opacity(0.8))
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)).frame(minHeight: 100)
                TextEditor(text: $promptText)
                    .scrollContentBackground(.hidden).foregroundStyle(.white).padding(10).frame(minHeight: 100)
                if promptText.isEmpty {
                    Text("e.g. 'A moonlit garden with soft purple flowers…'")
                        .foregroundStyle(.white.opacity(0.3)).font(.subheadline).padding(14).allowsHitTesting(false)
                }
            }
        }
    }

    private var styleRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Art Style", systemImage: "paintpalette").font(.subheadline.bold()).foregroundStyle(.white.opacity(0.8))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ImageStyle.allCases) { style in
                        StyleChip(style: style, isSelected: selectedStyle == style) { selectedStyle = style }
                    }
                }
            }
        }
    }

    private var sizeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Image Size", systemImage: "arrow.up.left.and.arrow.down.right")
                .font(.subheadline.bold()).foregroundStyle(.white.opacity(0.8))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ImageSize.allCases) { size in
                        Button { vm.selectedSize = size } label: {
                            Text(size.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .foregroundStyle(vm.selectedSize == size ? .white : .white.opacity(0.6))
                                .background(vm.selectedSize == size ? Color.purple.opacity(0.5) : Color.white.opacity(0.08),
                                            in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var voiceRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Or speak your vision", systemImage: "mic.circle")
                .font(.subheadline.bold()).foregroundStyle(.white.opacity(0.8))
            Button {
                vm.toggleVoiceRecording { transcribed in promptText = transcribed }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(vm.isRecording ? Color.red.opacity(0.3) : Color.indigo.opacity(0.3))
                            .frame(width: 50, height: 50)
                        Image(systemName: vm.isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundStyle(vm.isRecording ? .red : .indigo)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.isRecording ? "Listening… tap to stop" : "Tap to record voice prompt")
                            .font(.subheadline).foregroundStyle(.white)
                        if !vm.voiceTranscript.isEmpty {
                            Text(vm.voiceTranscript).font(.caption).foregroundStyle(.white.opacity(0.5)).lineLimit(2)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var generateButton: some View {
        Button {
            vm.generateImage(prompt: promptText.isEmpty ? vm.voiceTranscript : promptText,
                             style: selectedStyle)
        } label: {
            HStack(spacing: 10) {
                if vm.isGenerating { ProgressView().tint(.white) }
                else { Image(systemName: "wand.and.stars") }
                Text(vm.isGenerating ? "Generating…" : "Generate Image").font(.headline)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .opacity(canGenerate ? 1 : 0.5)
        }
        .disabled(!canGenerate)
    }

    private var canGenerate: Bool {
        !vm.isGenerating && !(promptText.isEmpty && vm.voiceTranscript.isEmpty)
    }
}

// MARK: - Upload View

struct UploadView: View {
    @Bindable var vm: StudioViewModel
    @State private var photoPickerItems: [PhotosPickerItem] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 10, matching: .images) {
                    VStack(spacing: 14) {
                        Image(systemName: "photo.badge.plus").font(.system(size: 48)).foregroundStyle(.indigo)
                        Text("Choose from Photo Library").font(.headline).foregroundStyle(.white)
                        Text("Select up to 10 images").font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 40)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.indigo.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8])))
                }
                .buttonStyle(.plain)
                .onChange(of: photoPickerItems) { _, new in Task { await vm.loadPickedPhotos(new) } }

                Button { vm.showCamera = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill").font(.title2).foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Take a Photo").font(.headline).foregroundStyle(.white)
                            Text("Capture directly to gallery").font(.caption).foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16).background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $vm.showCamera) {
                    CameraView { image in vm.addToGallery(image, source: "camera"); vm.showCamera = false }
                }

                if !vm.gallery.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recently Added").font(.subheadline.bold()).foregroundStyle(.white.opacity(0.8))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                            ForEach(vm.gallery.prefix(6)) { item in
                                Image(uiImage: item.image).resizable().scaledToFill()
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

    var body: some View {
        ScrollView {
            if vm.gallery.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "photo.stack").font(.system(size: 52)).foregroundStyle(.white.opacity(0.2))
                    Text("No images yet").foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity).padding(.top, 80)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 6)], spacing: 6) {
                    ForEach(vm.gallery) { item in
                        Image(uiImage: item.image).resizable().scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .bottomTrailing) {
                                if item.source == "generated" {
                                    Image(systemName: "wand.and.stars").font(.caption2)
                                        .padding(4).background(.ultraThinMaterial, in: Circle()).padding(4)
                                }
                            }
                            .onTapGesture { selected = item }
                    }
                }
                .padding(10)
            }
        }
        .sheet(item: $selected) { item in
            GalleryDetailView(item: item, onDelete: { vm.removeFromGallery(item); selected = nil })
        }
    }
}

// MARK: - Supporting Views

struct ProviderChip: View {
    let provider: AIProvider
    let isSelected: Bool
    let hasKey: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: provider.icon).font(.caption)
                Text(provider.rawValue.components(separatedBy: " ").first ?? provider.rawValue)
                    .font(.caption.bold())
                Circle().fill(hasKey ? Color.green : Color.orange).frame(width: 6, height: 6)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.white.opacity(0.08)),
                        in: Capsule())
        }.buttonStyle(.plain)
    }
}

struct StyleChip: View {
    let style: ImageStyle; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(style.label).font(.caption.bold()).padding(.horizontal, 14).padding(.vertical, 7)
                .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                .background(isSelected
                            ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.white.opacity(0.08)),
                            in: Capsule())
        }.buttonStyle(.plain)
    }
}

struct ErrorBanner: View {
    let message: String; let onDismiss: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(message).font(.caption).foregroundStyle(.white).lineLimit(3)
            Spacer()
            Button(action: onDismiss) { Image(systemName: "xmark").foregroundStyle(.white.opacity(0.6)) }
        }
        .padding(12)
        .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct GeneratedImageCard: View {
    let image: UIImage; let onSave: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            Image(uiImage: image).resizable().scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16)).shadow(color: .purple.opacity(0.4), radius: 16)
            HStack(spacing: 12) {
                Button(action: onSave) {
                    Label("Save", systemImage: "square.and.arrow.down").font(.subheadline.bold())
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Color.purple.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                ShareLink(item: Image(uiImage: image), preview: SharePreview("Ethereal Vision")) {
                    Label("Share", systemImage: "square.and.arrow.up").font(.subheadline.bold())
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Color.indigo.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct GalleryDetailView: View {
    let item: GalleryItem; let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(uiImage: item.image).resizable().scaledToFit()
                    if let prompt = item.prompt {
                        Text(prompt).font(.caption).foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal).multilineTextAlignment(.center)
                    }
                    if let provider = item.provider {
                        Text("Generated by \(provider)").font(.caption2).foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() }.foregroundStyle(.white) }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: Image(uiImage: item.image), preview: SharePreview("Ethereal Vision")) {
                        Image(systemName: "square.and.arrow.up")
                    }.foregroundStyle(.white)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - API Key Settings Sheet

struct APIKeySettingsView: View {
    var vm: StudioViewModel
    @State private var keys: [AIProvider: String] = [:]
    @State private var saved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("API keys are stored securely in the iOS Keychain on your device. They are never transmitted to World Class Scholars servers.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                ForEach(AIProvider.allCases) { provider in
                    Section(header: Label(provider.rawValue, systemImage: provider.icon)) {
                        SecureField("Paste API key…", text: Binding(
                            get: { keys[provider] ?? KeychainService.read(provider.keychainKey) ?? "" },
                            set: { keys[provider] = $0 }
                        ))
                        .font(.system(.body, design: .monospaced))

                        if KeychainService.hasKey(provider.keychainKey) {
                            Label("Key saved", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green).font(.caption)
                        }
                    }
                }

                Section {
                    Button("Save API Keys") {
                        for (provider, key) in keys where !key.isEmpty {
                            try? KeychainService.save(key, for: provider.keychainKey)
                        }
                        saved = true
                    }
                    .frame(maxWidth: .infinity).foregroundStyle(.white)
                    .listRowBackground(Color.indigo)
                }
            }
            .navigationTitle("API Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .alert("Keys Saved", isPresented: $saved) { Button("OK") { dismiss() } }
        }
    }
}
