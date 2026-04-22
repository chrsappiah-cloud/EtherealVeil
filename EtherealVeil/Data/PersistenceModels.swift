// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// SwiftData + CloudKit persistent models for gallery, drawings, settings.

import SwiftData
import SwiftUI

// MARK: - Gallery Image

@Model
final class PersistedImage {
    var id: UUID
    var imageData: Data
    var prompt: String?
    var providerRaw: String?
    var styleRaw: String?
    var sourceRaw: String           // "generated" | "uploaded" | "camera"
    var createdAt: Date
    var isFavorite: Bool

    init(imageData: Data,
         prompt: String? = nil,
         provider: String? = nil,
         style: ImageStyle? = nil,
         source: String,
         createdAt: Date = .now) {
        self.id = UUID()
        self.imageData = imageData
        self.prompt = prompt
        self.providerRaw = provider
        self.styleRaw = style?.rawValue
        self.sourceRaw = source
        self.createdAt = createdAt
        self.isFavorite = false
    }

    var uiImage: UIImage? { UIImage(data: imageData) }
    var style: ImageStyle? { styleRaw.flatMap { ImageStyle(rawValue: $0) } }
}

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
    var selectedProviderRaw: String
    var autoPlayMusic: Bool
    var voiceGuidanceEnabled: Bool
    var drawingCanvasColorHex: String
    var createdAt: Date

    static let defaultKey = "app_settings_singleton"

    init() {
        self.id = UUID()
        self.selectedProviderRaw = AIProvider.stabilityAI.rawValue
        self.autoPlayMusic = true
        self.voiceGuidanceEnabled = true
        self.drawingCanvasColorHex = "#1A1A1A"
        self.createdAt = .now
    }

    var selectedProvider: AIProvider {
        get { AIProvider(rawValue: selectedProviderRaw) ?? .stabilityAI }
        set { selectedProviderRaw = newValue.rawValue }
    }
}

// MARK: - ModelContainer factory

struct PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init(inMemory: Bool = false) {
        let schema = Schema([
            PersistedImage.self,
            DrawingSession.self,
            FavoriteTrack.self,
            AppSettings.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic   // iCloud sync when signed in
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed: \(error)")
        }
    }

    // MARK: - Preview / Test helper

    static var preview: PersistenceController {
        PersistenceController(inMemory: true)
    }
}
