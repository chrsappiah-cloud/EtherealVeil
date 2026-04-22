// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Classical music player — haunting nocturnes for therapeutic recall.

import SwiftUI
import AVFoundation

struct MusicTab: View {
    @State private var player = MusicPlayer()

    var body: some View {
        ZStack {
            etherealBackground

            VStack(spacing: 0) {
                header
                albumArt
                trackInfo
                progressBar
                controls
                playlist
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Subviews

    private var etherealBackground: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.05, green: 0.02, blue: 0.15)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        Text("Ethereal Soundscapes")
            .font(.title2.bold())
            .foregroundStyle(
                LinearGradient(colors: [.white, .purple.opacity(0.8)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .padding(.top, 20)
            .padding(.bottom, 12)
    }

    private var albumArt: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.indigo.opacity(0.6), Color.purple.opacity(0.3), .black],
                        center: .center, startRadius: 10, endRadius: 120
                    )
                )
                .frame(width: 220, height: 220)
                .shadow(color: .purple.opacity(0.5), radius: 30)
                .rotationEffect(.degrees(player.isPlaying ? 360 : 0))
                .animation(
                    player.isPlaying
                        ? .linear(duration: 12).repeatForever(autoreverses: false)
                        : .default,
                    value: player.isPlaying
                )

            Image(systemName: "music.quarternote.3")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 16)
    }

    private var trackInfo: some View {
        VStack(spacing: 4) {
            Text(player.currentTrack.title)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(player.currentTrack.composer)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.bottom, 16)
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            Slider(value: $player.progress, in: 0...1) { editing in
                if !editing { player.seek(to: player.progress) }
            }
            .tint(.purple)

            HStack {
                Text(player.elapsedFormatted)
                Spacer()
                Text(player.durationFormatted)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.bottom, 12)
    }

    private var controls: some View {
        HStack(spacing: 36) {
            Button { player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Button { player.togglePlayPause() } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 64, height: 64)
                        .shadow(color: .purple.opacity(0.6), radius: 12)

                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }

            Button { player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.bottom, 24)
    }

    private var playlist: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(Array(player.tracks.enumerated()), id: \.offset) { index, track in
                    PlaylistRow(
                        track: track,
                        isActive: index == player.currentIndex,
                        action: { player.play(index: index) }
                    )
                }
            }
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct PlaylistRow: View {
    let track: MusicTrack
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isActive ? "waveform" : "music.note")
                    .foregroundStyle(isActive ? .purple : .white.opacity(0.4))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline)
                        .foregroundStyle(isActive ? .white : .white.opacity(0.7))
                    Text(track.composer)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Text(track.durationLabel)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isActive ? Color.purple.opacity(0.15) : .clear)
        }
        .buttonStyle(.plain)
    }
}
