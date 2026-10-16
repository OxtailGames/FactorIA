# {{NAME}}: the Apple platform backend

Backend `"apple"` for the game's `platform` API (docs/PLATFORM.md, section "Apple") on **iOS and macOS**:

| Service | With | Notes |
|---|---|---|
| `purchases` | StoreKit 2 | products, buy (consumables, non-consumables, subscriptions), finish, restore; `purchase` events for Ask to Buy approvals, purchases made on another device and transactions the last run did not finish. Receipts are JWS documents. |
| `achievements`, `leaderboards` | Game Center | sign-in sheet, banners, global / around-the-player / friends boards. |
| `overlay` | Game Center | `achievements`, `leaderboards` and `friends` pages through `GKAccessPoint`; `store` is `unavailable` (`purchases.buy` shows the purchase sheet). |
| `cloudSave` | iCloud key-value store | 1 MB and 1024 keys in all; needs the iCloud capability. |

There are no `stats` and no `presence` on Apple's platforms: the engine answers those `unavailable`.

## Build it

On a Mac with Xcode (the build calls `xcrun`; `factoria call platform.add_backend '{"backend":"apple"}'` does all of this):

```bash
cmake -S . -B build && cmake --build build
```

It writes `macos/lib{{NAME}}.dylib`, `ios/iphoneos/lib{{NAME}}.a` and `ios/iphonesimulator/lib{{NAME}}.a`.
`-DFA_APPLE_SLICES=macos` builds only the macOS library, `-DFA_MACOS_ARCHS="arm64;x86_64"` a universal one.

## What the exports do with `ios/plugin.json` and `macos/plugin.json`

```json
{
  "frameworks": ["StoreKit", "GameKit"],
  "swift": true,
  "entitlements": {
    "com.apple.developer.game-center": true,
    "com.apple.developer.ubiquity-kvstore-identifier": "$(TeamIdentifierPrefix)$(CFBundleIdentifier)"
  }
}
```

`factoria export --platform ios` links the `frameworks`, gives the app the Swift runtime when `swift` is true, merges the
`entitlements` of every plugin into the Xcode project's `<Game>.entitlements`, and writes `Products.storekit` (the
catalog's products) into the scheme, so running the exported project from Xcode sells them locally. The macOS export
writes the entitlements next to the app as `<Game>.entitlements` (docs/MOBILE.md and docs/EXTENDING.md have the format).

## Before real purchases and Game Center work

1. App Store Connect: create the app with the game's bundle id; turn on **In-App Purchase**, **Game Center** and
   **iCloud** (key-value storage) on its App ID.
2. Create the products, achievements and leaderboards with exactly the ids of `factoria.json`'s `platform` catalog
   (`ids.apple`, else the catalog id). `factoria call platform.state` lists them.
3. Sign in with a **sandbox Apple Account** (Settings > Developer on a device, or App Store Connect > Users and Access >
   Sandbox) and run a development-signed build. In a development build, `fa.call("apple.status")` from a script returns what is missing on that device (`problems`).

Real purchases, Game Center sign-in and iCloud need that setup; they are manual checks (docs/PLATFORM.md, "Apple").
