# {{NAME}}: the AdMob ads backend

Backend `"admob"` for the `ads` service of the game's `platform` API (docs/PLATFORM.md, section "Ads") on **Android** and **iOS**. It offers only
`ads`: the game's store backend (Google Play, Steam, the fake) keeps answering purchases, achievements and the rest, and the engine
sends every `ads.*` request to this one.

| Call | What it does |
|---|---|
| `platform.ads.consent()` | Google's User Messaging Platform (UMP): `gdpr` is `granted`, `denied`, `notRequired` or `unknown`; `tracking` is `notRequired` on Android and, on iOS, unless `platform.ads.trackingPrompt` is true (then Apple's App Tracking Transparency status: `authorized`, `denied`, `restricted`, `notDetermined`); `privacyOptions` is `required` when the player can change their choices. |
| `platform.ads.available(placement)` | Loads one rewarded ad for the placement and keeps it. `true` when one is ready. |
| `platform.ads.showRewarded(placement)` | Shows the kept ad. `{rewarded: true}` only from the SDK's reward callback; closing the ad early is `{rewarded: false, reason: "closedEarly"}`. The next ad loads in the background. |
| `platform.ads.setUnderAge(bool)` | The answer of the age gate. It tags the UMP request and every ad request (child-directed treatment, under the age of consent, content rating G for a child). |
| `platform.ads.privacyOptions()` | Opens UMP's privacy options form when `consent().privacyOptions` is `required`. |

The start order is Google's: UMP first (a player in the EEA, the UK or Switzerland sees the consent form once), then, on iOS and
only when `platform.ads.trackingPrompt` is true, the "Allow tracking" sheet (never for a player under age), then the Mobile Ads SDK
only when the player's choices allow requesting ads. Nothing runs before the activity is in front, and in a game whose
`platform.ads.audience` is `"mixed"` nothing runs before the game called `platform.ads.setUnderAge`.

## What this folder is

- `src/plugin.c`: the C bridge the engine loads (`lib{{NAME}}.so`). It finds the Java class `factoria.plugin.{{NAME}}.Backend` through
  the activity's class loader, registers four native callbacks (`resolve`, `reject`, `emit`, `log`) and forwards every request of the
  game to `Backend.request(token, method, argsJson)`. It registers the backend with the service list `["ads"]`.
- `android/`: a Gradle library module with the Java code (`src/main/java/factoria/plugin/{{NAME}}/`), its manifest and its R8 rules.
  `factoria export --platform android` copies it into the game's Gradle project; Gradle fetches the Mobile Ads SDK and UMP from
  Google's Maven repository (the versions are in `android/build.gradle`).
- `CMakeLists.txt`: builds the bridge with the Android NDK for one ABI at a time and copies it to
  `android/src/main/jniLibs/<abi>/lib{{NAME}}.so`; on a Mac it builds the iOS libraries and the macOS one.
- `src/*.swift`, `src/entry.c`, `include/module.modulemap`: the **iOS** side, in Swift. `Plugin.swift` registers the backend
  through the engine's plugin API, `Ads.swift` runs UMP, the tracking prompt, the Mobile Ads SDK and the rewarded ads with the same
  behaviour and answers as the Java code, `Errors.swift` and `Common.swift` hold the glue. `entry.c` is the C entry point that
  Swift code cannot define. On **macOS** the same `entry.c` builds a library that registers nothing and logs why (Google ships no
  AdMob SDK for macOS), so `platform.has("ads")` is false there.
- `ios/plugin.json`: what the iOS export links and writes (`xcframeworks`, system `frameworks`, `swift`, `infoPlist` with
  Google's `SKAdNetworkItems`). `ios/frameworks/` is where Google's XCFrameworks go: they are a download and `.gitignore` keeps them
  out of git.

## Build it

`factoria call platform.add_backend '{"backend":"admob"}'` does all of this. By hand, with the NDK and CMake that
`sdkmanager "ndk;27.2.12479018" "cmake;3.31.6"` installs in the Android SDK:

```bash
SDK=$ANDROID_HOME   # the Android SDK folder
for ABI in arm64-v8a x86_64; do
  cmake -S . -B build-$ABI -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=$SDK/ndk/27.2.12479018/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$ABI -DANDROID_PLATFORM=android-26 -DCMAKE_MAKE_PROGRAM=$SDK/cmake/3.31.6/bin/ninja
  cmake --build build-$ABI
done
```

## Build it for iOS

On a Mac with Xcode. Download Google's Mobile Ads SDK for iOS (developers.google.com/admob/ios/quick-start, "Download the SDK"),
then `factoria call platform.add_backend '{"backend":"admob","sdk":"<the .zip or the unpacked folder>"}'` copies
`GoogleMobileAds.xcframework` and `UserMessagingPlatform.xcframework` into `ios/frameworks/` and runs
`cmake -S . -B build && cmake --build build` (see `CMakeLists.txt`; `-DFA_ADMOB_SLICES="iphoneos;iphonesimulator"` limits it to the
iOS libraries) to write `ios/iphoneos/lib{{NAME}}.a` and `ios/iphonesimulator/lib{{NAME}}.a`. `factoria export --platform ios` then
links the libraries and the frameworks and writes `GADApplicationIdentifier`, `SKAdNetworkItems` and the engine's own keys into the
Info.plist. Without the frameworks the export fails and says where to put them.

## Test ads and real ads

- An export that is not a release (`factoria export --platform android` without `--release`) always uses **Google's sample app id**
  (`ca-app-pub-3940256099942544~3347511713`) and **Google's sample rewarded unit** (`ca-app-pub-3940256099942544/5224354917`),
  whatever the catalog says. They show test ads and earn nothing, so you cannot click your own real ads by mistake. On iOS the
  samples are `ca-app-pub-3940256099942544~1458002511` and `ca-app-pub-3940256099942544/1712485313`.
- A release export writes `platform.ads.appIds.android` of `factoria.json` into the manifest and loads the placement's AdMob unit
  (`"ids": {"admob": "ca-app-pub-.../..."}`; on iOS `platform.ads.appIds.ios` and `"ids": {"admob_ios": "..."}`). `factoria validate` warns when a release export would carry the sample app id or no app id.

In a running game, `fa.call("{{NAME}}.status")` from a script returns the manifest's app id, whether it is a test build, the audience,
the age the game told, the consent answer (on iOS also `trackingPrompt`), whether the SDK started, each placement's ad, and a `problems` list of what to fix.
