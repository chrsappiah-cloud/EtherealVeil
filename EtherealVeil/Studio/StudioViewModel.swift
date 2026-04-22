// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// StudioViewModel — real multi-provider image generation, voice, SwiftData gallery.

import SwiftUI
import PhotosUI
import Speech
import AVFoundation
import SwiftData
import Observation

// MARK: - ViewModel

@Observable
@MainActor
final class StudioViewModel {

    // Generation
    var isGenerating = false
    var latestGeneratedImage: UIImage?
    var generationError: String?
    var selectedProvider: AIProvider = .stabilityAI
    var selectedSize: ImageSize = .square1024

    // Voice
    var isRecording = false
    var voiceTranscript = ""

    // In-memory gallery (backed by SwiftData via sync)
    var gallery: [GalleryItem] = []

    // UI state
    var showCamera = false
    var showAPIKeySettings = false

    // SwiftData context injected from the environment
    var modelContext: ModelContext?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    // MARK: - API Key helpers

    var currentAPIKeyIsSet: Bool {
        KeychainService.hasKey(selectedProvider.keychainKey)
    }

    func saveAPIKey(_ key: String, for provider: AIProvider) {
        try? KeychainService.save(key, for: provider.keychainKey)
    }

    // MARK: - Image Generation

    func generateImage(prompt: String, style: ImageStyle) {
        let trimmed = prompt.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        guard currentAPIKeyIsSet else {
            generationError = GenerationError.noAPIKey(selectedProvider.rawValue).localizedDescription
            showAPIKeySettings = true
            return
        }

        isGenerating = true
        generationError = nil

        let service = selectedProvider.makeService()
        let size = selectedSize

        Task {
            do {
                let image = try await service.generate(prompt: trimmed, style: style, size: size)
                latestGeneratedImage = image
                persistImage(image, prompt: trimmed, style: style, source: "generated")
            } catch let err as GenerationError {
                generationError = err.localizedDescription
            } catch {
                generationError = error.localizedDescription
            }
            isGenerating = false
        }
    }

    // MARK: - Voice Recording

    func toggleVoiceRecording(updatePrompt: @escaping (String) -> Void) {
        isRecording ? stopRecording() : startRecording(updatePrompt: updatePrompt)
    }

    private func startRecording(updatePrompt: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard status == .authorized else {
                    self.generationError = "Speech recognition not authorized. Enable in Settings → Privacy."
                    return
                }
                self.requestMicrophoneAndBegin(updatePrompt: updatePrompt)
            }
        }
    }

    private func requestMicrophoneAndBegin(updatePrompt: @escaping (String) -> Void) {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard granted else {
                    self.generationError = "Microphone access denied. Enable in Settings → Privacy."
                    return
                }
                self.beginAudioCapture(updatePrompt: updatePrompt)
            }
        }
    }

    private func beginAudioCapture(updatePrompt: @escaping (String) -> Void) {
        let engine = AVAudioEngine()
        audioEngine = engine

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        recognitionRequest = request

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        let node = engine.inputNode
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        do {
            try engine.start()
        } catch {
            generationError = "Audio engine failed to start: \(error.localizedDescription)"
            return
        }

        isRecording = true
        voiceTranscript = ""

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let text = result?.bestTranscription.formattedString {
                    self.voiceTranscript = text
                    updatePrompt(text)
                }
                if result?.isFinal == true || error != nil {
                    self.stopRecording()
                }
            }
        }
    }

    private func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Gallery

    func addToGallery(_ image: UIImage, source: String = "uploaded") {
        persistImage(image, prompt: nil, style: nil, source: source)
    }

    func removeFromGallery(_ item: GalleryItem) {
        gallery.removeAll { $0.id == item.id }
        if let ctx = modelContext {
            let id = item.id
            let fetch = FetchDescriptor<PersistedImage>(
                predicate: #Predicate { $0.id == id }
            )
            if let found = try? ctx.fetch(fetch).first {
                ctx.delete(found)
                try? ctx.save()
            }
        }
    }

    func loadGalleryFromDatabase() {
        guard let ctx = modelContext else { return }
        let fetch = FetchDescriptor<PersistedImage>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let items = try? ctx.fetch(fetch) else { return }
        gallery = items.compactMap { persisted -> GalleryItem? in
            guard let image = persisted.uiImage else { return nil }
            return GalleryItem(
                id: persisted.id,
                image: image,
                source: persisted.sourceRaw,
                prompt: persisted.prompt,
                provider: persisted.providerRaw,
                createdAt: persisted.createdAt
            )
        }
    }

    func loadPickedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                addToGallery(image, source: "uploaded")
            }
        }
    }

    // MARK: - Private persistence

    private func persistImage(_ image: UIImage, prompt: String?, style: ImageStyle?, source: String) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }

        let item = GalleryItem(
            id: UUID(),
            image: image,
            source: source,
            prompt: prompt,
            provider: source == "generated" ? selectedProvider.rawValue : nil,
            createdAt: .now
        )
        gallery.insert(item, at: 0)

        if let ctx = modelContext {
            let record = PersistedImage(
                imageData: data,
                prompt: prompt,
                provider: source == "generated" ? selectedProvider.rawValue : nil,
                style: style,
                source: source
            )
            ctx.insert(record)
            try? ctx.save()
        }
    }
}
