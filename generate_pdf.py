import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import textwrap
import re

new_name = "Ethereal Veil"
title = f"World Class Scholars - {new_name}"
subtitle = "Therapeutic iOS App - Updated Boilerplate SwiftUI Code"
description = f"""
Overview: {new_name} is a mysterious, therapeutic iOS app for dementia patients. Features ethereal digital painting/drawing with haunting classical music and whispering voice guidance. Hyperrealistic futuristic UI invites exploration of forgotten memories.

Key Features:
- Infinite Canvas for touch drawing/painting (mysterious brush trails)
- Ethereal classical music (Chopin nocturnes, veiled playback)
- Voice whispers: 'Unveil your inner world', 'Let colors emerge from shadows'
- Neumorphic, holographic UI with subtle glows and veils
- © World Class Scholars 2026 - Bridging equity in dementia care.
"""

content_parts = [
    "# App Structure\nMVVM: ContentView orchestrates mystery; VeilCanvas reveals art; WhisperVoice for guidance; ShadowAudio for music.\nMysterious palette: midnight blues, silver veils, glowing purples.",

    "## Core Files\n### EtherealVeilApp.swift\n```swift\n@main\nstruct EtherealVeilApp: App {\n    var body: some Scene {\n        WindowGroup {\n            ContentView()\n        }\n    }\n}\n```",

    f"### ContentView.swift\n```swift\nimport SwiftUI\nimport AVFoundation\n\nstruct ContentView: View {{\n    @StateObject private var whisperVoice = WhisperVoice()\n    @StateObject private var shadowAudio = ShadowAudio()\n    @StateObject private var veilViewModel = VeilViewModel()\n    \n    var body: some View {{\n        NavigationView {{\n            ZStack {{\n                // Ethereal veiled gradient\n                RadialGradient(gradient: Gradient(colors: [\n                    Color.black.opacity(0.9),\n                    Color.indigo.opacity(0.7),\n                    Color.purple.opacity(0.5)\n                ]), center: .center, startRadius: 50, endRadius: 600)\n                .ignoresSafeArea()\n                \n                VStack {{\n                    Text(\"{new_name}\")\n                        .font(.title.bold())\n                        .foregroundStyle(.silver)\n                        .shadow(color: .purple.opacity(0.8), radius: 15)\n                    \n                    VeilCanvas(viewModel: veilViewModel)\n                        .frame(height: 450)\n                        .background(.ultraThinMaterial)\n                        .clipShape(RoundedRectangle(cornerRadius: 30))\n                        .shadow(color: .purple.opacity(0.6), radius: 25)\n                    \n                    HStack(spacing: 20) {{\n                        Button(\"Awaken Shadows\") {{ shadowAudio.playVeiledMusic() }}\n                            .buttonStyle(.borderedProminent)\n                            .tint(.indigo)\n                        Button(\"Whisper Secrets\") {{ \n                            whisperVoice.speak(\"Unveil hidden colors. Your touch awakens memories.\") \n                        }}\n                            .buttonStyle(.bordered)\n                    }}\n                }}\n                .padding()\n            }}\n            .onAppear {{\n                shadowAudio.startEtherealMusic()\n                whisperVoice.speak(\"Enter the veil. Create from within.\")\n            }}\n        }}\n    }}\n}}\n```",

    "### VeilCanvas.swift\n```swift\nstruct VeilCanvas: View {\n    @ObservedObject var viewModel: VeilViewModel\n    \n    var body: some View {\n        Canvas { context, size in\n            for trail in viewModel.glowTrails {\n                context.stroke(trail.path, with: .linearGradient(\n                    Gradient(colors: [trail.color.opacity(0.3), trail.color]),\n                    startPoint: .leading, endPoint: .trailing\n                ), lineWidth: trail.thickness)\n            }\n        }\n        .gesture(DragGesture().onChanged { value in\n            viewModel.addGlow(value.location)\n        })\n        .drawingGroup(opaque: false)\n    }\n}\n```",

    "### VeilViewModel.swift\n```swift\nclass VeilViewModel: ObservableObject {\n    @Published var glowTrails: [GlowTrail] = []\n    private var currentTrailPoints: [CGPoint] = []\n    \n    func addGlow(_ point: CGPoint) {\n        currentTrailPoints.append(point)\n        let path = Path { p in p.addLines(currentTrailPoints) }\n        glowTrails.append(GlowTrail(path: path, color: .cyan, thickness: 12))\n    }\n}\nstruct GlowTrail: Identifiable {\n    let id = UUID()\n    let path: Path\n    let color: Color\n    let thickness: CGFloat\n}\n```",

    "### WhisperVoice.swift\n```swift\nclass WhisperVoice: ObservableObject {\n    private let synthesizer = AVSpeechSynthesizer()\n    \n    func speak(_ text: String) {\n        let utterance = AVSpeechUtterance(string: text)\n        utterance.rate = 0.4\n        utterance.pitchMultiplier = 0.9  // Whispery tone\n        utterance.volume = 0.8\n        synthesizer.speak(utterance)\n    }\n}\n```",

    "### ShadowAudio.swift\n```swift\nclass ShadowAudio: ObservableObject {\n    private var player: AVAudioPlayer?\n    \n    func startEtherealMusic() {\n        // Bundle: chopin_nocturne.m4a or mysterious ambient\n        guard let url = Bundle.main.url(forResource: \"chopin\", withExtension: \"m4a\") else { return }\n        try? AVAudioPlayer(contentsOf: url).play()\n    }\n    func playVeiledMusic() { player?.play() }\n}\n```",

    f"## Deployment\n1. Xcode New Project: '{new_name}' (SwiftUI).\n2. Paste code; add ethereal music (Chopin Nocturne).\n3. Background Audio capability.\n4. Cursor/Xcode: Refine glow effects.\n5. TestFlight → Production under World Class Scholars.\nEnhance: Color veils, memory save (iCloud), AR shadows.",
]

with PdfPages('output/EtherealVeil_App_Boilerplate.pdf') as pdf:
    fig, ax = plt.subplots(figsize=(8.5, 11))
    ax.axis('off')
    y_pos = 0.95

    ax.text(0.5, y_pos, title, ha='center', va='top', fontsize=22, fontweight='bold', transform=ax.transAxes)
    y_pos -= 0.08
    ax.text(0.5, y_pos, subtitle, ha='center', va='top', fontsize=14, style='italic', transform=ax.transAxes)
    y_pos -= 0.06
    ax.text(0.5, y_pos, '© World Class Scholars 2026 - Dr. Christopher Appiah-Thompson', ha='center', va='top', fontsize=11, transform=ax.transAxes)
    y_pos -= 0.1

    wrapped_desc = textwrap.fill(description, width=85)
    ax.text(0.05, y_pos, wrapped_desc, ha='left', va='top', fontsize=11, transform=ax.transAxes, wrap=True)
    y_pos -= 0.28

    page_num = 1
    for part in content_parts:
        lines = part.split('\n')
        for line in lines:
            if y_pos < 0.05:
                pdf.savefig(fig, bbox_inches='tight')
                plt.close(fig)
                fig, ax = plt.subplots(figsize=(8.5, 11))
                ax.axis('off')
                y_pos = 0.95
                page_num += 1
                ax.text(0.5, 0.02, f'Page {page_num}', ha='center', va='bottom', fontsize=10, transform=ax.transAxes)

            if line.startswith('#') or line.startswith('##'):
                fontsize = 16 if line.startswith('# ') else 14
                ax.text(0.05, y_pos, line.lstrip('#').strip(), ha='left', va='top', fontsize=fontsize, fontweight='bold', transform=ax.transAxes)
                y_pos -= 0.04
            elif '```swift' in line:
                ax.text(0.05, y_pos, 'Swift Code:', ha='left', va='top', fontsize=12, fontweight='bold', transform=ax.transAxes)
                y_pos -= 0.03
            elif '```' in line:
                y_pos -= 0.02
            else:
                wrapped = textwrap.fill(re.sub(r'\n', ' ', line), width=90)
                font_family = 'monospace' if any(kw in line.lower() for kw in ['class', 'func', 'struct', 'import', '@published']) else 'sans-serif'
                ax.text(0.05, y_pos, wrapped, ha='left', va='top', fontsize=10, family=font_family, transform=ax.transAxes)
                y_pos -= 0.025

        y_pos -= 0.02

    ax.text(0.5, 0.02, f'Page {page_num}', ha='center', va='bottom', fontsize=10, transform=ax.transAxes)
    pdf.savefig(fig, bbox_inches='tight')
    plt.close(fig)

print("Updated PDF: output/EtherealVeil_App_Boilerplate.pdf")
