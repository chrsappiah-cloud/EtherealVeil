// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// SwiftData persistence tests — insert, fetch, delete, CloudKit model shape.

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

    // MARK: - PersistedImage

    func testInsertAndFetchImage() throws {
        let data = UIImage(systemName: "star")!.pngData()!
        let record = PersistedImage(imageData: data, source: "generated")
        context.insert(record)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<PersistedImage>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].sourceRaw, "generated")
    }

    func testImageDefaultsNotFavorite() throws {
        let record = PersistedImage(imageData: Data(), source: "uploaded")
        context.insert(record)
        XCTAssertFalse(record.isFavorite)
    }

    func testToggleFavoriteImage() throws {
        let record = PersistedImage(imageData: Data(), source: "generated")
        context.insert(record)
        record.isFavorite = true
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<PersistedImage>())
        XCTAssertTrue(fetched[0].isFavorite)
    }

    func testDeleteImage() throws {
        let record = PersistedImage(imageData: Data(), source: "camera")
        context.insert(record)
        try context.save()
        context.delete(record)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<PersistedImage>())
        XCTAssertTrue(fetched.isEmpty)
    }

    func testImageStyleRoundTrip() throws {
        let record = PersistedImage(imageData: Data(), style: .watercolor, source: "generated")
        context.insert(record)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<PersistedImage>())
        XCTAssertEqual(fetched[0].style, .watercolor)
    }

    func testMultipleImages() throws {
        for i in 0..<10 {
            context.insert(PersistedImage(imageData: Data(), prompt: "prompt \(i)", source: "generated"))
        }
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<PersistedImage>())
        XCTAssertEqual(fetched.count, 10)
    }

    func testImageSortedByDate() throws {
        let early = PersistedImage(imageData: Data(), source: "uploaded",
                                   createdAt: Date(timeIntervalSinceNow: -100))
        let recent = PersistedImage(imageData: Data(), source: "uploaded",
                                    createdAt: Date())
        context.insert(early)
        context.insert(recent)
        try context.save()

        var desc = FetchDescriptor<PersistedImage>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let fetched = try context.fetch(desc)
        XCTAssertGreaterThan(fetched[0].createdAt, fetched[1].createdAt)
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
        XCTAssertEqual(settings.selectedProvider, .stabilityAI)
    }

    func testAppSettingsProviderChange() throws {
        let settings = AppSettings()
        context.insert(settings)
        settings.selectedProvider = .openAIDallE
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<AppSettings>())
        XCTAssertEqual(fetched[0].selectedProvider, .openAIDallE)
    }

    func testInMemoryContainerDoesNotPersistAcrossInstances() throws {
        let ctxA = PersistenceController(inMemory: true).container.mainContext
        let ctxB = PersistenceController(inMemory: true).container.mainContext
        ctxA.insert(PersistedImage(imageData: Data(), source: "test"))
        try ctxA.save()
        let countB = try ctxB.fetch(FetchDescriptor<PersistedImage>()).count
        XCTAssertEqual(countB, 0)
    }
}
