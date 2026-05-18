// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class AccessControlManager {
    var currentUser: StudioUser?
    var showPaywall = false
    var paywallFeature: StudioFeature = .paint
    var statusMessage = "Sign in to manage your studio access."

    private let freeSessionSaveLimit = 3

    func bootstrap(in context: ModelContext) throws {
        try AccessStore.ensureDefaultAdmin(in: context)
        currentUser = try AccessStore.currentUser(in: context)
        refreshStatusMessage()
    }

    func signIn(email: String, displayName: String, in context: ModelContext) throws {
        currentUser = try AccessStore.signIn(
            email: email,
            displayName: displayName,
            in: context
        )
        refreshStatusMessage()
    }

    func signOut(in context: ModelContext) throws {
        try AccessStore.signOut(in: context)
        currentUser = nil
        statusMessage = "Signed out."
    }

    func syncSubscription(
        paymentManager: PaymentManager,
        in context: ModelContext
    ) async throws {
        guard let user = currentUser else { return }

        let entitled = await paymentManager.hasActiveEntitlement()
        if entitled {
            try AccessStore.applySubscription(
                user: user,
                tier: .pro,
                status: .active,
                expiresAt: Calendar.current.date(byAdding: .year, value: 1, to: .now),
                note: "App Store subscription",
                in: context
            )
        }
        currentUser = try AccessStore.currentUser(in: context)
        refreshStatusMessage()
    }

    func canAccess(_ feature: StudioFeature, sessionCount: Int) -> Bool {
        guard let user = currentUser, user.isActive else { return feature == .librarySave && sessionCount < 1 }

        if user.role == StudioUserRole.admin.rawValue { return true }

        let tier = StudioAccessTier(rawValue: user.accessTier) ?? .free
        let status = StudioSubscriptionStatus(rawValue: user.subscriptionStatus) ?? .none
        let paid = tier == .pro || tier == .enterprise
        let active = status == .active || status == .adminGranted || status == .trial
        let notExpired = user.subscriptionExpiresAt.map { $0 > .now } ?? true

        if paid && active && notExpired { return true }

        switch feature {
        case .paint, .cloudBackup, .fullMusic:
            return false
        case .librarySave:
            return sessionCount < freeSessionSaveLimit
        case .unlimitedSessions:
            return false
        }
    }

    func requestAccess(
        to feature: StudioFeature,
        sessionCount: Int,
        onAllowed: () -> Void
    ) {
        if canAccess(feature, sessionCount: sessionCount) {
            onAllowed()
        } else {
            paywallFeature = feature
            showPaywall = true
        }
    }

    var isAdmin: Bool {
        currentUser?.role == StudioUserRole.admin.rawValue
    }

    var accessBadge: String {
        guard let user = currentUser else { return "Guest" }
        if isAdmin { return "Admin" }
        let tier = StudioAccessTier(rawValue: user.accessTier) ?? .free
        return tier.label
    }

    private func refreshStatusMessage() {
        guard let user = currentUser else {
            statusMessage = "Create an account to save sessions and subscribe."
            return
        }
        let tier = StudioAccessTier(rawValue: user.accessTier) ?? .free
        let status = StudioSubscriptionStatus(rawValue: user.subscriptionStatus) ?? .none
        statusMessage = "\(user.displayName) · \(tier.label) · \(status.label)"
    }
}
