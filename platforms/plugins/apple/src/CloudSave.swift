// Cloud saves on iCloud's key-value store (NSUbiquitousKeyValueStore): one key per save, the value is the JSON text the
// engine hands over. Limits of the store: 1 MB in total, 1024 keys.
import Foundation
#if os(macOS)
import Security
#endif

let kvStoreEntitlement = "com.apple.developer.ubiquity-kvstore-identifier"

/// Whether the running process was signed with the entitlement; nil where an app cannot ask (iOS).
func hasEntitlement(_ name: String) -> Bool? {
    #if os(macOS)
    guard let task = SecTaskCreateFromSelf(nil) else { return false }
    return SecTaskCopyValueForEntitlement(task, name as CFString, nil) != nil
    #else
    return nil
    #endif
}

final class CloudSave: @unchecked Sendable {
    static let maxBytes = 1_048_576
    static let maxKeys = 1024

    private var store: NSUbiquitousKeyValueStore { NSUbiquitousKeyValueStore.default }

    private let signInHint = "Sign in to iCloud (iOS: Settings > your name > iCloud; macOS: System Settings > Apple Account > iCloud) and turn "
        + "iCloud Drive on; in the simulator sign in to an Apple Account under Settings. The cloud save is stored in iCloud's key-value store."
    private let entitlementHint = "Add the iCloud capability (key-value storage only) to the App ID and sign the app with the entitlement "
        + "com.apple.developer.ubiquity-kvstore-identifier = $(TeamIdentifierPrefix)$(CFBundleIdentifier): `factoria export --platform ios` "
        + "writes it into the Xcode project, a macOS app needs it in the signature (docs/PLATFORM.md, section Apple)."

    /// iCloud must be signed in, and the app must carry the key-value entitlement.
    private func requireICloud() throws {
        if hasEntitlement(kvStoreEntitlement) == false {
            throw Failure(.unavailable, "cloud saves are unavailable: this app is not signed with the entitlement \(kvStoreEntitlement)",
                          hint: entitlementHint)
        }
        if FileManager.default.ubiquityIdentityToken == nil {
            throw Failure(.unavailable, "cloud saves are unavailable: no iCloud account is signed in for this app", hint: signInHint)
        }
    }

    private func size(of value: Any) -> Int {
        if let text = value as? String { return text.utf8.count }
        if let data = value as? Data { return data.count }
        return 8
    }

    func save(key: String, data: String) throws -> JSONObject {
        try requireICloud()
        let bytes = data.utf8.count
        let others = store.dictionaryRepresentation.filter { $0.key != key }
        let total = others.values.reduce(bytes) { $0 + size(of: $1) }
        if total > CloudSave.maxBytes {
            throw Failure(.failed, "the cloud save \"\(key)\" does not fit: iCloud's key-value store holds \(CloudSave.maxBytes) bytes in all and this save would make it \(total)",
                          hint: "Save less (only what must follow the player: progress, settings), remove keys with platform.cloud.remove, or compress the value.")
        }
        if others.count >= CloudSave.maxKeys {
            throw Failure(.failed, "the cloud save \"\(key)\" does not fit: iCloud's key-value store holds at most \(CloudSave.maxKeys) keys",
                          hint: "Keep few keys (one per save slot) and remove the ones you do not need with platform.cloud.remove.")
        }
        store.set(data, forKey: key)
        store.synchronize()
        // Without the entitlement the store drops the write silently: read it back to tell.
        guard store.string(forKey: key) == data else {
            throw Failure(.unavailable, "the cloud save \"\(key)\" was not kept by iCloud's key-value store", hint: entitlementHint)
        }
        return ["key": key, "bytes": bytes]
    }

    func load(key: String) throws -> Any {
        try requireICloud()
        store.synchronize()
        guard let text = store.string(forKey: key) else { return NSNull() }
        return ["key": key, "data": text]
    }

    func list() throws -> [String] {
        try requireICloud()
        store.synchronize()
        return store.dictionaryRepresentation.keys.sorted()
    }

    func remove(key: String) throws -> JSONObject {
        try requireICloud()
        store.removeObject(forKey: key)
        store.synchronize()
        return [:]
    }
}
