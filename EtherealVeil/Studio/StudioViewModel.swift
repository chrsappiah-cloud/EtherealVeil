// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// StudioViewModel — voice recording, image generation, gallery management.

import SwiftUI
import PhotosUI
import Speech
import AVFoundation
import Observation

// MARK: - Supporting Models

enum ImageStyle: String, CaseIterable, Identifiable {
    case ethereal, watercolor, oilPainting, sketch, impressionist, abstract

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ethereal:      "Ethereal"
        case .watercolor:    "Watercolor"
        case .oilPainting:   "Oil Paint"
        case .sketch:        "Sketch"
        case .impressionist: "Impressionist"
        case .abstract:      "Abstract"
        }
    }

    var stylePromptSuffix: String {
        switch self {
        case .ethereal:      "in an ethereal, dreamlike style with soft purple hues"
        case .watercolor:    "in a delicate watercolor painting style"
        case .oilPainting:   "as a rich oil painting with impasto texture"
        case .sketch:        "as a detailed pencil sketch"
        case .impressionist: "in an impressionist style with visible brushstrokes"
        case .abstract:      "as an abstract expressionist painting"
        }
    }
}

enum GallerySource { case generated, uploaded }

struct GalleryItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let source: GallerySource
    let prompt: String?
    let createdAt = Date()
}

// MARK: - ViewModel

@Observable
@MainActor
final class StudioViewModel {
    // Generation
    var isGenerating = false
    var latestGeneratedImage: UIImage?
    var generationError: String?

    // Voice
    var isRecording = false
    var voiceTranscript = ""

    // Gallery
    var gallery: [GalleryItem] = []

    // UI state
    var showCamera = false

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    // MARK: - Image Generation

    func generateImage(prompt: String, style: ImageStyle) {
        guard !prompt.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isGenerating = true
        generationError = nil

        // Build full prompt with style suffix
        let fullPrompt = "\(prompt), \(style.stylePromptSuffix)"

        Task {
            do {
                let image = try await callImageGenerationAPI(prompt: fullPrompt)
                latestGeneratedImage = image
                saveToGallery(image, prompt: fullPrompt)
            } catch {
                generationError = error.localizedDescription
            }
            isGenerating = false
        }
    }

    // Replace with your actual API (OpenAI DALL·E, Stability AI, etc.)
    private func callImageGenerationAPI(prompt: String) async throws -> UIImage {
        // Placeholder — renders a gradient canvas with the prompt as a watermark.
        // Wire in your API key + endpoint here.
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.15, green: 0.05, blue: 0.35, alpha: 1).cgColor,
                    UIColor(red: 0.35, green: 0.1, blue: 0.6, alpha: 1).cgColor,
                    UIColor(red: 0.05, green: 0.2, blue: 0.5, alpha: 1).cgColor,
                ] as CFArray,
                locations: [0, 0.5, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Draw placeholder label
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.7),
            ]
            let text = "AI Image Preview\n\(prompt.prefix(60))…"
            let rect = CGRect(x: 20, y: size.height / 2 - 40, width: size.width - 40, height: 80)
            (text as NSString).draw(in: rect, withAttributes: attrs)
        }
        // Simulate network latency
        try await Task.sleep(for: .seconds(1.5))
        return image
    }

    // MARK: - Voice Recording

    func toggleVoiceRecording(updatePrompt: @escaping (String) -> Void) {
        isRecording ? stopRecording() : startRecording(updatePrompt: updatePrompt)
    }

    private func startRecording(updatePrompt: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self, status == .authorized else { return }
                self.beginAudioCapture(updatePrompt: updatePrompt)
            }
        }
    }

    private func beginAudioCapture(updatePrompt: @escaping (String) -> Void) {
        let engine = AVAudioEngine()
        audioEngine = engine
        let request = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest = request
        request.shouldReportPartialResults = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        let node = engine.inputNode
        let format = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        try? engine.start()
        isRecording = true

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let text = result?.bestTranscription.formattedString {
                    self.voiceTranscript = text
                    updatePrompt(text)
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
    }

    // MARK: - Gallery

    func saveToGallery(_ image: UIImage, prompt: String? = nil) {
        let item = GalleryItem(image: image, source: .generated, prompt: prompt)
        gallery.insert(item, at: 0)
    }

    func addToGallery(_ image: UIImage) {
        let item = GalleryItem(image: image, source: .uploaded, prompt: nil)
        gallery.insert(item, at: 0)
    }

    func removeFromGallery(_ item: GalleryItem) {
        gallery.removeAll { $0.id == item.id }
    }

    func loadPickedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                addToGallery(image)
            }
        }
    }
}
