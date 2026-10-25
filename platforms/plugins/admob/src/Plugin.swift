// The AdMob backend on iOS: registers the backend "admob" with the one service "ads" and routes the game's `ads.*` requests to
// Ads.swift (docs/PLATFORM.md, "Ads"). Android has the same backend in Java (android/); macOS offers no ads (src/entry.c).
import CFaPlugin
import Foundation
import UIKit

/// What the backend offers: only ads. The game's store backend answers everything else.
private let adsServices = "[\"ads\"]"

/// Called by the engine for every request of the game, on the game's thread. Never throws; answers exactly once.
private func adsRequest(_ token: OpaquePointer?, _ method: UnsafePointer<CChar>?, _ args: UnsafePointer<CChar>?,
                        _ user: UnsafeMutableRawPointer?) {
    guard let token = token else { return }
    let request = PlatformRequest(token: token, method: method.map { String(cString: $0) } ?? "",
                                  argsJSON: args.map { String(cString: $0) } ?? "{}")
    onMain { dispatch(request) }
}

@MainActor
private func dispatch(_ r: PlatformRequest) {
    let ads = Ads.shared
    guard ads.started else {
        r.reject(Failure(.unavailable, "\(r.doing) failed: the AdMob backend did not start",
                         hint: "The log says why. \(Host.shared.plugin).status lists what is missing."))
        return
    }
    ads.learn(r)
    switch r.method {
    case "ads.available": ads.available(r)
    case "ads.showRewarded": ads.showRewarded(r)
    case "ads.consent": ads.consent(r)
    case "ads.setUnderAge": ads.setUnderAge(r)
    case "ads.privacyOptions": ads.privacyOptions(r)
    default:
        r.reject(Failure(.unavailable, "\(r.doing) failed: AdMob has no such thing (\(r.method))",
                         hint: "This backend only offers the \"ads\" service. Check platform.has(service) before using a service; the game's "
                             + "store backend answers the others."))
    }
}

/// `<plugin>.status`: what works on this device and what to fix. A command answers before it returns, so this waits for the main
/// thread (the engine calls it from there in practice).
private func adsStatus(_ call: OpaquePointer?, _ args: UnsafePointer<CChar>?, _ user: UnsafeMutableRawPointer?) {
    guard let api = Host.shared.api, let reply = api.pointee.reply, let call = call else { return }
    let status: JSONObject
    if Thread.isMainThread {
        status = MainActor.assumeIsolated { Ads.shared.status() }
    } else {
        status = DispatchQueue.main.sync { MainActor.assumeIsolated { Ads.shared.status() } }
    }
    Json.text(status).withCString { reply(call, $0) }
}

/// The entry point entry.c calls: fa_plugin_init_<name> (the static library the iOS app links). Returns 0 when the backend is
/// registered.
@_cdecl("fa_admob_init")
public func fa_admob_init(_ api: UnsafePointer<FaPluginApi>) -> Int32 {
    Host.shared.attach(api)
    guard api.pointee.version >= 2, let addBackend = api.pointee.add_backend else {
        Host.shared.error("the AdMob plugin needs plugin API version 2 (the engine runs version \(api.pointee.version)): "
            + "build the game with a FactorIA that has the platform API (docs/PLATFORM.md)")
        return 1
    }
    let registered: Int32 = "admob".withCString { name in
        adsServices.withCString { services in
            var desc = FaBackendDesc(name: name, services: services, request: adsRequest, frame: nil, user: nil)
            return addBackend(api, &desc)
        }
    }
    if registered != 0 { return registered }  // the engine logged why

    if let addCommand = api.pointee.add_command {
        let summary = "Show the state of the consent form, the tracking sheet and the Mobile Ads SDK on this device, and what to fix."
        let details = "Reports the app id of the Info.plist, whether the build uses Google's test ads, the game's audience and whether the "
            + "player is under age, whether the tracking sheet is on, the consent answer (gdpr, tracking, canShowAds, privacyOptions), "
            + "whether the Mobile Ads SDK started, the state of each placement's ad, and a `problems` list of sentences that say what to fix. "
            + "Example: {}."
        _ = "\(Host.shared.plugin).status".withCString { name in
            summary.withCString { summary in
                details.withCString { details in
                    var command = FaCommandDesc(name: name, summary: summary, description: details, input_schema: nil, read_only: 1,
                                                handler: adsStatus, user: nil)
                    return addCommand(api, &command)
                }
            }
        }
    }
    // Nothing of Google's runs yet: the consent form, the tracking sheet and the Mobile Ads SDK start once the app is active and
    // (in a game for children and adults) once the game knows whether the player is under age.
    onMain { Ads.shared.begin() }
    Host.shared.info("AdMob backend ready: service ads on \(Host.shared.platform)")
    return 0
}
