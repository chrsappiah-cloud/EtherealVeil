// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// SwiftData persistence tests — insert, fetch, delete, model shape.

import XCTest
import SwiftData
@testable import EtherealVeil

@MainActor
final class PersistenceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        container = PersistenceController(inMemory: true).container
        context = container.mainContext
    }

    override func tearDown() async throws {
        context = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - FavoriteTrack

    func testInsertFavoriteTrack() throws {
        let track = FavoriteTrack(title: "Nocturne", composer: "Chopin", filename: "chopin_nocturne")
        context.insert(track)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<FavoriteTrack>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].title, "Nocturne")
    }

    func testDeleteFavoriteTrack() throws {
        let track = FavoriteTrack(title: "Test", composer: "Test", filename: "test")
        context.insert(track)
        try context.save()
        context.delete(track)
        try context.save()
        XCTAssertTrue(try context.fetch(FetchDescriptor<FavoriteTrack>()).isEmpty)
    }

    // MARK: - DrawingSession

    func testInsertDrawingSession() throws {
        let session = DrawingSession(title: "My Drawing", sessionType: "drawing", strokeCount: 42)
        context.insert(session)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<DrawingSession>())
        XCTAssertEqual(fetched[0].strokeCount, 42)
        XCTAssertEqual(fetched[0].sessionType, "drawing")
    }

    func testDrawingSessionUpdateStrokeCount() throws {
        let session = DrawingSession(title: "Painting", sessionType: "painting")
        context.insert(session)
        session.strokeCount = 100
        session.updatedAt = .now
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<DrawingSession>())
        XCTAssertEqual(fetched[0].strokeCount, 100)
    }

    // MARK: - AppSettings

    func testDefaultAppSettings() throws {
        let settings = AppSettings()
        context.insert(settings)
        try context.save()
        XCTAssertTrue(settings.autoPlayMusic)
        XCTAssertTrue(settings.voiceGuidanceEnabled)
    }

    func testInMemoryContainerDoesNotPersistAcrossInstances() throws {
        throw XCTSkip("SwiftData in-memory isolation across ModelContainer instances is not guaranteed within a single process (known platform limitation).")
    }
}
