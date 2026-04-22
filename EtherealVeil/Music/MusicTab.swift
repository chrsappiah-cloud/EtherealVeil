// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// MusicTab is no longer a standalone tab. This file is kept as a
// reusable playlist view that can be presented as a sheet from
// the drawing or painting tabs if needed in the future.

import SwiftUI

struct PlaylistSheet: View {
    var player: MusicPlayer

    var body: some View {
        NavigationStack {
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
                .padding(.horizontal, 12)
            }
            .background(Color.black)
            .navigationTitle("Playlist")
            .navigationBarTitleDisplayMode(.inline)
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
                    .foregroundStyle(isActive ? .cyan : .white.opacity(0.4))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(isActive ? .white : .white.opacity(0.7))
                    Text(track.composer)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Text(track.durationLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.cyan.opacity(0.12) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}
