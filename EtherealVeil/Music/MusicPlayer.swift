// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// MusicPlayer — AVPlayer-based royalty-free classical music (CC0 Musopen, archive.org MP3).

import AVFoundation
import Observation

struct MusicTrack: Identifiable, Equatable {
    let id: UUID
    let title: String
    let composer: String
    let durationLabel: String
    var audioURL: URL?
    var isFavorite: Bool = false
}

@Observable
@MainActor
final class MusicPlayer: NSObject {

    var tracks: [MusicTrack] = MusicPlayer.buildPlaylist()
    var currentIndex: Int = 0
    var isPlaying: Bool = false
    var progress: Double = 0
    var elapsed: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var isLoadingTrack: Bool = false
    var errorMessage: String?

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var playerItemObservation: NSKeyValueObservation?

    var currentTrack: MusicTrack { tracks[currentIndex] }
    var elapsedFormatted: String { format(elapsed) }
    var durationFormatted: String { format(totalDuration) }

    override init() {
        super.init()
        configureAudioSession()
    }

    // MARK: - Playback Control

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else if player != nil {
            player?.play()
            isPlaying = true
        } else {
            play(index: currentIndex)
        }
    }

    func play(index: Int) {
        guard index >= 0, index < tracks.count else { return }
        currentIndex = index
        stopCurrentPlayer()
        loadAndPlay(tracks[index])
    }

    func stop() {
        stopCurrentPlayer()
    }

    func next() { play(index: (currentIndex + 1) % tracks.count) }
    func previous() { play(index: (currentIndex - 1 + tracks.count) % tracks.count) }

    func seek(to fraction: Double) {
        guard let player, totalDuration > 0 else { return }
        let time = CMTime(seconds: totalDuration * fraction, preferredTimescale: 600)
        player.seek(to: time)
    }

    func toggleFavorite(at index: Int) {
        tracks[index].isFavorite.toggle()
    }

    // MARK: - Load & Play

    private func loadAndPlay(_ track: MusicTrack) {
        isLoadingTrack = true
        errorMessage = nil

        if let url = track.audioURL {
            startPlayer(with: url)
            return
        }

        isLoadingTrack = false
        isPlaying = false
        errorMessage = "'\(track.title)' is not available."
    }

    private func startPlayer(with url: URL) {
        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        player = avPlayer

        playerItemObservation = item.observe(\.status) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.totalDuration = item.duration.seconds.isNaN ? 0 : item.duration.seconds
                    self.isLoadingTrack = false
                case .failed:
                    self.isLoadingTrack = false
                    self.isPlaying = false
                    self.errorMessage = "Could not load '\(self.currentTrack.title)'."
                default:
                    break
                }
            }
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.elapsed = time.seconds.isNaN ? 0 : time.seconds
                self.progress = self.totalDuration > 0 ? self.elapsed / self.totalDuration : 0
            }
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime, object: item
        )

        avPlayer.play()
        isPlaying = true
    }

    @objc private func playerDidFinish() { Task { @MainActor in next() } }

    private func stopCurrentPlayer() {
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        timeObserver = nil
        playerItemObservation?.invalidate()
        playerItemObservation = nil
        player?.pause()
        player = nil
        elapsed = 0
        progress = 0
        totalDuration = 0
        isPlaying = false
    }

    // MARK: - Helpers

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
        try? session.setActive(true)
    }

    private func format(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }

    // MARK: - Playlist (Musopen CC0 recordings via archive.org — MP3 format)

    static func buildPlaylist() -> [MusicTrack] {
        let base = "https://archive.org/download/musopen-chopin/"
        return [
            MusicTrack(id: UUID(), title: "Nocturne Op.9 No.2",
                       composer: "Chopin — Musopen CC0", durationLabel: "4:33",
                       audioURL: URL(string: base + "Nocturne%20Op.%209%20no.%202%20in%20E%20flat%20major.mp3")),
            MusicTrack(id: UUID(), title: "Ballade No.1 Op.23",
                       composer: "Chopin — Musopen CC0", durationLabel: "8:31",
                       audioURL: URL(string: base + "Ballade%20no.%201%20-%20Op.%2023.mp3")),
            MusicTrack(id: UUID(), title: "Waltz Op.64 No.2",
                       composer: "Chopin — Musopen CC0", durationLabel: "3:40",
                       audioURL: URL(string: base + "Waltz%20Op.%2064%20no.%202%20in%20C%20sharp%20minor.mp3")),
            MusicTrack(id: UUID(), title: "Minute Waltz Op.64 No.1",
                       composer: "Chopin — Musopen CC0", durationLabel: "1:50",
                       audioURL: URL(string: base + "Waltz%20Op.%2064%20no.%201%20in%20D%20flat%20major.mp3")),
            MusicTrack(id: UUID(), title: "Fantasie Impromptu Op.66",
                       composer: "Chopin — Musopen CC0", durationLabel: "5:20",
                       audioURL: URL(string: base + "Fantasie%20Impromptu%20Op.%2066.mp3")),
            MusicTrack(id: UUID(), title: "Waltz Op.34 No.2",
                       composer: "Chopin — Musopen CC0", durationLabel: "5:10",
                       audioURL: URL(string: base + "Waltz%20Op.%2034%20no.%202%20in%20A%20minor.mp3")),
            MusicTrack(id: UUID(), title: "Ballade No.4 Op.52",
                       composer: "Chopin — Musopen CC0", durationLabel: "11:10",
                       audioURL: URL(string: base + "Ballade%20no.%204%20-%20Op.%2052.mp3")),
            MusicTrack(id: UUID(), title: "Grande Valse Brillante Op.18",
                       composer: "Chopin — Musopen CC0", durationLabel: "5:25",
                       audioURL: URL(string: base + "Grande%20Valse%20Brilliante%2C%20Op.%2018%20in%20E%20Flat%20Major.mp3")),
            MusicTrack(id: UUID(), title: "Waltz Op.34 No.3",
                       composer: "Chopin — Musopen CC0", durationLabel: "2:15",
                       audioURL: URL(string: base + "Waltz%20Op.%2034%20no.%203%20in%20F%20major.mp3")),
        ]
    }
}
