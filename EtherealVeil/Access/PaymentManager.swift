// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.

import Foundation
import Observation
import StoreKit

@Observable
@MainActor
final class PaymentManager {
    var products: [Product] = []
    var isLoadingProducts = false
    var isPurchasing = false
    var statusMessage = "Loading subscription options…"
    var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForTransactions() }
    }

    var hasAvailableProducts: Bool { !products.isEmpty }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            products = try await Product.products(for: StudioProductID.all)
                .sorted { $0.price < $1.price }
            if products.isEmpty {
                statusMessage = "Purchases are not available in this build."
            } else {
                statusMessage = "Choose a plan to unlock Studio Pro."
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Could not load App Store products."
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                statusMessage = "Purchase successful — Studio Pro is active."
                return true
            case .userCancelled:
                statusMessage = "Purchase cancelled."
                return false
            case .pending:
                statusMessage = "Purchase pending approval."
                return false
            @unknown default:
                statusMessage = "Purchase could not be completed."
                return false
            }
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Purchase failed."
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await AppStore.sync()
            statusMessage = "Restore complete. Check your access status."
            return true
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Restore failed."
            return false
        }
    }

    func hasActiveEntitlement() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if StudioProductID.all.contains(transaction.productID) {
                return true
            }
        }
        return false
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard let transaction = try? checkVerified(result) else { continue }
            await transaction.finish()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
