// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson

import SwiftUI

struct ContentView: View {
    @State private var musicPlayer = MusicPlayer()
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Canvas area fills the screen behind the tab bar
            Group {
                switch selectedTab {
                case 0:  DrawingTab(musicPlayer: musicPlayer)
                case 1:  PaintingTab(musicPlayer: musicPlayer)
                default: DrawingTab(musicPlayer: musicPlayer)
                }
            }
            .ignoresSafeArea(edges: .bottom)

            // Floating futuristic tab bar + music strip
            VStack(spacing: 0) {
                musicStrip
                tabBar
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { _, _ in
            if !musicPlayer.isPlaying && musicPlayer.tracks.contains(where: { $0.audioURL != nil }) {
                musicPlayer.togglePlayPause()
            }
        }
    }

    // MARK: - Music Strip (compact now-playing above tab bar)

    private var musicStrip: some View {
        HStack(spacing: 12) {
            // Animated waveform indicator
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(neonGradient)
                        .frame(width: 3, height: musicPlayer.isPlaying ? CGFloat.random(in: 6...16) : 4)
                        .animation(
                            musicPlayer.isPlaying
                                ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(i) * 0.1)
                                : .default,
                            value: musicPlayer.isPlaying
                        )
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(musicPlayer.currentTrack.title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(musicPlayer.currentTrack.composer)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            // Progress arc
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: musicPlayer.progress)
                    .stroke(neonGradient, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 22, height: 22)

            Button { musicPlayer.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Button { musicPlayer.togglePlayPause() } label: {
                Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(neonGradient).shadow(color: .cyan.opacity(0.5), radius: 8)
                    )
            }

            Button { musicPlayer.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(colors: [.cyan.opacity(0.3), .purple.opacity(0.2), .clear],
                                           startPoint: .leading, endPoint: .trailing),
                            lineWidth: 0.5
                        )
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Futuristic Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "pencil.tip.crop.circle", label: "Draw", index: 0)
            tabButton(icon: "paintbrush.pointed.fill", label: "Paint", index: 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(colors: [.cyan.opacity(0.4), .purple.opacity(0.4)],
                                           startPoint: .leading, endPoint: .trailing),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        )
        .padding(.horizontal, 60)
        .padding(.bottom, 8)
    }

    private func tabButton(icon: String, label: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { selectedTab = index }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selectedTab == index {
                        Circle()
                            .fill(neonGradient)
                            .frame(width: 42, height: 42)
                            .shadow(color: .cyan.opacity(0.6), radius: 12)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: selectedTab == index ? .bold : .regular))
                        .foregroundStyle(selectedTab == index ? .white : .white.opacity(0.4))
                }
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selectedTab == index ? .white : .white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var neonGradient: LinearGradient {
        LinearGradient(colors: [.cyan, .blue, .purple],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview { ContentView() }
