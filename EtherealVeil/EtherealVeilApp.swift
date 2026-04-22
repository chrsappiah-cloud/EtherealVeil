// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson

import SwiftUI
import SwiftData

@main
struct EtherealVeilApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(PersistenceController.shared.container)
    }
}
