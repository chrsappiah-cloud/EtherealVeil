// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// StudioViewModel tests — generation flow, voice state, gallery CRUD, edge cases.

import XCTest
import SwiftData
@testable import EtherealVeil

@MainActor
final class StudioViewModelTests: XCTestCase {

    private var sut: StudioViewModel!
    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = PersistenceController(inMemory: true).container
        sut = StudioViewModel()
        sut.modelContext = container.mainContext
    }

    override func tearDown() async throws {
        sut = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - Initial state

    func testInitialGalleryIsEmpty() {
        XCTAssertTrue(sut.gallery.isEmpty)
    }

    func testInitialGeneratingIsFalse() {
        XCTAssertFalse(sut.isGenerating)
    }

    func testInitialRecordingIsFalse() {
        XCTAssertFalse(sut.isRecording)
    }

    func testDefaultProviderIsStabilityAI() {
        XCTAssertEqual(sut.selectedProvider, .stabilityAI)
    }

    // MARK: - API key guard

    func testGenerateWithNoKeyShowsSettingsAndSetsError() {
        try? KeychainService.delete(.stabilityAIKey)
        sut.selectedProvider = .stabilityAI
        sut.generateImage(prompt: "test", style: .ethereal)
        XCTAssertNotNil(sut.generationError)
        XCTAssertTrue(sut.showAPIKeySettings)
    }

    func testGenerateWithEmptyPromptDoesNothing() {
        try? KeychainService.save("fake-key", for: .stabilityAIKey)
        defer { try? KeychainService.delete(.stabilityAIKey) }
        sut.generateImage(prompt: "", style: .ethereal)
        // isGenerating stays false when prompt is empty
        XCTAssertFalse(sut.isGenerating)
    }

    func testGenerateWithWhitespaceOnlyPromptDoesNothing() {
        try? KeychainService.save("fake-key", for: .stabilityAIKey)
        defer { try? KeychainService.delete(.stabilityAIKey) }
        sut.generateImage(prompt: "   \n\t  ", style: .watercolor)
        XCTAssertFalse(sut.isGenerating)
    }

    // MARK: - Gallery CRUD

    func testAddToGalleryIncreasesCount() {
        let img = makeTestImage()
        sut.addToGallery(img, source: "uploaded")
        XCTAssertEqual(sut.gallery.count, 1)
    }

    func testAddMultipleImagesToGallery() {
        for _ in 0..<5 { sut.addToGallery(makeTestImage(), source: "uploaded") }
        XCTAssertEqual(sut.gallery.count, 5)
    }

    func testGalleryInsertsAtFront() {
        sut.addToGallery(makeTestImage(color: .red), source: "uploaded")
        sut.addToGallery(makeTestImage(color: .blue), source: "uploaded")
        // Most recent first
        XCTAssertEqual(sut.gallery.count, 2)
    }

    func testRemoveFromGallery() {
        sut.addToGallery(makeTestImage(), source: "uploaded")
        let item = sut.gallery[0]
        sut.removeFromGallery(item)
        XCTAssertTrue(sut.gallery.isEmpty)
    }

    func testRemoveNonExistentItemIsHarmless() {
        sut.addToGallery(makeTestImage(), source: "uploaded")
        let fakeItem = GalleryItem(id: UUID(), image: makeTestImage(), source: "uploaded",
                                   prompt: nil, provider: nil, createdAt: .now)
        sut.removeFromGallery(fakeItem)
        XCTAssertEqual(sut.gallery.count, 1)
    }

    // MARK: - SwiftData persistence

    func testAddToGalleryPersistsToDatabase() throws {
        sut.addToGallery(makeTestImage(), source: "camera")
        let fetch = FetchDescriptor<PersistedImage>()
        let records = try container.mainContext.fetch(fetch)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0].sourceRaw, "camera")
    }

    func testRemoveFromGalleryDeletesFromDatabase() throws {
        sut.addToGallery(makeTestImage(), source: "uploaded")
        let item = sut.gallery[0]
        sut.removeFromGallery(item)
        let fetch = FetchDescriptor<PersistedImage>()
        let records = try container.mainContext.fetch(fetch)
        XCTAssertTrue(records.isEmpty)
    }

    func testLoadGalleryFromDatabaseRestoresItems() throws {
        // Insert directly into DB
        let img = makeTestImage()
        let data = img.jpegData(compressionQuality: 0.8)!
        let record = PersistedImage(imageData: data, source: "generated")
        container.mainContext.insert(record)
        try container.mainContext.save()

        sut.loadGalleryFromDatabase()
        XCTAssertEqual(sut.gallery.count, 1)
    }

    // MARK: - API Key

    func testSaveAPIKeyStoresInKeychain() throws {
        sut.saveAPIKey("test-key-123", for: .openAIDallE)
        defer { try? KeychainService.delete(.openAIKey) }
        XCTAssertEqual(KeychainService.read(.openAIKey), "test-key-123")
    }

    func testCurrentAPIKeyIsSetReflectsKeychain() throws {
        try? KeychainService.delete(.stabilityAIKey)
        sut.selectedProvider = .stabilityAI
        XCTAssertFalse(sut.currentAPIKeyIsSet)

        try KeychainService.save("key", for: .stabilityAIKey)
        defer { try? KeychainService.delete(.stabilityAIKey) }
        XCTAssertTrue(sut.currentAPIKeyIsSet)
    }

    // MARK: - Helpers

    private func makeTestImage(color: UIColor = .purple) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }
}
