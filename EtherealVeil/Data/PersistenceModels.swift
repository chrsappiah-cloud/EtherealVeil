// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// Ethereal Veil™ is a trademark of World Class Scholars.
// Unauthorized reproduction or distribution is prohibited.
// SwiftData + CloudKit persistent models for drawings, settings.

import SwiftData
import SwiftUI

// MARK: - Drawing Session

@Model
final class DrawingSession {
    var id: UUID
    var title: String
    var sessionType: String          // "drawing" | "painting"
    var thumbnailData: Data?
    var strokeCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(title: String, sessionType: String, thumbnailData: Data? = nil, strokeCount: Int = 0) {
        self.id = UUID()
        self.title = title
        self.sessionType = sessionType
        self.thumbnailData = thumbnailData
        self.strokeCount = strokeCount
        self.createdAt = .now
        self.updatedAt = .now
    }
}

// MARK: - Favorite Track

@Model
final class FavoriteTrack {
    var id: UUID
    var title: String
    var composer: String
    var filename: String
    var addedAt: Date

    init(title: String, composer: String, filename: String) {
        self.id = UUID()
        self.title = title
        self.composer = composer
        self.filename = filename
        self.addedAt = .now
    }
}

// MARK: - App Settings

@Model
final class AppSettings {
    var id: UUID
    var autoPlayMusic: Bool
    var voiceGuidanceEnabled: Bool
    var drawingCanvasColorHex: String
    var createdAt: Date

    static let defaultKey = "app_settings_singleton"

    init() {
        self.id = UUID()
        self.autoPlayMusic = true
        self.voiceGuidanceEnabled = true
        self.drawingCanvasColorHex = "#1A1A1A"
        self.createdAt = .now
    }
}

// MARK: - ModelContainer factory

struct PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([
            DrawingSession.self,
            FavoriteTrack.self,
            AppSettings.self,
        ])
        let configName = inMemory ? UUID().uuidString : "EtherealVeilStore"
        let config = ModelConfiguration(
            configName,
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed: \(error)")
        }
    }

    static var preview: PersistenceController {
        PersistenceController(inMemory: true)
    }
}
