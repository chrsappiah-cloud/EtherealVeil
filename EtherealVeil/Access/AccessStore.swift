// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.

import Foundation
import SwiftData

@MainActor
enum AccessStore {
    private static let currentUserKey = "studio_current_user_id"
    private static let defaultAdminEmail = "admin@worldclassscholars.com"

    static func ensureDefaultAdmin(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<StudioUser>(
            predicate: #Predicate { $0.role == "admin" }
        )
        if try context.fetch(descriptor).isEmpty {
            let admin = StudioUser(
                email: defaultAdminEmail,
                displayName: "Studio Admin",
                role: .admin,
                accessTier: .enterprise,
                subscriptionStatus: .adminGranted
            )
            admin.manualPaymentNote = "Bootstrap administrator"
            admin.isCurrentSession = true
            context.insert(admin)
            UserDefaults.standard.set(admin.id.uuidString, forKey: currentUserKey)
            try context.save()
        } else if try currentUser(in: context) == nil {
            let admins = try context.fetch(descriptor)
            if let admin = admins.first {
                try setCurrentUser(admin, in: context)
            }
        }
    }

    static func currentUser(in context: ModelContext) throws -> StudioUser? {
        guard let idString = UserDefaults.standard.string(forKey: currentUserKey),
              let id = UUID(uuidString: idString) else { return nil }
        let descriptor = FetchDescriptor<StudioUser>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    static func allUsers(in context: ModelContext) throws -> [StudioUser] {
        let descriptor = FetchDescriptor<StudioUser>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    static func signIn(email: String, displayName: String, in context: ModelContext) throws -> StudioUser {
        let normalized = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<StudioUser>(
            predicate: #Predicate { $0.email == normalized }
        )
        let user: StudioUser
        if let existing = try context.fetch(descriptor).first {
            existing.displayName = displayName
            existing.updatedAt = .now
            user = existing
        } else {
            user = StudioUser(email: normalized, displayName: displayName)
            context.insert(user)
        }
        try setCurrentUser(user, in: context)
        try context.save()
        return user
    }

    static func signOut(in context: ModelContext) throws {
        for user in try allUsers(in: context) {
            user.isCurrentSession = false
        }
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        try context.save()
    }

    static func applySubscription(
        user: StudioUser,
        tier: StudioAccessTier,
        status: StudioSubscriptionStatus,
        expiresAt: Date?,
        note: String,
        in context: ModelContext
    ) throws {
        user.accessTier = tier.rawValue
        user.subscriptionStatus = status.rawValue
        user.subscriptionExpiresAt = expiresAt
        user.manualPaymentNote = note
        user.updatedAt = .now
        try context.save()
    }

    static func adminUpdateUser(
        actor: StudioUser,
        target: StudioUser,
        tier: StudioAccessTier,
        status: StudioSubscriptionStatus,
        isActive: Bool,
        expiresAt: Date?,
        note: String,
        in context: ModelContext
    ) throws {
        guard actor.role == StudioUserRole.admin.rawValue else {
            throw AccessStoreError.notAuthorized
        }
        target.accessTier = tier.rawValue
        target.subscriptionStatus = status.rawValue
        target.isActive = isActive
        target.subscriptionExpiresAt = expiresAt
        target.manualPaymentNote = note
        target.updatedAt = .now

        let log = AccessAuditLog(
            actorEmail: actor.email,
            targetEmail: target.email,
            action: "access_update",
            detail: "Tier \(tier.rawValue), status \(status.rawValue), active \(isActive)"
        )
        context.insert(log)
        try context.save()
    }

    static func auditLogs(in context: ModelContext) throws -> [AccessAuditLog] {
        let descriptor = FetchDescriptor<AccessAuditLog>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    private static func setCurrentUser(_ user: StudioUser, in context: ModelContext) throws {
        for existing in try allUsers(in: context) {
            existing.isCurrentSession = false
        }
        user.isCurrentSession = true
        UserDefaults.standard.set(user.id.uuidString, forKey: currentUserKey)
    }
}

enum AccessStoreError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAuthorized: "Admin privileges are required for this action."
        }
    }
}
