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

// MARK: - Backup Snapshot

@Model
final class BackupSnapshot {
    var id: UUID
    var provider: String
    var status: String
    var sessionCount: Int
    var favoriteCount: Int
    var createdAt: Date

    init(provider: String, status: String, sessionCount: Int, favoriteCount: Int) {
        self.id = UUID()
        self.provider = provider
        self.status = status
        self.sessionCount = sessionCount
        self.favoriteCount = favoriteCount
        self.createdAt = .now
    }
}

// MARK: - Studio User (access + payments)

@Model
final class StudioUser {
    var id: UUID
    var email: String
    var displayName: String
    var role: String
    var accessTier: String
    var subscriptionStatus: String
    var isActive: Bool
    var subscriptionExpiresAt: Date?
    var manualPaymentNote: String
    var isCurrentSession: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        email: String,
        displayName: String,
        role: StudioUserRole = .user,
        accessTier: StudioAccessTier = .free,
        subscriptionStatus: StudioSubscriptionStatus = .none
    ) {
        self.id = UUID()
        self.email = email.lowercased()
        self.displayName = displayName
        self.role = role.rawValue
        self.accessTier = accessTier.rawValue
        self.subscriptionStatus = subscriptionStatus.rawValue
        self.isActive = true
        self.subscriptionExpiresAt = nil
        self.manualPaymentNote = ""
        self.isCurrentSession = false
        self.createdAt = .now
        self.updatedAt = .now
    }
}

// MARK: - Access audit log (admin actions)

@Model
final class AccessAuditLog {
    var id: UUID
    var actorEmail: String
    var targetEmail: String
    var action: String
    var detail: String
    var createdAt: Date

    init(actorEmail: String, targetEmail: String, action: String, detail: String) {
        self.id = UUID()
        self.actorEmail = actorEmail
        self.targetEmail = targetEmail
        self.action = action
        self.detail = detail
        self.createdAt = .now
    }
}

// MARK: - App Settings

@Model
final class AppSettings {
    var id: UUID
    var autoPlayMusic: Bool
    var voiceGuidanceEnabled: Bool
    var cloudKitSyncEnabled: Bool
    var iCloudBackupEnabled: Bool
    var drawingCanvasColorHex: String
    var lastBackupAt: Date?
    var lastBackupProvider: String
    var backupStatusMessage: String
    var createdAt: Date

    static let defaultKey = "app_settings_singleton"

    init() {
        self.id = UUID()
        self.autoPlayMusic = true
        self.voiceGuidanceEnabled = true
        self.cloudKitSyncEnabled = true
        self.iCloudBackupEnabled = true
        self.drawingCanvasColorHex = "#1A1A1A"
        self.lastBackupAt = nil
        self.lastBackupProvider = ""
        self.backupStatusMessage = "CloudKit sync is ready and iCloud recovery backups are enabled."
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
            BackupSnapshot.self,
            AppSettings.self,
            StudioUser.self,
            AccessAuditLog.self,
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
