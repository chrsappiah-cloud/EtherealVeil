// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DrawingTab()
                .tabItem {
                    Label("Draw", systemImage: "pencil.tip")
                }

            PaintingTab()
                .tabItem {
                    Label("Paint", systemImage: "paintbrush.pointed")
                }

            MusicTab()
                .tabItem {
                    Label("Music", systemImage: "music.note.list")
                }

            CreativeStudioTab()
                .tabItem {
                    Label("Studio", systemImage: "wand.and.stars")
                }
        }
        .tint(.purple)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
