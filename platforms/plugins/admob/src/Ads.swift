// Consent (Google's User Messaging Platform), the App Tracking Transparency prompt and rewarded ads (the Mobile Ads SDK) on iOS.
// The behaviour is the Android side's (android/.../Ads.java) with Apple's additions. Everything here runs on the main thread.
//
// The order is Google's, then Apple's: the consent form first (a player in the EEA, UK or Switzerland answers it once; the answer
// is kept), then, only when the game asked for it (platform.ads.trackingPrompt) and the player's choices allow requesting ads,
// the "Allow tracking" sheet, and last the Mobile Ads SDK starts. Nothing of that runs before the app is active, and in a game for
// children and adults ("mixed") nothing runs before the game told ads.setUnderAge, so a child is never shown a form and the SDK
// never starts untagged.
import AppTrackingTransparency
import CFaPlugin
import Foundation
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// Runs `body` on the main thread, later (a Google callback may arrive on any thread).
func onMain(_ body: @escaping @MainActor () -> Void) {
    DispatchQueue.main.async { MainActor.assumeIsolated(body) }
}

/// One kept rewarded ad per placement.
@MainActor
final class Slot {
    let placement: String
    var unit = ""
    var ad: RewardedAd?
    var loadedAt: TimeInterval = 0
    var loading = false
    var lastError: String?
    var waiters: [() -> Void] = []
    /// The ad on screen and its delegate (the ad holds its delegate weakly).
    var showing: (ad: RewardedAd, delegate: ShowDelegate)?

    init(placement: String) { self.placement = placement }

    /// Rewarded ads expire an hour after they were loaded; a kept ad older than 55 minutes is thrown away.
    var fresh: Bool { ad != nil && ProcessInfo.processInfo.systemUptime - loadedAt < Ads.maxAge }
}

/// The events of one full-screen ad.
@MainActor
final class ShowDelegate: NSObject, FullScreenContentDelegate {
    var earned = false
    var onDismiss: (() -> Void)?
    var onFail: ((Error) -> Void)?

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { onDismiss?() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { onFail?(error) }
}

@MainActor
final class Ads {
    static let shared = Ads()

    /// Google's iOS sample app id and rewarded unit (developers.google.com/admob/ios/test-ads): they show test ads and earn nothing.
    static let sampleAppId = "ca-app-pub-3940256099942544~1458002511"
    static let sampleRewarded = "ca-app-pub-3940256099942544/1712485313"
    static let maxAge: TimeInterval = 55 * 60

    // What the export wrote into Info.plist (platforms/ios/Info.plist.in, "FactoriaAds*" and GADApplicationIdentifier).
    private var appId = ""
    private var audience = "general"  // factoria.json platform.ads.audience
    private var test = true           // a development export: Google's test ids, whatever the catalog says
    private var trackingPrompt = false  // factoria.json platform.ads.trackingPrompt

    private(set) var started = false
    private var active = false
    /// The player is under the age of consent: nil = the game did not say.
    private var underAge: Bool?
    private var flowStarted = false
    private var consentDone = false      // the consent flow ended (with or without a form)
    private var consentProblem: String?  // why the consent information could not be read, or nil
    private var trackingPending = false  // the "Allow tracking" sheet is up (or about to be)
    private var trackingAsked = false
    private var sdkStarting = false
    private var sdkReady = false
    private var blocked: String?         // why no ad can be requested (the player refused, the SDK did not start), or nil
    private var waiting: [() -> Void] = []
    private var slots: [String: Slot] = [:]
    private var startPolls = 0

    private var ump: ConsentInformation { ConsentInformation.shared }

    // --------------------------------------------------------------------------------------------------------- start ----
    func begin() {
        let info = Bundle.main.infoDictionary ?? [:]
        appId = info["GADApplicationIdentifier"] as? String ?? ""
        audience = info["FactoriaAdsAudience"] as? String ?? "general"
        test = info["FactoriaAdsTest"] as? Bool ?? true
        trackingPrompt = info["FactoriaAdsTrackingPrompt"] as? Bool ?? false
        if audience == "children" { underAge = true }
        if !test && (appId.isEmpty || appId == Ads.sampleAppId) {
            Host.shared.warn("this is a release build but the app id is " + (appId.isEmpty ? "missing" : "Google's sample id")
                + ": real ads will not load. Set platform.ads.appIds.ios in factoria.json (docs/PLATFORM.md, \"Ads on iOS\").")
        }
        if trackingPrompt && (info["NSUserTrackingUsageDescription"] as? String ?? "").isEmpty {
            Host.shared.warn("platform.ads.trackingPrompt is true but Info.plist has no NSUserTrackingUsageDescription: iOS ends the app "
                + "when the tracking sheet is requested. Export the game again (factoria export --platform ios).")
        }
        Host.shared.info("AdMob: " + (test ? "development export, Google's test ads" : "release export, real ads") + ", audience \(audience), "
            + "tracking prompt \(trackingPrompt ? "on" : "off")")
        if test && debugSetting("FA_ADS_RESET_CONSENT", "FactoriaAdsResetConsent") != nil {
            ump.reset()
            Host.shared.info("ads: the stored consent was reset (FA_ADS_RESET_CONSENT)")
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            onMain { Ads.shared.becameActive() }
        }
        started = true
        if UIApplication.shared.applicationState == .active { becameActive() }
    }

    private func becameActive() {
        active = true
        maybeStart()
    }

    /// What the game knows about the player's age travels with every request; a new answer reconfigures the SDK.
    func learn(_ r: PlatformRequest) {
        if let value = r.args.bool("underAge") { setUnderAge(value) }
        maybeStart()
    }

    private func setUnderAge(_ requested: Bool) {
        let value = audience == "children" ? true : requested  // a game for children counts every player as a child
        if underAge == value { return }
        underAge = value
        if sdkReady {
            configure()  // the tags only apply to requests made from now on: ads loaded before are not tagged
            for slot in slots.values { slot.ad = nil }
        }
        Host.shared.info("ads: the player is \(value ? "under" : "not under") the age of consent")
    }

    private var ageKnown: Bool { audience != "mixed" || underAge != nil }

    /// A launch argument (`-FactoriaAdsDebugGeography EEA`) or an environment variable (`FA_ADS_DEBUG_GEOGRAPHY=EEA`, which
    /// `SIMCTL_CHILD_FA_ADS_DEBUG_GEOGRAPHY=EEA xcrun simctl launch` passes to the simulator): only a development export reads them.
    private func debugSetting(_ environment: String, _ argument: String) -> String? {
        if let value = ProcessInfo.processInfo.environment[environment], !value.isEmpty { return value }
        if let value = UserDefaults.standard.string(forKey: argument), !value.isEmpty { return value }
        return nil
    }

    private func requestParameters() -> RequestParameters {
        let params = RequestParameters()
        if let underAge = underAge { params.isTaggedForUnderAgeOfConsent = underAge }
        // Test the form without being in Europe (a development export only): the simulator is a test device already, a real
        // device needs the hashed id that UMP writes to the log ("Use new ConsentDebugSettings.testDeviceIdentifiers = @[...]").
        if test {
            let geography = debugSetting("FA_ADS_DEBUG_GEOGRAPHY", "FactoriaAdsDebugGeography")
            let devices = debugSetting("FA_ADS_DEBUG_DEVICES", "FactoriaAdsDebugDevices")
            if geography != nil || devices != nil {
                let debug = DebugSettings()
                switch (geography ?? "").lowercased() {
                case "eea": debug.geography = .EEA
                case "regulatedusstate": debug.geography = .regulatedUSState
                case "other", "noteea": debug.geography = .other
                case "": break
                default:
                    Host.shared.warn("FA_ADS_DEBUG_GEOGRAPHY='\(geography ?? "")' is not one of EEA, regulatedUSState or other: ignored")
                }
                if let devices = devices { debug.testDeviceIdentifiers = devices.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
                params.debugSettings = debug
                Host.shared.info("ads: UMP debug settings, geography \(geography ?? "unchanged")")
            }
        }
        return params
    }

    private func maybeStart() {
        guard !flowStarted, active, ageKnown else { return }
        guard topViewController() != nil else {
            // The window is not up yet (the engine creates it after the first frame): look again in a moment.
            startPolls += 1
            if startPolls < 240 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { MainActor.assumeIsolated { Ads.shared.maybeStart() } }
            } else {
                Host.shared.warn("ads: the app has no window to show the consent form from after 2 minutes: no ads")
            }
            return
        }
        flowStarted = true
        ump.requestConsentInfoUpdate(with: requestParameters()) { requestError in
            let message = requestError.map { "the consent information could not be read: \($0.localizedDescription) (error \(($0 as NSError).code))" }
            onMain {
                if let message = message {
                    Ads.shared.consentProblem = message
                    Ads.shared.consentFlowEnded()
                    return
                }
                Ads.shared.presentConsentFormIfRequired()
            }
        }
    }

    private func presentConsentFormIfRequired() {
        guard let controller = topViewController() else {
            consentProblem = "the app has no window to show the consent form from"
            consentFlowEnded()
            return
        }
        ConsentForm.loadAndPresentIfRequired(from: controller) { formError in
            let message = formError.map { "the consent form failed: \($0.localizedDescription) (error \(($0 as NSError).code))" }
            onMain {
                if let message = message { Ads.shared.consentProblem = message }
                Ads.shared.consentFlowEnded()
            }
        }
    }

    private func consentFlowEnded() {
        consentDone = true
        if let problem = consentProblem { Host.shared.warn("ads: \(problem)") }
        Host.shared.info("ads: consent \(Json.text(consentJson()))")
        askTrackingThenStart()
    }

    /// The "Allow tracking" sheet: only when the game asked for it, after UMP's form, when ads may be requested at all and the
    /// player is not under age (a child is never asked to be tracked).
    private func askTrackingThenStart() {
        let status = ATTrackingManager.trackingAuthorizationStatus
        guard trackingPrompt, !trackingAsked, underAge != true, ump.canRequestAds, status == .notDetermined else {
            startSdk()
            return
        }
        trackingAsked = true
        trackingPending = true
        // UMP's form was just dismissed: iOS shows the sheet only to an app that is active, and a moment after the form is gone.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { MainActor.assumeIsolated { Ads.shared.requestTracking() } }
    }

    private func requestTracking() {
        guard UIApplication.shared.applicationState == .active else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { MainActor.assumeIsolated { Ads.shared.requestTracking() } }
            return
        }
        ATTrackingManager.requestTrackingAuthorization { status in
            onMain {
                Ads.shared.trackingPending = false
                Host.shared.info("ads: tracking \(Ads.trackingName(status))")
                Ads.shared.startSdk()
            }
        }
    }

    /// Starts the Mobile Ads SDK once the player's choices allow requesting ads (also after they change them in the privacy form).
    private func startSdk() {
        if sdkReady || sdkStarting { return }
        if !ump.canRequestAds {
            blocked = consentProblem ?? "the player did not give the consent that ads need"
            settle()
            return
        }
        blocked = nil
        sdkStarting = true
        configure()
        MobileAds.shared.start { _ in
            onMain {
                Ads.shared.sdkReady = true
                Ads.shared.sdkStarting = false
                Host.shared.info("ads: the Mobile Ads SDK is ready")
                Ads.shared.settle()
            }
        }
    }

    /// COPPA and the age of consent: the tag AdMob needs on every request of a child (developers.google.com/admob/ios/targeting).
    private func configure() {
        let configuration = MobileAds.shared.requestConfiguration
        guard let underAge = underAge else { return }
        configuration.ageRestrictedTreatment = underAge ? .child : .unspecified
        configuration.maxAdContentRating = underAge ? .general : nil
    }

    /// Runs what waited for the start to finish (the SDK is ready, or it will not be).
    private func settle() {
        let run = waiting
        waiting.removeAll()
        for work in run { work() }
    }

    private var settled: Bool {
        if trackingPending { return false }
        return sdkReady || blocked != nil || (consentDone && !ump.canRequestAds)
    }

    /// The player is busy with a form or a sheet: the flow ends by itself, so a request waits for it however long it takes.
    private var playerBusy: Bool { flowStarted && (!consentDone || trackingPending) }

    private func after(_ seconds: Double, _ r: PlatformRequest, _ action: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            MainActor.assumeIsolated { if !r.isAnswered { action() } }
        }
    }

    /// Runs `then` once the consent flow and the SDK start have ended; a request that waits too long gets `late`.
    private func whenSettled(_ r: PlatformRequest, then: @escaping () -> Void, late: @escaping () -> Void) {
        if settled {
            then()
            return
        }
        waiting.append { if !r.isAnswered { then() } }
        giveUpLater(r, late)
    }

    private func giveUpLater(_ r: PlatformRequest, _ late: @escaping () -> Void) {
        after(120, r) {
            if Ads.shared.playerBusy { Ads.shared.giveUpLater(r, late) } else { late() }
        }
    }

    // ----------------------------------------------------------------------------------------------------- consent ----
    static func trackingName(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "notDetermined"
        }
    }

    private func consentJson() -> JSONObject {
        var gdpr = "unknown"
        var options = "unknown"
        var canShow = false
        if consentDone {
            canShow = ump.canRequestAds
            switch ump.consentStatus {
            case .notRequired: gdpr = "notRequired"
            case .obtained: gdpr = canShow ? "granted" : "denied"
            case .required: gdpr = "denied"  // the flow ended and it is still required: no answer
            default: gdpr = "unknown"
            }
            switch ump.privacyOptionsRequirementStatus {
            case .required: options = "required"
            case .notRequired: options = "notRequired"
            default: options = "unknown"
            }
        }
        // The App Tracking Transparency answer; a game that does not use the sheet (platform.ads.trackingPrompt) tracks nothing.
        let tracking = trackingPrompt ? Ads.trackingName(ATTrackingManager.trackingAuthorizationStatus) : "notRequired"
        return ["gdpr": gdpr, "tracking": tracking, "canShowAds": canShow, "privacyOptions": options]
    }

    func consent(_ r: PlatformRequest) {
        if !ageKnown {  // a game for children and adults has not asked the age yet: the form must not appear
            r.resolve(["gdpr": "unknown", "tracking": trackingPrompt ? Ads.trackingName(ATTrackingManager.trackingAuthorizationStatus) : "notRequired",
                       "canShowAds": false, "privacyOptions": "unknown"])
            return
        }
        whenSettled(r, then: { r.resolve(Ads.shared.consentJson()) }, late: { r.resolve(Ads.shared.consentJson()) })
    }

    func setUnderAge(_ r: PlatformRequest) {
        r.resolve([String: Any]())  // learn() already kept the answer and started the consent flow if it was waiting for it
    }

    func privacyOptions(_ r: PlatformRequest) {
        if !ageKnown {
            r.resolve(["shown": false])
            return
        }
        whenSettled(r, then: {
            let ads = Ads.shared
            guard ads.ump.privacyOptionsRequirementStatus == .required, let controller = ads.topViewController() else {
                r.resolve(["shown": false])
                return
            }
            r.beginInteraction()
            ConsentForm.presentPrivacyOptionsForm(from: controller) { formError in
                let failure = formError.map { Errors.google(code: ($0 as NSError).code, message: $0.localizedDescription, doing: r.doing) }
                onMain {
                    let ads = Ads.shared
                    if let failure = failure {
                        r.reject(failure)
                        return
                    }
                    if !ads.ump.canRequestAds {  // the player took the consent back: ads kept in memory must not be shown
                        for slot in ads.slots.values { slot.ad = nil }
                        ads.blocked = "the player did not give the consent that ads need"
                    } else {
                        ads.startSdk()
                    }
                    r.resolve(["shown": true])
                }
            }
        }, late: { r.resolve(["shown": false]) })
    }

    // ------------------------------------------------------------------------------------------------------- ads ----
    /// The unit to load for a placement: Google's rewarded sample in a development export, the catalog's iOS AdMob unit
    /// (`ids.admob_ios`: an AdMob unit belongs to one app, and the Android one is `ids.admob`) in a release one.
    private func unit(for r: PlatformRequest) throws -> String {
        if test { return Ads.sampleRewarded }
        let placement = r.args.string("placement") ?? ""
        let unit = (r.args["ids"] as? JSONObject)?.string("admob_ios") ?? ""
        if unit.range(of: #"^ca-app-pub-\d{16}/\d{10}$"#, options: .regularExpression) == nil {
            throw Failure(.unknownId, "\(r.doing) failed: " + (unit.isEmpty ? "the placement has no iOS ad unit" : "'\(unit)' is not an AdMob ad unit id"),
                          hint: "Give the placement its iOS AdMob unit in factoria.json: \"placements\": [{\"id\": \"\(placement)\", "
                              + "\"ids\": {\"admob_ios\": \"ca-app-pub-1234567890123456/1234567890\"}}] (AdMob > Apps > the iOS app > Ad units). "
                              + "The Android unit is ids.admob and does not work on iOS.")
        }
        if unit == Ads.sampleRewarded {
            Host.shared.warn("the placement '\(placement)' uses Google's sample ad unit in a release build: it earns nothing")
        }
        return unit
    }

    private func slot(for r: PlatformRequest) throws -> Slot {
        let placement = r.args.string("placement") ?? ""
        let slot = slots[placement] ?? Slot(placement: placement)
        slots[placement] = slot
        slot.unit = try unit(for: r)
        return slot
    }

    private func load(_ slot: Slot) {
        if slot.loading || slot.fresh || !sdkReady { return }
        slot.ad = nil
        slot.loading = true
        RewardedAd.load(with: slot.unit, request: Request()) { ad, error in
            let message = error.map { "\($0.localizedDescription) (Google error \(($0 as NSError).code))" }
            onMain {
                slot.loading = false
                if let ad = ad {
                    slot.ad = ad
                    slot.loadedAt = ProcessInfo.processInfo.systemUptime
                    slot.lastError = nil
                    Host.shared.info("ads: a rewarded ad is ready for '\(slot.placement)'")
                } else {
                    slot.ad = nil
                    slot.lastError = message ?? "no ad and no error"
                    Host.shared.warn("ads: no rewarded ad for '\(slot.placement)': \(slot.lastError ?? "")")
                }
                Ads.shared.wake(slot)
            }
        }
    }

    private func wake(_ slot: Slot) {
        let run = slot.waiters
        slot.waiters.removeAll()
        for work in run { work() }
    }

    /// Calls `then` when the slot has an ad or the load ended without one.
    private func whenLoaded(_ slot: Slot, _ r: PlatformRequest, then: @escaping () -> Void) {
        if slot.fresh {
            then()
            return
        }
        slot.waiters.append { if !r.isAnswered { then() } }
        load(slot)
        if !slot.loading && !slot.fresh { wake(slot) }  // load() did not start (SDK not ready): do not wait for nothing
    }

    func available(_ r: PlatformRequest) {
        if !ageKnown {
            r.resolve(["available": false])
            return
        }
        whenSettled(r, then: {
            let ads = Ads.shared
            do {
                if !ads.sdkReady {
                    r.resolve(["available": false])
                    return
                }
                let slot = try ads.slot(for: r)
                ads.after(30, r) { r.resolve(["available": false]) }  // a slow network is "no ad for now"
                ads.whenLoaded(slot, r) { r.resolve(["available": slot.fresh]) }
            } catch {
                r.reject(Errors.of(error, doing: r.doing))
            }
        }, late: { r.resolve(["available": false]) })
    }

    func showRewarded(_ r: PlatformRequest) {
        if !ageKnown {
            r.resolve(["rewarded": false, "reason": "consentRefused"])
            return
        }
        whenSettled(r, then: {
            let ads = Ads.shared
            do {
                if !ads.sdkReady {
                    r.resolve(["rewarded": false, "reason": !ads.ump.canRequestAds ? "consentRefused" : "noFill"])
                    return
                }
                let slot = try ads.slot(for: r)
                ads.after(30, r) { if !r.isInteracting { r.resolve(["rewarded": false, "reason": "noFill"]) } }
                ads.whenLoaded(slot, r) { ads.show(slot, r) }
            } catch {
                r.reject(Errors.of(error, doing: r.doing))
            }
        }, late: { r.resolve(["rewarded": false, "reason": "noFill"]) })
    }

    private func show(_ slot: Slot, _ r: PlatformRequest) {
        guard slot.fresh, let ad = slot.ad else {
            r.resolve(["rewarded": false, "reason": "noFill"])
            return
        }
        slot.ad = nil  // an ad is shown once
        guard let controller = topViewController() else {
            r.reject(Failure(.failed, "\(r.doing) failed: the app has no window to show the ad from",
                             hint: "Call it while the game is in front. \(Host.shared.plugin).status lists what is missing."))
            return
        }
        do {
            try ad.canPresent(from: controller)
        } catch {
            r.reject(Errors.of(error, doing: r.doing))
            load(slot)
            return
        }
        let delegate = ShowDelegate()
        delegate.onDismiss = { [weak delegate] in
            let earned = delegate?.earned ?? false
            Host.shared.info("ads: the rewarded ad of '\(slot.placement)' was closed, rewarded: \(earned)")
            slot.showing = nil
            let answer: JSONObject = earned ? ["rewarded": true] : ["rewarded": false, "reason": "closedEarly"]
            r.resolve(answer)
            Ads.shared.load(slot)  // keep the next one ready
        }
        delegate.onFail = { error in
            slot.showing = nil
            r.reject(Errors.of(error, doing: r.doing))
            Ads.shared.load(slot)
        }
        ad.fullScreenContentDelegate = delegate
        slot.showing = (ad, delegate)
        r.beginInteraction()
        ad.present(from: controller) { [weak delegate] in
            delegate?.earned = true  // the only place that grants the reward
            let reward = ad.adReward
            Host.shared.info("ads: the player earned the reward of '\(slot.placement)' (\(reward.amount) \(reward.type))")
        }
    }

    // ------------------------------------------------------------------------------------------------------ status ----
    func status() -> JSONObject {
        var problems: [String] = []
        var placements: JSONObject = [:]
        for slot in slots.values {
            placements[slot.placement] = ["unit": slot.unit, "ready": slot.fresh, "loading": slot.loading,
                                          "lastError": slot.lastError ?? NSNull()] as JSONObject
        }
        if appId.isEmpty {
            problems.append("Info.plist has no GADApplicationIdentifier: AdMob stops the app at start. Export the game again (factoria export --platform ios).")
        }
        if !test && appId == Ads.sampleAppId {
            problems.append("This is a release build with Google's sample app id: set platform.ads.appIds.ios in factoria.json and export again.")
        }
        if !active { problems.append("The app has not been active yet: the consent form waits for it.") }
        if audience == "mixed" && underAge == nil {
            problems.append("The audience is \"mixed\" and the game has not called platform.ads.setUnderAge(): no consent form, no SDK and no ad until it does (the menu kit's ageGate part asks).")
        }
        if trackingPrompt && underAge == true {
            problems.append("The player is under age: the \"Allow tracking\" sheet is never shown to them.")
        }
        if let problem = consentProblem { problems.append("Consent: \(problem)") }
        if let reason = blocked { problems.append("No ad can be requested: \(reason)") }
        return [
            "plugin": Host.shared.plugin, "started": started, "appId": appId, "test": test, "audience": audience,
            "underAge": underAge.map { $0 as Any } ?? NSNull(), "trackingPrompt": trackingPrompt,
            "consentFlowStarted": flowStarted, "consent": consentJson(), "sdkReady": sdkReady,
            "blocked": blocked.map { $0 as Any } ?? NSNull(), "placements": placements, "problems": problems,
        ]
    }

    // ---------------------------------------------------------------------------------------------------- windows ----
    /// The view controller on top of the key window: where Google's forms and ads are presented from.
    func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first else { return nil }
        var top = window.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
