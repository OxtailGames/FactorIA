# {{NAME}}: the AdMob ads backend

Backend `"admob"` for the `ads` service of the game's `platform` API (docs/PLATFORM.md, section "Ads") on **Android**. It offers only
`ads`: the game's store backend (Google Play, Steam, the fake) keeps answering purchases, achievements and the rest, and the engine
sends every `ads.*` request to this one.

| Call | What it does |
|---|---|
| `platform.ads.consent()` | Google's User Messaging Platform (UMP): `gdpr` is `granted`, `denied`, `notRequired` or `unknown`; `tracking` is always `notRequired` (Android has no tracking sheet); `privacyOptions` is `required` when the player can change their choices. |
| `platform.ads.available(placement)` | Loads one rewarded ad for the placement and keeps it. `true` when one is ready. |
| `platform.ads.showRewarded(placement)` | Shows the kept ad. `{rewarded: true}` only from the SDK's reward callback; closing the ad early is `{rewarded: false, reason: "closedEarly"}`. The next ad loads in the background. |
| `platform.ads.setUnderAge(bool)` | The answer of the age gate. It tags the UMP request and every ad request (child-directed treatment, under the age of consent, content rating G for a child). |
| `platform.ads.privacyOptions()` | Opens UMP's privacy options form when `consent().privacyOptions` is `required`. |

The start order is Google's: UMP first (a player in the EEA, the UK or Switzerland sees the consent form once), the Mobile Ads SDK
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
  `android/src/main/jniLibs/<abi>/lib{{NAME}}.so`.

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

## Test ads and real ads

- An export that is not a release (`factoria export --platform android` without `--release`) always uses **Google's sample app id**
  (`ca-app-pub-3940256099942544~3347511713`) and **Google's sample rewarded unit** (`ca-app-pub-3940256099942544/5224354917`),
  whatever the catalog says. They show test ads and earn nothing, so you cannot click your own real ads by mistake.
- A release export writes `platform.ads.appIds.android` of `factoria.json` into the manifest and loads the placement's AdMob unit
  (`"ids": {"admob": "ca-app-pub-.../..."}`). `factoria validate` warns when a release export would carry the sample app id or no app id.

In a running game, `fa.call("{{NAME}}.status")` from a script returns the manifest's app id, whether it is a test build, the audience,
the age the game told, the consent answer, whether the SDK started, each placement's ad, and a `problems` list of what to fix.
