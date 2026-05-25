// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// Ethereal Veil™ is a trademark of World Class Scholars.
// Unauthorized reproduction or distribution is prohibited.

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
