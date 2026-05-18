// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// StudioStore tests — settings bootstrap, session save, favorites, backups.

import XCTest
import SwiftData
@testable import EtherealVeil

@MainActor
final class StudioStoreTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        container = PersistenceController(inMemory: true).container
        context = container.mainContext
    }

    override func tearDown() async throws {
        context = nil
        container = nil
    }

    func testEnsureSettingsCreatesDefaultRecord() throws {
        let settings = try StudioStore.ensureSettings(in: context)
        XCTAssertTrue(settings.autoPlayMusic)
        XCTAssertTrue(settings.cloudKitSyncEnabled)
        XCTAssertEqual(try context.fetch(FetchDescriptor<AppSettings>()).count, 1)
    }

    func testEnsureSettingsReturnsExistingRecord() throws {
        let first = try StudioStore.ensureSettings(in: context)
        let second = try StudioStore.ensureSettings(in: context)
        XCTAssertEqual(first.persistentModelID, second.persistentModelID)
    }

    func testSaveSessionPersistsDrawingSession() throws {
        let session = try StudioStore.saveSession(kind: .drawing, strokeCount: 12, in: context)
        XCTAssertEqual(session.sessionType, "drawing")
        XCTAssertEqual(session.strokeCount, 12)
        XCTAssertEqual(try context.fetch(FetchDescriptor<DrawingSession>()).count, 1)
    }

    func testToggleFavoriteAddsThenRemoves() throws {
        let track = MusicPlayer.buildPlaylist()[0]
        XCTAssertTrue(try StudioStore.toggleFavorite(track: track, in: context))
        XCTAssertEqual(try context.fetch(FetchDescriptor<FavoriteTrack>()).count, 1)
        XCTAssertFalse(try StudioStore.toggleFavorite(track: track, in: context))
        XCTAssertTrue(try context.fetch(FetchDescriptor<FavoriteTrack>()).isEmpty)
    }

    func testTrackIdentifierUsesAudioURLWhenPresent() {
        let track = MusicPlayer.buildPlaylist()[0]
        XCTAssertEqual(
            StudioStore.trackIdentifier(for: track),
            track.audioURL?.absoluteString
        )
    }

    func testRecordBackupUpdatesSettingsAndSnapshot() throws {
        let settings = try StudioStore.ensureSettings(in: context)
        try StudioStore.recordBackup(
            provider: .cloudKit,
            settings: settings,
            sessionCount: 4,
            favoriteCount: 2,
            in: context
        )

        XCTAssertEqual(settings.lastBackupProvider, BackupProvider.cloudKit.rawValue)
        XCTAssertNotNil(settings.lastBackupAt)
        let snapshots = try context.fetch(FetchDescriptor<BackupSnapshot>())
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots[0].sessionCount, 4)
        XCTAssertEqual(snapshots[0].favoriteCount, 2)
    }

    func testUpdateBackupPreferencesPausesStatusWhenDisabled() throws {
        let settings = try StudioStore.ensureSettings(in: context)
        try StudioStore.updateBackupPreferences(
            settings: settings,
            cloudKitSyncEnabled: false,
            iCloudBackupEnabled: false,
            in: context
        )
        XCTAssertFalse(settings.cloudKitSyncEnabled)
        XCTAssertFalse(settings.iCloudBackupEnabled)
        XCTAssertTrue(settings.backupStatusMessage.contains("paused"))
    }
}
