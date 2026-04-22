// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Therapeutic iOS app for dementia patients — MVVM entry point.

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var whisperVoice = WhisperVoice()
    @StateObject private var shadowAudio = ShadowAudio()
    @StateObject private var veilViewModel = VeilViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                etherealBackground

                VStack(spacing: 24) {
                    headerTitle

                    VeilCanvas(viewModel: veilViewModel)
                        .frame(height: 450)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .shadow(color: .purple.opacity(0.6), radius: 25)

                    controlButtons
                }
                .padding()
            }
            .onAppear {
                shadowAudio.startEtherealMusic()
                whisperVoice.speak("Enter the veil. Create from within.")
            }
        }
        .navigationViewStyle(.stack)
    }

    private var etherealBackground: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.9),
                Color.indigo.opacity(0.7),
                Color.purple.opacity(0.5)
            ]),
            center: .center,
            startRadius: 50,
            endRadius: 600
        )
        .ignoresSafeArea()
    }

    private var headerTitle: some View {
        VStack(spacing: 6) {
            Text("Ethereal Veil")
                .font(.largeTitle.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(white: 0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .purple.opacity(0.8), radius: 15)

            Text("World Class Scholars")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button {
                shadowAudio.playVeiledMusic()
            } label: {
                Label("Awaken Shadows", systemImage: "music.note")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)

            Button {
                whisperVoice.speak("Unveil hidden colors. Your touch awakens memories.")
            } label: {
                Label("Whisper Secrets", systemImage: "waveform")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.purple)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
