// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// MusicPlayer — manages track selection, AVAudioPlayer, and progress updates.

import AVFoundation
import Observation

struct MusicTrack: Identifiable {
    let id = UUID()
    let title: String
    let composer: String
    let filename: String
    let ext: String
    let duration: String
}

@Observable
@MainActor
final class MusicPlayer {
    var tracks: [MusicTrack] = MusicPlayer.buildPlaylist()
    var currentIndex = 0
    var isPlaying = false
    var progress: Double = 0
    var elapsed: TimeInterval = 0
    var totalDuration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    var currentTrack: MusicTrack { tracks[currentIndex] }

    var elapsedFormatted: String { format(elapsed) }
    var durationFormatted: String { format(totalDuration) }

    // MARK: - Playback Control

    func togglePlayPause() {
        isPlaying ? pause() : play(index: currentIndex)
    }

    func play(index: Int) {
        currentIndex = index
        loadTrack(tracks[index])
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func next() {
        play(index: (currentIndex + 1) % tracks.count)
    }

    func previous() {
        play(index: (currentIndex - 1 + tracks.count) % tracks.count)
    }

    func seek(to fraction: Double) {
        guard let player else { return }
        player.currentTime = player.duration * fraction
        elapsed = player.currentTime
    }

    // MARK: - Private

    private func loadTrack(_ track: MusicTrack) {
        stopTimer()
        player?.stop()

        configureAudioSession()

        guard let url = Bundle.main.url(forResource: track.filename, withExtension: track.ext) else {
            // File not bundled yet — still advances the UI and auto-advances playlist.
            isPlaying = false
            totalDuration = 0
            elapsed = 0
            progress = 0
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            totalDuration = player?.duration ?? 0
            startTimer()
        } catch {
            isPlaying = false
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let player, player.isPlaying else { return }
        elapsed = player.currentTime
        progress = totalDuration > 0 ? elapsed / totalDuration : 0
        if !player.isPlaying { next() }
    }

    private func format(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Playlist

    private static func buildPlaylist() -> [MusicTrack] {
        [
            MusicTrack(title: "Nocturne Op.9 No.2", composer: "Frédéric Chopin",
                       filename: "chopin_nocturne_op9_no2", ext: "m4a", duration: "4:33"),
            MusicTrack(title: "Clair de Lune", composer: "Claude Debussy",
                       filename: "debussy_clair_de_lune", ext: "m4a", duration: "5:01"),
            MusicTrack(title: "Gymnopédie No.1", composer: "Erik Satie",
                       filename: "satie_gymnopedie_1", ext: "m4a", duration: "3:12"),
            MusicTrack(title: "Moonlight Sonata", composer: "Ludwig van Beethoven",
                       filename: "beethoven_moonlight", ext: "m4a", duration: "6:02"),
            MusicTrack(title: "Prelude in C Major", composer: "Johann Sebastian Bach",
                       filename: "bach_prelude_c_major", ext: "m4a", duration: "2:28"),
            MusicTrack(title: "Liebestraum No.3", composer: "Franz Liszt",
                       filename: "liszt_liebestraum_3", ext: "m4a", duration: "4:46"),
            MusicTrack(title: "Romance in F Major", composer: "Robert Schumann",
                       filename: "schumann_romance", ext: "m4a", duration: "3:55"),
        ]
    }
}
