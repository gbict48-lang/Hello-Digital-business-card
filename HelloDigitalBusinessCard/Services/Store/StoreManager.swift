import Foundation
import StoreKit
import Observation

/// Handles the in-app purchase that unlocks unlimited cards ("Hello Card Pro").
///
/// Model: the first card is free. Creating more requires a one-time Pro unlock.
/// No account needed — StoreKit ties the purchase to the user's Apple ID and
/// restores automatically across their devices.
@Observable
@MainActor
final class StoreManager {
    /// Create this product in App Store Connect as a **non-consumable** IAP.
    static let proProductID = "nl.gbict.hellodigitalbusinesscard.pro"

    /// How many cards a free user may keep.
    static let freeCardLimit = 1

    private(set) var proProduct: Product?
    private(set) var isPro = false
    private(set) var isPurchasing = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesTask?.cancel() }

    var displayPrice: String { proProduct?.displayPrice ?? "" }

    /// Whether the user is allowed to create another card right now.
    func canCreateCard(existingCount: Int) -> Bool {
        isPro || existingCount < Self.freeCardLimit
    }

    // MARK: - Loading

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            proProduct = products.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
    }

    // MARK: - Purchase / restore

    func purchasePro() async {
        guard let proProduct else {
            errorMessage = "The Pro upgrade isn't available right now. Please try again later."
            return
        }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let result = try await proProduct.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Transaction updates

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }
}
