// The Apple platform backend: registers the backend "apple" (Game Center, StoreKit 2, iCloud key-value store) and routes
// the game's `platform` requests to the services (docs/PLATFORM.md, "Apple").
import CFaPlugin
import Foundation
import StoreKit
#if canImport(GameKit)
import GameKit
#endif

/// What the backend offers. Game Center has no stats and no presence, so the engine answers those itself with `unavailable`.
private let appleServices = "[\"achievements\",\"leaderboards\",\"purchases\",\"cloudSave\",\"overlay\"]"

final class ApplePlugin: @unchecked Sendable {
    static let shared = ApplePlugin()

    let gameCenter = GameCenter()
    let purchases = Purchases()
    let cloud = CloudSave()

    /// Seconds after which a request that has no answer is rejected, so no game waits forever on a store that is silent.
    /// The sign-in has its own timer (it waits while Game Center shows its sheet); a purchase is cut short only until its
    /// sheet is up (Request.beginInteraction); restoring may ask the player for the Apple Account password.
    private func patience(for method: String) -> TimeInterval? {
        switch method {
        case "player.signIn": return nil
        case "purchases.restore": return 120
        default: return 30
        }
    }

    func handle(_ request: Request) {
        if let seconds = patience(for: request.method) {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + seconds) {
                if request.isInteracting { return }
                request.reject(Failure(.network, "\(request.method) got no answer from Apple within \(Int(seconds)) seconds",
                                       hint: "Check the internet connection and try again. An app that is not signed with a development "
                                           + "team gets no answers from the App Store, Game Center or iCloud: the command apple.status (fa.call from a script) lists what is missing."))
            }
        }
        Task {
            do {
                if let result = try await self.run(request) { request.resolve(result) }
            } catch {
                request.reject(foundationFailure(error, doing: request.method))
            }
        }
    }

    /// Runs one request. Returns the result, or nil when the service answers the request itself (the sign-in).
    private func run(_ request: Request) async throws -> Any? {
        let a = request.args
        switch request.method {
        case "player.signIn":
            gameCenter.signIn(request)
            return nil
        case "achievements.unlock":
            return try await gameCenter.unlock(id: a.catalogId, storeId: a.storeId)
        case "achievements.progress":
            return try await gameCenter.progress(id: a.catalogId, storeId: a.storeId, fraction: a.double("progress") ?? 0)
        case "achievements.list":
            return try await gameCenter.list(a.entries("achievements"))
        case "achievements.reset":
            return try await gameCenter.resetAchievements()
        case "leaderboards.submit":
            return try await gameCenter.submit(id: a.catalogId, storeId: a.storeId, order: a.string("order") ?? "descending", period: a.string("period") ?? "allTime",
                                               score: a.int("score") ?? 0)
        case "leaderboards.entries":
            return try await gameCenter.entries(id: a.catalogId, storeId: a.storeId, range: a.string("range") ?? "top", period: a.string("period") ?? "allTime",
                                                count: min(100, max(1, a.int("count") ?? 10)))
        case "cloud.save":
            return try cloud.save(key: a.string("key") ?? "", data: a.string("data") ?? "null")
        case "cloud.load":
            return try cloud.load(key: a.string("key") ?? "")
        case "cloud.list":
            return try cloud.list()
        case "cloud.remove":
            return try cloud.remove(key: a.string("key") ?? "")
        case "cloud.stat":
            return try cloud.stat(key: a.string("key") ?? "")
        case "purchases.products":
            return try await purchases.products(a.entries("products"))
        case "purchases.buy":
            return try await purchases.buy(id: a.catalogId, storeId: a.storeId, request: request)
        case "purchases.finish":
            return try await purchases.finish(transactionId: a.string("transactionId") ?? "")
        case "purchases.restore":
            return try await purchases.restore(a.entries("products"))
        case "overlay.open":
            return try await gameCenter.openOverlay(page: a.string("page") ?? "", id: a.string("id"), storeId: a.string("storeId"))
        default:
            throw Failure(.unavailable, "the Apple backend does not offer \(request.method)",
                          hint: "Apple has no stats and no presence; achievements, leaderboards, purchases, cloud saves and the overlay are answered. "
                              + "Check the spelling against docs/PLATFORM.md.")
        }
    }

    // ------------------------------------------------------------------------------------------------ status ----
    /// `apple.status`: what works on this device and what to fix. Synchronous (a command answers before it returns).
    func status() -> JSONObject {
        var problems: [String] = []
        let player = gameCenter.playerJSON()
        if player["signedIn"] as? Bool != true {
            problems.append("Game Center: no player is signed in. " + gameCenterHint)
        }
        if hasEntitlement("com.apple.developer.game-center") == false {
            problems.append("Game Center: the app is not signed with com.apple.developer.game-center, so Game Center answers nothing. " + gameCenterHint)
        }
        let payments = AppStore.canMakePayments
        if !payments {
            problems.append("Purchases: this device cannot make payments (Screen Time restrictions or a managed device).")
        }
        let icloud = FileManager.default.ubiquityIdentityToken != nil
        if !icloud {
            problems.append("Cloud saves: no iCloud account is signed in for this app.")
        }
        let kv = hasEntitlement(kvStoreEntitlement)
        if kv == false {
            problems.append("Cloud saves: the app is not signed with \(kvStoreEntitlement); iCloud's key-value store drops every write.")
        }
        var out: JSONObject = [
            "backend": "apple", "platform": Host.shared.platform, "gameCenter": player, "canMakePayments": payments,
            "iCloudSignedIn": icloud, "problems": problems,
        ]
        if let kv = kv { out["keyValueEntitlement"] = kv }
        if let id = Bundle.main.bundleIdentifier { out["bundleId"] = id }
        return out
    }
}

// ---------------------------------------------------------------------------------------------------- C entry points --
private func appleRequest(_ token: OpaquePointer?, _ method: UnsafePointer<CChar>?, _ args: UnsafePointer<CChar>?,
                          _ user: UnsafeMutableRawPointer?) {
    guard let token = token else { return }
    let request = Request(token: token, method: method.map { String(cString: $0) } ?? "", argsJSON: args.map { String(cString: $0) } ?? "{}")
    ApplePlugin.shared.handle(request)
}

private func appleStatus(_ call: OpaquePointer?, _ args: UnsafePointer<CChar>?, _ user: UnsafeMutableRawPointer?) {
    guard let api = Host.shared.api, let reply = api.pointee.reply, let call = call else { return }
    Json.text(ApplePlugin.shared.status()).withCString { reply(call, $0) }
}

/// The entry point both flavours call (entry.c): fa_plugin_init (a dylib on macOS) and fa_plugin_init_<name> (a static
/// library on iOS). Returns 0 when the backend is registered.
@_cdecl("fa_apple_init")
public func fa_apple_init(_ api: UnsafePointer<FaPluginApi>) -> Int32 {
    Host.shared.attach(api)
    guard api.pointee.version >= 2, let addBackend = api.pointee.add_backend else {
        Host.shared.log(3, "the Apple plugin needs plugin API version 2 (the engine runs version \(api.pointee.version)): "
            + "build the game with a FactorIA that has the platform API (docs/PLATFORM.md)")
        return 1
    }
    let registered: Int32 = "apple".withCString { name in
        appleServices.withCString { services in
            var desc = FaBackendDesc(name: name, services: services, request: appleRequest, frame: nil, user: nil)
            return addBackend(api, &desc)
        }
    }
    if registered != 0 { return registered }  // the engine logged why

    if let addCommand = api.pointee.add_command {
        let summary = "Show what works on this device for Apple's services (Game Center, purchases, iCloud) and what to fix."
        let details = "Reports whether a Game Center player is signed in, whether purchases are allowed, whether iCloud is signed in and "
            + "whether the app carries the entitlements, with a `problems` list of teaching lines. Example: {}."
        _ = "\(Host.shared.plugin).status".withCString { name in
            summary.withCString { summary in
                details.withCString { details in
                    var command = FaCommandDesc(name: name, summary: summary, description: details, input_schema: nil, read_only: 1,
                                                handler: appleStatus, user: nil)
                    return addCommand(api, &command)
                }
            }
        }
    }
    ApplePlugin.shared.purchases.startListening()
    Host.shared.log(1, "Apple backend ready: Game Center, StoreKit 2 and iCloud key-value saves on \(Host.shared.platform)")
    return 0
}
