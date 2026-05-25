// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.

import SwiftUI
import SwiftData
import StoreKit

struct AccountAccessView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudioUser.updatedAt, order: .reverse) private var users: [StudioUser]
    @Query(sort: \AccessAuditLog.createdAt, order: .reverse) private var auditLogs: [AccessAuditLog]

    @Bindable var access: AccessControlManager
    @Bindable var payments: PaymentManager

    @State private var email = ""
    @State private var displayName = ""
    @State private var adminTargetEmail = ""
    @State private var adminNote = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                accountHero
                subscriptionCard
                signInCard
                if access.isAdmin {
                    adminControlCard
                    auditLogCard
                }
            }
            .padding(.vertical, 4)
        }
        .task {
            await payments.loadProducts()
            if access.currentUser != nil {
                try? await access.syncSubscription(paymentManager: payments, in: modelContext)
            }
        }
        .sheet(isPresented: $access.showPaywall) {
            PaywallSheet(access: access, payments: payments)
        }
    }

    private var accountHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Account & Access")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(GoldStudioTheme.sparkle)
            Text(access.statusMessage)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.72))
            HStack(spacing: 10) {
                GoldMetricCard(title: "Access", value: access.accessBadge, icon: "person.badge.key.fill")
                GoldMetricCard(
                    title: "Users",
                    value: "\(users.count)",
                    icon: "person.3.fill"
                )
            }
        }
        .padding(18)
        .goldPanel()
    }

    private var signInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Local studio account (no password)")
            Text(
                "There is no username/password or remote login server. "
                    + "Enter any email and display name, then tap Sign in or create account. "
                    + "First-time visitors create a local on-device profile automatically."
            )
            .font(.caption)
            .foregroundStyle(Color.white.opacity(0.62))
            TextField("Email", text: $email)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                #endif
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
            TextField("Display name", text: $displayName)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
            HStack(spacing: 10) {
                goldButton("Sign in or create account") {
                    do {
                        try access.signIn(email: email, displayName: displayName, in: modelContext)
                    } catch {
                        access.statusMessage = error.localizedDescription
                    }
                }
                if access.currentUser != nil {
                    goldButton("Sign out", filled: false) {
                        do {
                            try access.signOut(in: modelContext)
                        } catch {
                            access.statusMessage = error.localizedDescription
                        }
                    }
                }
            }
            goldButton("Enable Full Feature Demo", filled: false) {
                do {
                    try access.activateReviewMode(in: modelContext)
                } catch {
                    access.statusMessage = error.localizedDescription
                }
            }
            Text(
                "Full Feature Demo unlocks every studio tool for review. "
                    + "Studio Pro subscriptions stay in the section above."
            )
            .font(.caption2)
            .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(16)
        .goldPanel()
    }

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Studio Pro subscriptions (In-App Purchase)")
            Text(
                "Always on the Account tab — first section below the header. "
                    + "Demo mode does not remove these plans."
            )
            .font(.caption)
            .foregroundStyle(Color.white.opacity(0.62))
            Text(payments.statusMessage)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.65))

            if payments.isLoadingProducts {
                ProgressView().tint(GoldStudioTheme.sparkle)
            }

            ForEach(StudioProductID.all, id: \.self) { productID in
                if let product = payments.products.first(where: { $0.id == productID }) {
                    Button {
                        Task {
                            if await payments.purchase(product) {
                                try? await access.syncSubscription(
                                    paymentManager: payments,
                                    in: modelContext
                                )
                            }
                        }
                    } label: {
                        planRow(
                            title: product.displayName,
                            price: product.displayPrice,
                            detail: product.description
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(payments.isPurchasing)
                } else {
                    planRow(
                        title: StudioProductID.displayName(for: productID),
                        price: payments.hasAvailableProducts ? "—" : "Loading from App Store…",
                        detail: StudioProductID.catalogSummary(for: productID)
                    )
                }
            }

            HStack(spacing: 10) {
                goldButton("Reload subscription plans", filled: false) {
                    Task { await payments.loadProducts() }
                }
                goldButton("Restore purchases", filled: false) {
                    Task {
                        if await payments.restorePurchases() {
                            try? await access.syncSubscription(
                                paymentManager: payments,
                                in: modelContext
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .goldPanel()
    }

    private var adminControlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Admin access control")
            Text("Grant, revoke, or override payment status for any user.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.62))

            TextField("User email to manage", text: $adminTargetEmail)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))

            TextField("Payment / access note", text: $adminNote)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))

            ForEach(users.filter { $0.email.contains(adminTargetEmail.lowercased()) || adminTargetEmail.isEmpty }.prefix(6)) { user in
                adminUserRow(user)
            }
        }
        .padding(16)
        .goldPanel()
    }

    private func adminUserRow(_ user: StudioUser) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(user.email)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                Spacer()
                Text(StudioAccessTier(rawValue: user.accessTier)?.label ?? "Free")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(GoldStudioTheme.sparkle))
            }

            HStack(spacing: 8) {
                adminAction("Grant Pro") {
                    try? grant(user: user, tier: .pro, status: .adminGranted)
                }
                adminAction("Revoke") {
                    try? grant(user: user, tier: .free, status: .expired, active: false)
                }
                adminAction("Enterprise") {
                    try? grant(user: user, tier: .enterprise, status: .adminGranted)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
    }

    private var auditLogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Audit trail")
            if auditLogs.isEmpty {
                Text("No admin actions recorded yet.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
            } else {
                ForEach(auditLogs.prefix(8)) { log in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(log.action) → \(log.targetEmail)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(log.detail)
                            .font(.caption2)
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                    .padding(10)
                    .goldPanel()
                }
            }
        }
        .padding(16)
        .goldPanel()
    }

    private func grant(
        user: StudioUser,
        tier: StudioAccessTier,
        status: StudioSubscriptionStatus,
        active: Bool = true
    ) throws {
        guard let actor = access.currentUser else { return }
        try AccessStore.adminUpdateUser(
            actor: actor,
            target: user,
            update: .init(
                tier: tier,
                status: status,
                isActive: active,
                expiresAt: Calendar.current.date(byAdding: .year, value: 1, to: .now),
                note: adminNote.isEmpty ? "Admin override" : adminNote
            ),
            in: modelContext
        )
        access.currentUser = try AccessStore.currentUser(in: modelContext)
        access.statusMessage = "Updated access for \(user.email)"
    }

    private func planRow(title: String, price: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.62))
            }
            Spacer()
            Text(price)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(GoldStudioTheme.sparkle)
        }
        .padding(14)
        .goldPanel()
    }

    private func adminAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(GoldStudioTheme.sparkle))
        }
        .buttonStyle(.plain)
    }

    private func goldButton(_ title: String, filled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(filled ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(
                        filled
                            ? AnyShapeStyle(GoldStudioTheme.sparkle)
                            : AnyShapeStyle(Color.white.opacity(0.12))
                    )
                )
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.white.opacity(0.92))
    }
}

struct PaywallSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var access: AccessControlManager
    @Bindable var payments: PaymentManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(
                        payments.hasAvailableProducts
                            ? "Unlock \(access.paywallFeature.title)"
                            : "Full feature access"
                    )
                        .font(.title2.weight(.black))
                        .foregroundStyle(GoldStudioTheme.sparkle)
                    Text(
                        payments.hasAvailableProducts
                            ? "Studio Pro includes painting, cloud backups, the full classical playlist, and unlimited library saves."
                            : "Purchases are unavailable in this build. "
                                + "Open Account — Studio Pro subscriptions (In-App Purchase) "
                                + "is the first section below the header. "
                                + "Tap Enable Full Feature Demo below that for full access during review."
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.75))

                    if payments.hasAvailableProducts {
                        ForEach(payments.products, id: \.id) { product in
                            Button {
                                Task {
                                    if await payments.purchase(product) {
                                        try? await access.syncSubscription(
                                            paymentManager: payments,
                                            in: modelContext
                                        )
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(product.displayName)
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text(product.description)
                                            .font(.caption)
                                            .foregroundStyle(Color.white.opacity(0.6))
                                    }
                                    Spacer()
                                    Text(product.displayPrice)
                                        .foregroundStyle(GoldStudioTheme.sparkle)
                                }
                                .padding(14)
                                .goldPanel()
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("Go to Account tab") {
                        dismiss()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GoldStudioTheme.sparkle)
                }
                .padding()
            }
            .background(GoldStudioTheme.background)
            .navigationTitle(payments.hasAvailableProducts ? "Studio Pro" : "Full access")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { await payments.loadProducts() }
    }
}
