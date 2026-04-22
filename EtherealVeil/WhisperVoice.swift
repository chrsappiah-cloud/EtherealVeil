// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Gentle voice guidance — a soft whisper to surface forgotten memories.

import AVFoundation
import Combine

class WhisperVoice: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .word) }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.4
        utterance.pitchMultiplier = 0.9
        utterance.volume = 0.8
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")

        synthesizer.speak(utterance)
    }

    func silence() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
