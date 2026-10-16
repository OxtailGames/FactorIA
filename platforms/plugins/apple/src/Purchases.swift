// In-app purchases with StoreKit 2 (docs/PLATFORM.md, "Apple"): products, buy, finish, restore, and the transactions that
// arrive on their own (Ask to Buy approvals, purchases made on another device, ones the last run did not finish).
import Foundation
import StoreKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The transactions the game was told about and has not finished yet, and the ones already delivered as events.
actor Ledger {
    private var open: [UInt64: Transaction] = [:]
    private var delivered: Set<UInt64> = []

    func remember(_ transaction: Transaction) { open[transaction.id] = transaction }
    func take(_ id: UInt64) -> Transaction? { open.removeValue(forKey: id) }
    /// True the first time a transaction is delivered; later deliveries of the same one are dropped.
    func markDelivered(_ id: UInt64) -> Bool { delivered.insert(id).inserted }
}

final class Purchases: @unchecked Sendable {
    private let ledger = Ledger()
    private let lock = NSLock()
    private var listening = false

    // The App Store's wording for what to do when it does not know a product. Used in warnings and in unknownId.
    private let productHint = "Create the product in App Store Connect (My Apps > your app > Monetization > In-App Purchases) with exactly this "
        + "product id (platform.products[].ids.apple in factoria.json, else its id) and make sure the Paid Apps agreement is active. "
        + "To try purchases without App Store Connect, run the game from the Xcode project that `factoria export --platform ios` writes: "
        + "it sells the products of Products.storekit (docs/PLATFORM.md, section Apple)."

    // ------------------------------------------------------------------------------------------------ updates ----
    /// Starts listening to `Transaction.updates`: every verified transaction that did not come from buy() is a `purchase` event.
    func startListening() {
        lock.lock()
        let first = !listening
        listening = true
        lock.unlock()
        guard first else { return }
        Task.detached(priority: .utility) { [self] in
            for await result in Transaction.updates { await received(result) }
        }
        Task.detached(priority: .utility) { [self] in
            for await result in Transaction.unfinished { await received(result) }
        }
    }

    private func received(_ result: VerificationResult<Transaction>) async {
        switch result {
        case .unverified(let transaction, let error):
            Host.shared.log(2, "the App Store sent the transaction \(transaction.id) of \"\(transaction.productID)\" but its signature did not verify (\(error)): "
                + "not delivered to the game and not finished. Verify receipts on a server (docs/PLATFORM.md, section Apple).")
        case .verified(let transaction):
            if transaction.revocationDate != nil {
                Host.shared.log(1, "the transaction \(transaction.id) of \"\(transaction.productID)\" was refunded or revoked: finished, not delivered")
                await transaction.finish()
                return
            }
            if let expires = transaction.expirationDate, expires < Date() {
                await transaction.finish()  // an expired subscription period is not a purchase
                return
            }
            guard await ledger.markDelivered(transaction.id) else { return }
            await ledger.remember(transaction)
            Host.shared.emit("purchase", purchaseJSON(transaction, jws: result.jwsRepresentation))
        }
    }

    private func purchaseJSON(_ transaction: Transaction, jws: String) -> JSONObject {
        ["status": "purchased", "productId": transaction.productID, "transactionId": String(transaction.id), "receipt": jws]
    }

    // ------------------------------------------------------------------------------------------------ products ----
    private func typeName(_ type: Product.ProductType) -> String {
        switch type {
        case .consumable: return "consumable"
        case .nonConsumable: return "nonConsumable"
        default: return "subscription"  // .autoRenewable and .nonRenewable
        }
    }

    private func load(_ storeIds: [String]) async throws -> [Product] {
        if storeIds.isEmpty { return [] }
        do {
            return try await Product.products(for: storeIds)
        } catch {
            throw storeKitFailure(error, doing: "reading the products from the App Store")
        }
    }

    func products(_ wanted: [CatalogEntry]) async throws -> [JSONObject] {
        let found = try await load(wanted.map { $0.storeId })
        var out: [JSONObject] = []
        var missing: [String] = []
        for entry in wanted {
            guard let product = found.first(where: { $0.id == entry.storeId }) else {
                missing.append(entry.storeId)
                continue
            }
            out.append(["id": entry.id, "title": product.displayName, "description": product.description,
                        "price": product.displayPrice, "priceValue": NSDecimalNumber(decimal: product.price).doubleValue,
                        "currency": product.priceFormatStyle.currencyCode, "type": typeName(product.type)])
        }
        if !missing.isEmpty {
            Host.shared.log(2, "the App Store does not know the product\(missing.count == 1 ? "" : "s") \(missing.map { "\"\($0)\"" }.joined(separator: ", ")): left out. "
                + productHint)
        }
        return out
    }

    // --------------------------------------------------------------------------------------------------- buy ----
    @MainActor
    private func startPurchase(_ product: Product) async throws -> Product.PurchaseResult {
        #if canImport(UIKit)
        if #available(iOS 17.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            if let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first {
                return try await product.purchase(confirmIn: scene)
            }
        }
        #elseif canImport(AppKit)
        if #available(macOS 15.2, *), let window = NSApp.keyWindow ?? NSApp.mainWindow {
            return try await product.purchase(confirmIn: window)
        }
        #endif
        return try await product.purchase()
    }

    func buy(id: String, storeId: String, request: Request) async throws -> JSONObject {
        guard AppStore.canMakePayments else {
            throw Failure(.notAllowed, "purchases are not allowed on this device",
                          hint: "Screen Time restrictions (Settings > Screen Time > Content & Privacy Restrictions > iTunes & App Store Purchases) "
                              + "or a managed device switch in-app purchases off.")
        }
        guard let product = try await load([storeId]).first else {
            throw Failure(.unknownId, "the App Store does not know the product \"\(storeId)\"", hint: productHint)
        }
        let result: Product.PurchaseResult
        request.beginInteraction()  // from here the player decides how long it takes
        do {
            result = try await startPurchase(product)
        } catch StoreKitError.userCancelled {
            return ["status": "cancelled", "productId": storeId]
        } catch {
            throw storeKitFailure(error, doing: "buying \"\(storeId)\"")
        }
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                _ = await ledger.markDelivered(transaction.id)  // not also an event
                await ledger.remember(transaction)
                return purchaseJSON(transaction, jws: verification.jwsRepresentation)
            case .unverified(let transaction, let error):
                Host.shared.log(2, "the purchase of \"\(storeId)\" (transaction \(transaction.id)) did not verify: \(error)")
                throw Failure(.failed, "the App Store charged for \"\(storeId)\" but the signature of the transaction did not verify (\(error))",
                              hint: "Nothing was granted and the transaction is not finished, so the App Store offers it again. Receipts are JWS "
                                  + "documents: verify them on your server (docs/PLATFORM.md, section Apple). Unverified results come from a "
                                  + "modified device or a missing StoreKit test certificate.")
            }
        case .pending:  // Ask to Buy: the approval arrives later as a `purchase` event
            return ["status": "pending", "productId": storeId]
        case .userCancelled:
            return ["status": "cancelled", "productId": storeId]
        @unknown default:
            throw Failure(.failed, "the App Store answered the purchase of \"\(storeId)\" with a result this plugin does not know",
                          hint: "Update the plugin (platform.add_backend {\"backend\": \"apple\"}) to the newest version of FactorIA.")
        }
    }

    // ------------------------------------------------------------------------------------------------- finish ----
    func finish(transactionId: String) async throws -> JSONObject {
        guard let id = UInt64(transactionId), let transaction = await ledger.take(id) else {
            throw Failure(.unknownId, "StoreKit has no open transaction \"\(transactionId)\" in this run",
                          hint: "finish() takes the transactionId of a buy() result, a purchase event or a restore() entry, once.")
        }
        await transaction.finish()
        return [:]
    }

    // ------------------------------------------------------------------------------------------------ restore ----
    func restore(_ wanted: [CatalogEntry]) async throws -> [JSONObject] {
        var syncError: Error?
        do {
            try await AppStore.sync()
        } catch {
            syncError = error
        }
        let storeIds = Set(wanted.map { $0.storeId })
        var out: [JSONObject] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                Host.shared.log(2, "an entitlement did not verify and is left out of restore()")
                continue
            }
            if transaction.revocationDate != nil { continue }
            if !storeIds.isEmpty && !storeIds.contains(transaction.productID) { continue }
            await ledger.remember(transaction)
            _ = await ledger.markDelivered(transaction.id)
            out.append(["productId": transaction.productID, "transactionId": String(transaction.id), "receipt": result.jwsRepresentation])
        }
        // Syncing with the App Store failed and nothing is known locally: say why instead of "you own nothing".
        if out.isEmpty, let error = syncError, !(error is CancellationError) {
            if case StoreKitError.userCancelled = error { return out }
            throw storeKitFailure(error, doing: "restoring the purchases")
        }
        return out
    }
}
