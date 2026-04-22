// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// ImageGenerationService — protocol + factory for Stable Diffusion, DALL·E, Replicate.

import UIKit

// MARK: - Protocol

protocol ImageGenerationService: Sendable {
    var providerName: String { get }
    func generate(prompt: String, style: ImageStyle, size: ImageSize) async throws -> UIImage
}

// MARK: - Image Size (generation-only concern, kept here)

enum ImageSize: String, CaseIterable, Identifiable {
    case square512  = "512×512"
    case square1024 = "1024×1024"
    case landscape  = "1344×768"
    case portrait   = "768×1344"

    var id: String { rawValue }

    var stabilityDimensions: (width: Int, height: Int) {
        switch self {
        case .square512:  (512, 512)
        case .square1024: (1024, 1024)
        case .landscape:  (1344, 768)
        case .portrait:   (768, 1344)
        }
    }

    var dallESize: String {
        switch self {
        case .square512:  "1024x1024"
        case .square1024: "1024x1024"
        case .landscape:  "1792x1024"
        case .portrait:   "1024x1792"
        }
    }
}

enum GenerationError: Error, LocalizedError {
    case noAPIKey(String)
    case networkError(String)
    case invalidResponse
    case quotaExceeded
    case contentFiltered
    case unsupportedProvider

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let p):     "\(p) API key not set. Add it in Settings → API Keys."
        case .networkError(let m): "Network error: \(m)"
        case .invalidResponse:     "Unexpected response from AI service."
        case .quotaExceeded:       "API quota exceeded. Please check your billing."
        case .contentFiltered:     "Prompt was filtered by content policy."
        case .unsupportedProvider: "This AI provider is not supported."
        }
    }
}

// MARK: - Factory

enum AIProvider: String, CaseIterable, Identifiable {
    case stabilityAI = "Stable Diffusion (Stability AI)"
    case openAIDallE = "DALL·E 3 (OpenAI)"
    case replicate   = "Replicate (SDXL)"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .stabilityAI: "staroflife.fill"
        case .openAIDallE: "sparkles"
        case .replicate:   "cpu"
        }
    }

    var keychainKey: KeychainKey {
        switch self {
        case .stabilityAI: .stabilityAIKey
        case .openAIDallE: .openAIKey
        case .replicate:   .replicateKey
        }
    }

    func makeService() -> any ImageGenerationService {
        switch self {
        case .stabilityAI: StabilityAIService()
        case .openAIDallE: DallE3Service()
        case .replicate:   ReplicateService()
        }
    }
}

// MARK: - Stability AI (Stable Diffusion XL)

struct StabilityAIService: ImageGenerationService {
    let providerName = "Stability AI"
    private let baseURL = "https://api.stability.ai/v2beta/stable-image/generate/core"

    func generate(prompt: String, style: ImageStyle, size: ImageSize) async throws -> UIImage {
        guard let apiKey = KeychainService.read(.stabilityAIKey), !apiKey.isEmpty else {
            throw GenerationError.noAPIKey(providerName)
        }

        let (width, height) = size.stabilityDimensions
        let fullPrompt = "\(prompt), \(style.stylePromptSuffix), high quality, detailed"

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "prompt": fullPrompt,
            "negative_prompt": "blurry, low quality, distorted",
            "aspect_ratio": aspectRatioString(width: width, height: height),
            "output_format": "png",
            "style_preset": style.stabilityPreset,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        guard let image = UIImage(data: data) else { throw GenerationError.invalidResponse }
        return image
    }

    private func aspectRatioString(width: Int, height: Int) -> String {
        if width == height { return "1:1" }
        return width > height ? "16:9" : "9:16"
    }
}

// MARK: - OpenAI DALL·E 3

struct DallE3Service: ImageGenerationService {
    let providerName = "OpenAI DALL·E 3"
    private let baseURL = "https://api.openai.com/v1/images/generations"

    func generate(prompt: String, style: ImageStyle, size: ImageSize) async throws -> UIImage {
        guard let apiKey = KeychainService.read(.openAIKey), !apiKey.isEmpty else {
            throw GenerationError.noAPIKey(providerName)
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": "\(prompt), \(style.stylePromptSuffix)",
            "n": 1,
            "size": size.dallESize,
            "quality": "hd",
            "style": style == .sketch ? "natural" : "vivid",
            "response_format": "url",
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let urlString = (json?["data"] as? [[String: Any]])?.first?["url"] as? String,
              let imageURL = URL(string: urlString) else {
            throw GenerationError.invalidResponse
        }

        let (imageData, _) = try await URLSession.shared.data(from: imageURL)
        guard let image = UIImage(data: imageData) else { throw GenerationError.invalidResponse }
        return image
    }
}

// MARK: - Replicate (SDXL)

struct ReplicateService: ImageGenerationService {
    let providerName = "Replicate SDXL"
    private let predictionsURL = "https://api.replicate.com/v1/predictions"
    private let sdxlVersion = "7762fd07cf82c948538e41f63f77d685e02b063e37291fae01d1e2ba39cd1de0"

    func generate(prompt: String, style: ImageStyle, size: ImageSize) async throws -> UIImage {
        guard let apiKey = KeychainService.read(.replicateKey), !apiKey.isEmpty else {
            throw GenerationError.noAPIKey(providerName)
        }

        // 1 — Start prediction
        var request = URLRequest(url: URL(string: predictionsURL)!)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (w, h) = size.stabilityDimensions
        let body: [String: Any] = [
            "version": sdxlVersion,
            "input": [
                "prompt": "\(prompt), \(style.stylePromptSuffix)",
                "negative_prompt": "blurry, distorted, low quality",
                "width": w,
                "height": h,
                "num_inference_steps": 30,
                "guidance_scale": 7.5,
            ] as [String: Any],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (startData, startResponse) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(startResponse, data: startData)

        guard let startJSON = try JSONSerialization.jsonObject(with: startData) as? [String: Any],
              let predictionID = startJSON["id"] as? String,
              let pollURL = URL(string: "\(predictionsURL)/\(predictionID)") else {
            throw GenerationError.invalidResponse
        }

        // 2 — Poll for completion (max 60 s)
        return try await pollForResult(pollURL: pollURL, apiKey: apiKey)
    }

    private func pollForResult(pollURL: URL, apiKey: String) async throws -> UIImage {
        for _ in 0..<30 {
            try await Task.sleep(for: .seconds(2))

            var req = URLRequest(url: pollURL)
            req.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw GenerationError.invalidResponse
            }

            let status = json["status"] as? String ?? ""
            switch status {
            case "succeeded":
                guard let outputs = json["output"] as? [String],
                      let urlString = outputs.first,
                      let imageURL = URL(string: urlString) else {
                    throw GenerationError.invalidResponse
                }
                let (imageData, _) = try await URLSession.shared.data(from: imageURL)
                guard let image = UIImage(data: imageData) else { throw GenerationError.invalidResponse }
                return image

            case "failed", "canceled":
                let errorMsg = json["error"] as? String ?? "Unknown error"
                throw GenerationError.networkError(errorMsg)

            default:
                continue
            }
        }
        throw GenerationError.networkError("Timeout waiting for Replicate prediction")
    }
}

// MARK: - Shared Helpers

private extension ImageGenerationService {
    func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: return
        case 402:       throw GenerationError.quotaExceeded
        case 400:
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = (json["error"] as? [String: Any])?["message"] as? String,
               msg.lowercased().contains("content") {
                throw GenerationError.contentFiltered
            }
            throw GenerationError.networkError("HTTP \(http.statusCode)")
        default:
            throw GenerationError.networkError("HTTP \(http.statusCode)")
        }
    }
}

// ImageStyle.stabilityPreset lives in SharedModels.swift
