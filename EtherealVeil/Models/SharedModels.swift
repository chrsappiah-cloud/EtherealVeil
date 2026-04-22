// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// Shared value types used across the Studio, Services, and Data layers.

import SwiftUI

// MARK: - Image Style

enum ImageStyle: String, CaseIterable, Identifiable {
    case ethereal, watercolor, oilPainting, sketch, impressionist, abstract

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ethereal:      "Ethereal"
        case .watercolor:    "Watercolor"
        case .oilPainting:   "Oil Paint"
        case .sketch:        "Sketch"
        case .impressionist: "Impressionist"
        case .abstract:      "Abstract"
        }
    }

    var stylePromptSuffix: String {
        switch self {
        case .ethereal:      "in an ethereal, dreamlike style with soft purple hues"
        case .watercolor:    "in a delicate watercolor painting style"
        case .oilPainting:   "as a rich oil painting with impasto texture"
        case .sketch:        "as a detailed pencil sketch"
        case .impressionist: "in an impressionist style with visible brushstrokes"
        case .abstract:      "as an abstract expressionist painting"
        }
    }

    var stabilityPreset: String {
        switch self {
        case .ethereal:      "fantasy-art"
        case .watercolor:    "watercolor"
        case .oilPainting:   "oil-painting"
        case .sketch:        "pencil-sketch-2"
        case .impressionist: "impressionism"
        case .abstract:      "abstract-expressionism"
        }
    }
}

// MARK: - Gallery Item (in-memory display model)

struct GalleryItem: Identifiable {
    let id: UUID
    let image: UIImage
    let source: String          // "generated" | "uploaded" | "camera"
    let prompt: String?
    let provider: String?
    let createdAt: Date

    init(id: UUID = UUID(), image: UIImage, source: String,
         prompt: String? = nil, provider: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.image = image
        self.source = source
        self.prompt = prompt
        self.provider = provider
        self.createdAt = createdAt
    }
}
