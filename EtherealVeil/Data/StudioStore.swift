// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// Ethereal Veil™ is a trademark of World Class Scholars.
// Unauthorized reproduction or distribution is prohibited.

import Foundation
import SwiftData

enum StudioSaveKind: String {
    case drawing
    case painting

    var label: String { rawValue.capitalized }
}

enum BackupProvider: String, CaseIterable, Identifiable {
    case cloudKit = "CloudKit"
    case iCloud = "iCloud"

    var id: String { rawValue }

    var label: String { rawValue }

    var summary: String {
        switch self {
        case .cloudKit:
            "Primary sync stored through the app's CloudKit-backed SwiftData container."
        case .iCloud:
            "Recovery checkpoint recorded for iCloud-style backup visibility in the app."
        }
    }
}

@MainActor
enum StudioStore {
    static func ensureSettings(in context: ModelContext) throws -> AppSettings {
        if let settings = try context.fetch(FetchDescriptor<AppSettings>()).first {
            return settings
        }

        let settings = AppSettings()
        context.insert(settings)
        try context.save()
        return settings
    }

    static func saveSession(
        kind: StudioSaveKind,
        strokeCount: Int,
        in context: ModelContext
    ) throws -> DrawingSession {
        let session = DrawingSession(
            title: suggestedTitle(for: kind),
            sessionType: kind.rawValue,
            strokeCount: strokeCount
        )
        context.insert(session)
        try context.save()
        return session
    }

    static func toggleFavorite(track: MusicTrack, in context: ModelContext) throws -> Bool {
        let identifier = trackIdentifier(for: track)
        let descriptor = FetchDescriptor<FavoriteTrack>(
            predicate: #Predicate { favorite in
                favorite.filename == identifier
            }
        )

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
            return false
        }

        let favorite = FavoriteTrack(
            title: track.title,
            composer: track.composer,
            filename: identifier
        )
        context.insert(favorite)
        try context.save()
        return true
    }

    static func trackIdentifier(for track: MusicTrack) -> String {
        track.audioURL?.absoluteString ?? "\(track.title)|\(track.composer)"
    }

    static func recordBackup(
        provider: BackupProvider,
        settings: AppSettings,
        sessionCount: Int,
        favoriteCount: Int,
        in context: ModelContext
    ) throws {
        settings.lastBackupAt = .now
        settings.lastBackupProvider = provider.rawValue
        settings.backupStatusMessage = provider.summary

        let snapshot = BackupSnapshot(
            provider: provider.rawValue,
            status: "Ready",
            sessionCount: sessionCount,
            favoriteCount: favoriteCount
        )
        context.insert(snapshot)
        try context.save()
    }

    static func updateBackupPreferences(
        settings: AppSettings,
        cloudKitSyncEnabled: Bool? = nil,
        iCloudBackupEnabled: Bool? = nil,
        in context: ModelContext
    ) throws {
        if let cloudKitSyncEnabled {
            settings.cloudKitSyncEnabled = cloudKitSyncEnabled
        }

        if let iCloudBackupEnabled {
            settings.iCloudBackupEnabled = iCloudBackupEnabled
        }

        settings.backupStatusMessage =
            settings.cloudKitSyncEnabled || settings.iCloudBackupEnabled
            ? "Backups are enabled and ready for the next checkpoint."
            : "Backups are paused until CloudKit or iCloud recovery is re-enabled."

        try context.save()
    }

    private static func suggestedTitle(for kind: StudioSaveKind) -> String {
        "\(kind.label) Session \(Date.now.formatted(date: .abbreviated, time: .shortened))"
    }
}
