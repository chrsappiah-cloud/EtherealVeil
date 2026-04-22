// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// KeychainService unit tests — save, read, delete, overwrite, edge cases.

import XCTest
@testable import EtherealVeil

final class KeychainServiceTests: XCTestCase {

    // Clean up test key after each test
    override func tearDown() {
        try? KeychainService.delete(.stabilityAIKey)
        try? KeychainService.delete(.openAIKey)
        try? KeychainService.delete(.replicateKey)
        super.tearDown()
    }

    // MARK: - Save & Read

    func testSaveAndReadRoundTrip() throws {
        try KeychainService.save("sk-test-abc123", for: .stabilityAIKey)
        XCTAssertEqual(KeychainService.read(.stabilityAIKey), "sk-test-abc123")
    }

    func testSaveOverwritesPreviousValue() throws {
        try KeychainService.save("first-value", for: .openAIKey)
        try KeychainService.save("second-value", for: .openAIKey)
        XCTAssertEqual(KeychainService.read(.openAIKey), "second-value")
    }

    func testReadMissingKeyReturnsNil() {
        XCTAssertNil(KeychainService.read(.replicateKey))
    }

    func testHasKeyReturnsFalseWhenMissing() {
        XCTAssertFalse(KeychainService.hasKey(.replicateKey))
    }

    func testHasKeyReturnsTrueAfterSave() throws {
        try KeychainService.save("any-key", for: .replicateKey)
        XCTAssertTrue(KeychainService.hasKey(.replicateKey))
    }

    // MARK: - Delete

    func testDeleteRemovesKey() throws {
        try KeychainService.save("to-be-deleted", for: .stabilityAIKey)
        try KeychainService.delete(.stabilityAIKey)
        XCTAssertNil(KeychainService.read(.stabilityAIKey))
    }

    func testDeleteNonExistentKeyDoesNotThrow() {
        XCTAssertNoThrow(try KeychainService.delete(.replicateKey))
    }

    // MARK: - Edge Cases

    func testSaveEmptyStringStillWorks() throws {
        try KeychainService.save("", for: .openAIKey)
        XCTAssertEqual(KeychainService.read(.openAIKey), "")
    }

    func testSaveLongKey() throws {
        let longKey = String(repeating: "a", count: 512)
        try KeychainService.save(longKey, for: .stabilityAIKey)
        XCTAssertEqual(KeychainService.read(.stabilityAIKey), longKey)
    }

    func testSaveSpecialCharacters() throws {
        let special = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        try KeychainService.save(special, for: .replicateKey)
        XCTAssertEqual(KeychainService.read(.replicateKey), special)
    }

    func testAllProvidersIndependentStorage() throws {
        try KeychainService.save("key-stability", for: .stabilityAIKey)
        try KeychainService.save("key-openai",    for: .openAIKey)
        try KeychainService.save("key-replicate", for: .replicateKey)
        XCTAssertEqual(KeychainService.read(.stabilityAIKey), "key-stability")
        XCTAssertEqual(KeychainService.read(.openAIKey),      "key-openai")
        XCTAssertEqual(KeychainService.read(.replicateKey),   "key-replicate")
    }
}
