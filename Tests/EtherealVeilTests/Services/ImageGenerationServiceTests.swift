// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Image generation tests — mock network, error paths, provider selection.

import XCTest
@testable import EtherealVeil

// MARK: - Mock service

private final class MockImageService: ImageGenerationService, @unchecked Sendable {
    let providerName = "Mock"
    var shouldFail: Bool = false
    var errorToThrow: Error = GenerationError.invalidResponse
    var callCount = 0
    var lastPrompt: String?
    var lastStyle: ImageStyle?

    func generate(prompt: String, style: ImageStyle, size: ImageSize) async throws -> UIImage {
        callCount += 1
        lastPrompt = prompt
        lastStyle = style
        if shouldFail { throw errorToThrow }
        // Return a 1×1 white image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { ctx in ctx.cgContext.setFillColor(UIColor.white.cgColor); ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1)) }
    }
}

// MARK: - Tests

final class ImageGenerationServiceTests: XCTestCase {

    // MARK: - GenerationError descriptions

    func testNoAPIKeyErrorMessage() {
        let err = GenerationError.noAPIKey("Stability AI")
        XCTAssertTrue(err.localizedDescription.contains("Stability AI"))
        XCTAssertTrue(err.localizedDescription.contains("API key"))
    }

    func testNetworkErrorMessage() {
        let err = GenerationError.networkError("HTTP 503")
        XCTAssertTrue(err.localizedDescription.contains("503"))
    }

    func testQuotaExceededMessage() {
        let err = GenerationError.quotaExceeded
        XCTAssertTrue(err.localizedDescription.lowercased().contains("quota"))
    }

    func testContentFilteredMessage() {
        let err = GenerationError.contentFiltered
        XCTAssertFalse(err.localizedDescription.isEmpty)
    }

    // MARK: - Mock service happy path

    func testMockServiceReturnsImage() async throws {
        let service = MockImageService()
        let image = try await service.generate(prompt: "test", style: .ethereal, size: .square512)
        XCTAssertNotNil(image)
        XCTAssertEqual(service.callCount, 1)
        XCTAssertEqual(service.lastPrompt, "test")
        XCTAssertEqual(service.lastStyle, .ethereal)
    }

    func testMockServicePropagatesError() async {
        let service = MockImageService()
        service.shouldFail = true
        service.errorToThrow = GenerationError.quotaExceeded

        do {
            _ = try await service.generate(prompt: "test", style: .ethereal, size: .square512)
            XCTFail("Expected error")
        } catch GenerationError.quotaExceeded {
            // correct
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Provider factory

    func testEachProviderMakesDistinctService() {
        let s1 = AIProvider.stabilityAI.makeService()
        let s2 = AIProvider.openAIDallE.makeService()
        let s3 = AIProvider.replicate.makeService()
        XCTAssertEqual(s1.providerName, "Stability AI")
        XCTAssertEqual(s2.providerName, "OpenAI DALL·E 3")
        XCTAssertEqual(s3.providerName, "Replicate SDXL")
    }

    func testAllProvidersCoverAllCases() {
        XCTAssertEqual(AIProvider.allCases.count, 3)
    }

    // MARK: - ImageStyle

    func testImageStyleStabilityPresetNonEmpty() {
        for style in ImageStyle.allCases {
            XCTAssertFalse(style.stabilityPreset.isEmpty, "\(style) has empty stabilityPreset")
        }
    }

    func testImageStylePromptSuffixNonEmpty() {
        for style in ImageStyle.allCases {
            XCTAssertFalse(style.stylePromptSuffix.isEmpty, "\(style) has empty prompt suffix")
        }
    }

    func testImageStyleDalleSize() {
        XCTAssertEqual(ImageSize.square512.dallESize, "1024x1024")
        XCTAssertEqual(ImageSize.landscape.dallESize, "1792x1024")
        XCTAssertEqual(ImageSize.portrait.dallESize, "1024x1792")
    }

    func testImageSizeStabilityDimensions() {
        let (w, h) = ImageSize.square1024.stabilityDimensions
        XCTAssertEqual(w, 1024)
        XCTAssertEqual(h, 1024)
    }

    // MARK: - Stability API key guard

    func testStabilityServiceThrowsWithoutKey() async {
        try? KeychainService.delete(.stabilityAIKey)
        let service = StabilityAIService()
        do {
            _ = try await service.generate(prompt: "test", style: .ethereal, size: .square512)
            XCTFail("Expected noAPIKey error")
        } catch GenerationError.noAPIKey {
            // correct
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDallEServiceThrowsWithoutKey() async {
        try? KeychainService.delete(.openAIKey)
        let service = DallE3Service()
        do {
            _ = try await service.generate(prompt: "test", style: .watercolor, size: .square512)
            XCTFail("Expected noAPIKey error")
        } catch GenerationError.noAPIKey {
            // correct
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReplicateServiceThrowsWithoutKey() async {
        try? KeychainService.delete(.replicateKey)
        let service = ReplicateService()
        do {
            _ = try await service.generate(prompt: "test", style: .abstract, size: .square512)
            XCTFail("Expected noAPIKey error")
        } catch GenerationError.noAPIKey {
            // correct
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
