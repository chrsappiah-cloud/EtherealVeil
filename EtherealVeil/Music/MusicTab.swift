// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// Ethereal Veil™ is a trademark of World Class Scholars.
// Unauthorized reproduction or distribution is prohibited.
// MusicTab is no longer a standalone tab. This file is kept as a
// reusable playlist view that can be presented as a sheet from
// the drawing or painting tabs if needed in the future.

import SwiftUI

struct PlaylistSheet: View {
    var player: MusicPlayer
    var favoriteTrackIDs: Set<String> = []
    var onToggleFavorite: (MusicTrack) -> Void = { _ in }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(Array(player.tracks.enumerated()), id: \.offset) { index, track in
                        PlaylistRow(
                            track: track,
                            isActive: index == player.currentIndex,
                            isFavorite: favoriteTrackIDs.contains(StudioStore.trackIdentifier(for: track)),
                            onToggleFavorite: { onToggleFavorite(track) },
                            action: { player.play(index: index) }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            .background(GoldStudioTheme.background)
            .navigationTitle("Playlist")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

struct PlaylistRow: View {
    let track: MusicTrack
    let isActive: Bool
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(.plain)

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? AnyShapeStyle(GoldStudioTheme.sparkle) : AnyShapeStyle(Color.white.opacity(0.45)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color(red: 0.88, green: 0.71, blue: 0.33).opacity(0.18) : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? AnyShapeStyle(GoldStudioTheme.sparkle.opacity(0.5)) : AnyShapeStyle(Color.clear), lineWidth: 1)
                )
        )
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Image(systemName: isActive ? "waveform" : "music.note")
                .foregroundStyle(isActive ? AnyShapeStyle(GoldStudioTheme.sparkle) : AnyShapeStyle(Color.white.opacity(0.4)))
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
    }
}
