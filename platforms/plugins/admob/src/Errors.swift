// Turns what the Mobile Ads SDK, the consent library and Foundation throw into the error codes of docs/PLATFORM.md, with a
// message that says what went wrong and a hint that says how to fix it (the same wording as android/.../Errors.java).
import Foundation

enum Errors {
    /// An exception inside the plugin, or an NSError from Google's code or the system.
    static func of(_ error: Error, doing: String) -> Failure {
        if let failure = error as? Failure { return failure }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            return Failure(.network, "\(doing) failed: \(ns.localizedDescription)", hint: "Check the internet connection and try again.")
        }
        if ns.domain == googleErrorDomain { return google(code: ns.code, message: ns.localizedDescription, doing: doing) }
        return Failure(.failed, "\(doing) failed: \(ns.localizedDescription) (\(ns.domain) \(ns.code))",
                       hint: "This is a bug of the plugin or of the Google library; the log has the details. "
                           + "\(Host.shared.plugin).status lists what is missing on this device.")
    }

    /// The domain of the Mobile Ads SDK's errors (GADErrorDomain).
    static let googleErrorDomain = "com.google.admob"

    /// A failure of the Mobile Ads SDK or the consent library: Google's code (GADErrorCode) and message.
    static func google(code: Int, message: String, doing: String) -> Failure {
        let text = "\(doing) failed: \(message) (Google error \(code))"
        switch code {
        case 2, 5:  // GADErrorNetworkError, GADErrorTimeout
            return Failure(.network, text, hint: "Check the internet connection and try again.")
        case 0, 12, 20:  // GADErrorInvalidRequest, GADErrorInvalidArgument, GADErrorApplicationIdentifierMissing
            return Failure(.failed, text,
                           hint: "AdMob refused the request: usually the ad unit id or the app id is wrong. In a development run the plugin uses Google's "
                               + "test ids; in a release build set platform.ads.appIds.ios and the placement's \"ids\": {\"admob_ios\": \"ca-app-pub-...\"} "
                               + "in factoria.json (docs/PLATFORM.md, \"Ads on iOS\"). AdMob units belong to one app: the Android unit (ids.admob) does not work on iOS.")
        default:
            return Failure(.failed, text,
                           hint: "\(Host.shared.plugin).status lists the state of the consent form and the SDK; the log has the details.")
        }
    }
}
