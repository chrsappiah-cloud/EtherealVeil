// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// MusicPlayer — AVPlayer streaming with MusicKit fallback. No bundled files needed.

import AVFoundation
import MusicKit
import Observation

struct MusicTrack: Identifiable, Equatable {
    let id: UUID
    let title: String
    let composer: String
    let filename: String            // bundled resource name (optional)
    let ext: String
    let durationLabel: String
    var streamURL: URL?             // populated by MusicKit search when available
    var isFavorite: Bool = false
}

@Observable
@MainActor
final class MusicPlayer: NSObject {

    // Published state
    var tracks: [MusicTrack] = MusicPlayer.buildPlaylist()
    var currentIndex: Int = 0
    var isPlaying: Bool = false
    var progress: Double = 0
    var elapsed: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var isLoadingTrack: Bool = false
    var errorMessage: String?
    var musicKitAuthorized: Bool = false

    // AVPlayer
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var playerItemObservation: NSKeyValueObservation?

    var currentTrack: MusicTrack { tracks[currentIndex] }
    var elapsedFormatted: String { format(elapsed) }
    var durationFormatted: String { format(totalDuration) }

    override init() {
        super.init()
        configureAudioSession()
        Task { await requestMusicKitAuth() }
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

        Task {
            // 1. Try bundled file first
            if let url = Bundle.main.url(forResource: track.filename, withExtension: track.ext) {
                await startPlayer(with: url)
                return
            }

            // 2. Try MusicKit stream URL (requires Apple Music subscription)
            if musicKitAuthorized, let url = track.streamURL {
                await startPlayer(with: url)
                return
            }

            // 3. Search MusicKit catalog and populate stream URL
            if musicKitAuthorized {
                if let url = await searchMusicKit(track: track) {
                    tracks[currentIndex].streamURL = url
                    await startPlayer(with: url)
                    return
                }
            }

            // 4. Graceful degradation — show info, no crash
            isLoadingTrack = false
            isPlaying = false
            errorMessage = "'\(track.title)' not available. Bundle the .m4a file or subscribe to Apple Music."
        }
    }

    private func startPlayer(with url: URL) async {
        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        player = avPlayer

        // Observe duration when ready
        playerItemObservation = item.observe(\.status) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if item.status == .readyToPlay {
                    self.totalDuration = item.duration.seconds.isNaN ? 0 : item.duration.seconds
                    self.isLoadingTrack = false
                }
            }
        }

        // Periodic progress
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, let player = self.player else { return }
                self.elapsed = time.seconds.isNaN ? 0 : time.seconds
                self.progress = self.totalDuration > 0 ? self.elapsed / self.totalDuration : 0
                // Auto-advance
                if player.currentItem?.status == .readyToPlay,
                   abs(self.elapsed - self.totalDuration) < 1,
                   self.totalDuration > 0 {
                    self.next()
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
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

    // MARK: - MusicKit

    private func requestMusicKitAuth() async {
        let status = await MusicAuthorization.request()
        musicKitAuthorized = status == .authorized
    }

    private func searchMusicKit(track: MusicTrack) async -> URL? {
        var request = MusicCatalogSearchRequest(
            term: "\(track.title) \(track.composer)",
            types: [Song.self]
        )
        request.limit = 1

        guard let response = try? await request.response(),
              let song = response.songs.first,
              let previewURL = song.previewAssets?.first?.url else {
            return nil
        }
        return previewURL
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

    // MARK: - Static Playlist

    static func buildPlaylist() -> [MusicTrack] {
        [
            MusicTrack(id: UUID(), title: "Nocturne Op.9 No.2",    composer: "Frédéric Chopin",
                       filename: "chopin_nocturne_op9_no2",  ext: "m4a", durationLabel: "4:33"),
            MusicTrack(id: UUID(), title: "Clair de Lune",         composer: "Claude Debussy",
                       filename: "debussy_clair_de_lune",    ext: "m4a", durationLabel: "5:01"),
            MusicTrack(id: UUID(), title: "Gymnopédie No.1",       composer: "Erik Satie",
                       filename: "satie_gymnopedie_1",       ext: "m4a", durationLabel: "3:12"),
            MusicTrack(id: UUID(), title: "Moonlight Sonata Mvt.1", composer: "Ludwig van Beethoven",
                       filename: "beethoven_moonlight",      ext: "m4a", durationLabel: "6:02"),
            MusicTrack(id: UUID(), title: "Prelude in C Major",    composer: "J.S. Bach",
                       filename: "bach_prelude_c_major",     ext: "m4a", durationLabel: "2:28"),
            MusicTrack(id: UUID(), title: "Liebestraum No.3",      composer: "Franz Liszt",
                       filename: "liszt_liebestraum_3",      ext: "m4a", durationLabel: "4:46"),
            MusicTrack(id: UUID(), title: "Romance Op.28 No.2",    composer: "Robert Schumann",
                       filename: "schumann_romance",         ext: "m4a", durationLabel: "3:55"),
            MusicTrack(id: UUID(), title: "Arabesque No.1",        composer: "Claude Debussy",
                       filename: "debussy_arabesque_1",      ext: "m4a", durationLabel: "4:12"),
            MusicTrack(id: UUID(), title: "Ballade No.1 Op.23",    composer: "Frédéric Chopin",
                       filename: "chopin_ballade_1",         ext: "m4a", durationLabel: "8:31"),
        ]
    }
}
