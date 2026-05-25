// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.

import Foundation
import SwiftData

@MainActor
enum AccessStore {
    private static let currentUserKey = "studio_current_user_id"
    private static let defaultAdminEmail = "admin@worldclassscholars.com"
    static let reviewDemoEmail = "review-demo@etherealveil.local"

    struct SubscriptionUpdate {
        let tier: StudioAccessTier
        let status: StudioSubscriptionStatus
        let expiresAt: Date?
        let note: String
    }

    struct AdminAccessUpdate {
        let tier: StudioAccessTier
        let status: StudioSubscriptionStatus
        let isActive: Bool
        let expiresAt: Date?
        let note: String
    }

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
            context.insert(admin)
            try context.save()
        }
    }

    static func currentUser(in context: ModelContext) throws -> StudioUser? {
        var sessionDescriptor = FetchDescriptor<StudioUser>(
            predicate: #Predicate { $0.isCurrentSession == true }
        )
        sessionDescriptor.fetchLimit = 1
        if let active = try context.fetch(sessionDescriptor).first {
            return active
        }

        guard let idString = UserDefaults.standard.string(forKey: currentUserKey),
              let id = UUID(uuidString: idString) else { return nil }
        let idDescriptor = FetchDescriptor<StudioUser>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(idDescriptor).first
    }

    static func adminUser(in context: ModelContext) throws -> StudioUser? {
        let descriptor = FetchDescriptor<StudioUser>(
            predicate: #Predicate { $0.role == "admin" }
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
            if existing.role == StudioUserRole.admin.rawValue {
                throw AccessStoreError.reservedAccount
            }
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

    static func activateReviewMode(in context: ModelContext) throws -> StudioUser {
        let descriptor = FetchDescriptor<StudioUser>(
            predicate: #Predicate { $0.email == reviewDemoEmail }
        )
        let user: StudioUser
        if let existing = try context.fetch(descriptor).first {
            existing.displayName = "App Review Demo"
            existing.role = StudioUserRole.user.rawValue
            existing.accessTier = StudioAccessTier.enterprise.rawValue
            existing.subscriptionStatus = StudioSubscriptionStatus.trial.rawValue
            existing.isActive = true
            existing.subscriptionExpiresAt = Calendar.current.date(byAdding: .day, value: 30, to: .now)
            existing.manualPaymentNote = "Full feature demo access"
            existing.updatedAt = .now
            user = existing
        } else {
            user = StudioUser(
                email: reviewDemoEmail,
                displayName: "App Review Demo",
                accessTier: .enterprise,
                subscriptionStatus: .trial
            )
            user.subscriptionExpiresAt = Calendar.current.date(byAdding: .day, value: 30, to: .now)
            user.manualPaymentNote = "Full feature demo access"
            context.insert(user)
        }

        try setCurrentUser(user, in: context)
        try context.save()
        return user
    }

    static func applySubscription(
        user: StudioUser,
        update: SubscriptionUpdate,
        in context: ModelContext
    ) throws {
        user.accessTier = update.tier.rawValue
        user.subscriptionStatus = update.status.rawValue
        user.subscriptionExpiresAt = update.expiresAt
        user.manualPaymentNote = update.note
        user.updatedAt = .now
        try context.save()
    }

    static func adminUpdateUser(
        actor: StudioUser,
        target: StudioUser,
        update: AdminAccessUpdate,
        in context: ModelContext
    ) throws {
        guard actor.role == StudioUserRole.admin.rawValue else {
            throw AccessStoreError.notAuthorized
        }
        target.accessTier = update.tier.rawValue
        target.subscriptionStatus = update.status.rawValue
        target.isActive = update.isActive
        target.subscriptionExpiresAt = update.expiresAt
        target.manualPaymentNote = update.note
        target.updatedAt = .now

        let log = AccessAuditLog(
            actorEmail: actor.email,
            targetEmail: target.email,
            action: "access_update",
            detail: "Tier \(update.tier.rawValue), status \(update.status.rawValue), active \(update.isActive)"
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

enum AccessStoreError: LocalizedError, Equatable {
    case notAuthorized
    case reservedAccount

    var errorDescription: String? {
        switch self {
        case .notAuthorized: "Admin privileges are required for this action."
        case .reservedAccount: "This account is reserved. Use Full Feature Demo for full access in this build."
        }
    }
}
