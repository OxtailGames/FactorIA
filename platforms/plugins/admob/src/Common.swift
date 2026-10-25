// What the whole plugin shares: JSON text in and out, the engine's plugin API (logging), one platform request that is answered
// exactly once, and the error codes of docs/PLATFORM.md. The same shape as the Apple plugin's (platforms/plugins/apple), and the
// same answers as the Android side of this plugin (android/.../Request.java).
import CFaPlugin
import Foundation

typealias JSONObject = [String: Any]

// ------------------------------------------------------------------------------------------------------------ JSON --
enum Json {
    /// The object a request carries (an empty one when the text is not a JSON object).
    static func object(_ text: String) -> JSONObject {
        guard let data = text.data(using: .utf8),
              let value = try? JSONSerialization.jsonObject(with: data, options: []),
              let object = value as? JSONObject else { return [:] }
        return object
    }

    /// JSON text for an object, array, string, number, bool or NSNull.
    static func text(_ value: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]),
              let text = String(data: data, encoding: .utf8) else { return "null" }
        return text
    }
}

extension Dictionary where Key == String, Value == Any {
    func string(_ key: String) -> String? { self[key] as? String }

    /// A JSON boolean; nil when the key is missing, null or not a boolean.
    func bool(_ key: String) -> Bool? {
        guard let number = self[key] as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
        return number.boolValue
    }
}

// ------------------------------------------------------------------------------------------------------- failures --
/// The error codes a backend may use (docs/PLATFORM.md, section 2).
enum ErrorCode: String {
    case unavailable, notSignedIn, notAllowed, unknownId, network, failed
}

/// A failure that teaches: what went wrong and how to fix it. Becomes `reject(code, message, hint)`.
struct Failure: Error {
    let code: ErrorCode
    let message: String
    let hint: String?

    init(_ code: ErrorCode, _ message: String, hint: String? = nil) {
        self.code = code
        self.message = message
        self.hint = hint
    }
}

// ----------------------------------------------------------------------------------------------------------- host --
/// The engine side: the FaPluginApi (valid until the process ends) for logging.
final class Host: @unchecked Sendable {
    static let shared = Host()

    private(set) var api: UnsafePointer<FaPluginApi>?
    private(set) var platform = ""
    private(set) var plugin = "admob"

    func attach(_ api: UnsafePointer<FaPluginApi>) {
        self.api = api
        self.platform = api.pointee.platform.map { String(cString: $0) } ?? ""
        self.plugin = api.pointee.plugin.map { String(cString: $0) } ?? "admob"
    }

    /// level: 0 debug, 1 info, 2 warning, 3 error.
    func log(_ level: Int32, _ message: String) {
        guard let api = api, let log = api.pointee.log else { return }
        message.withCString { log(api, level, $0) }
    }
    func info(_ message: String) { log(1, message) }
    func warn(_ message: String) { log(2, message) }
    func error(_ message: String) { log(3, message) }
}

// --------------------------------------------------------------------------------------------------------- request --
/// One platform request. It is answered exactly once, whichever way the work ends (a result, a failure, a timer): the first
/// answer wins, a later one is dropped.
final class PlatformRequest: @unchecked Sendable {
    let method: String
    let args: JSONObject
    private let token: OpaquePointer
    private let lock = NSLock()
    private var answered = false
    private var interacting = false

    init(token: OpaquePointer, method: String, argsJSON: String) {
        self.token = token
        self.method = method
        self.args = Json.object(argsJSON)
    }

    /// The call as a game wrote it, for messages: platform.ads.showRewarded("more_time").
    var doing: String {
        let placement = args.string("placement") ?? ""
        return "platform.\(method)(" + (placement.isEmpty ? "" : Json.text(placement)) + ")"
    }

    private func claim() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if answered { return false }
        answered = true
        return true
    }

    var isAnswered: Bool {
        lock.lock()
        defer { lock.unlock() }
        return answered
    }

    /// The request now waits for the player (Google's consent form or an ad is up): the soft timers no longer cut it short.
    func beginInteraction() {
        lock.lock()
        interacting = true
        lock.unlock()
    }

    var isInteracting: Bool {
        lock.lock()
        defer { lock.unlock() }
        return interacting
    }

    func resolve(_ value: Any) {
        guard claim(), let api = Host.shared.api, let resolve = api.pointee.resolve else { return }
        Json.text(value).withCString { resolve(token, $0) }
    }

    func reject(_ failure: Failure) {
        guard claim(), let api = Host.shared.api, let reject = api.pointee.reject else { return }
        failure.code.rawValue.withCString { code in
            failure.message.withCString { message in
                if let hint = failure.hint {
                    hint.withCString { reject(token, code, message, $0) }
                } else {
                    reject(token, code, message, nil)
                }
            }
        }
    }
}
