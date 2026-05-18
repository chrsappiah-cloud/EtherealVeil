// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.

import Foundation

enum StudioUserRole: String, CaseIterable, Codable {
    case user
    case admin

    var label: String {
        switch self {
        case .user: "User"
        case .admin: "Admin"
        }
    }
}

enum StudioAccessTier: String, CaseIterable, Codable {
    case free
    case pro
    case enterprise

    var label: String {
        switch self {
        case .free: "Free"
        case .pro: "Studio Pro"
        case .enterprise: "Enterprise"
        }
    }
}

enum StudioSubscriptionStatus: String, CaseIterable, Codable {
    case none
    case active
    case expired
    case adminGranted
    case trial

    var label: String {
        switch self {
        case .none: "No subscription"
        case .active: "Active"
        case .expired: "Expired"
        case .adminGranted: "Granted by admin"
        case .trial: "Trial"
        }
    }
}

enum StudioFeature: String, CaseIterable {
    case paint
    case cloudBackup
    case librarySave
    case fullMusic
    case unlimitedSessions

    var title: String {
        switch self {
        case .paint: "Painting studio"
        case .cloudBackup: "Cloud backup"
        case .librarySave: "Save to library"
        case .fullMusic: "Full classical playlist"
        case .unlimitedSessions: "Unlimited sessions"
        }
    }
}

enum StudioProductID {
    static let monthly = "com.worldclassscholars.etherealveil.studio.monthly"
    static let yearly = "com.worldclassscholars.etherealveil.studio.yearly"

    static var all: [String] { [monthly, yearly] }
}
