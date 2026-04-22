// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Veiled ambient playback — Chopin nocturnes drift beneath the canvas.

import AVFoundation
import Combine

class ShadowAudio: ObservableObject {
    @Published var isPlaying = false

    private var player: AVAudioPlayer?

    func startEtherealMusic() {
        configureAudioSession()
        loadAndPlay(resource: "chopin_nocturne", ext: "m4a")
    }

    func playVeiledMusic() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
    }

    func stopMusic() {
        player?.stop()
        isPlaying = false
    }

    // MARK: - Private

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func loadAndPlay(resource: String, ext: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            // File not yet bundled — silently no-op until asset is added in Xcode.
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.55
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            // Audio initialisation failed; non-critical for therapy session.
        }
    }
}
