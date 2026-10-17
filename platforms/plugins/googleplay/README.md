# {{NAME}}: the Google Play platform backend

Backend `"googleplay"` for the game's `platform` API (docs/PLATFORM.md, section 7) on **Android**:

| Service | With | Notes |
|---|---|---|
| `purchases` | Google Play Billing 9 | products, buy (consumables, non-consumables, subscriptions), finish, restore; `purchase` events for pending payments that complete, purchases made outside the game and purchases the last run did not finish. The receipt is the signed purchase JSON plus its signature. |
| `overlay` | Play Games and the Play Store | `achievements` and `leaderboards` (Play Games screens), `store` (the game's Play Store page). `friends` is `unavailable`. |
| `integrity` | Play Integrity (classic request) | `platform.integrity.token(challenge)`: the token your server decodes with Google. |
| `achievements`, `leaderboards`, `cloudSave` | Play Games Services v2 | only when the Play Games project id is set (below); cloud saves are Saved Games snapshots. |

There are no `stats` and no `presence` on Google Play: the engine answers those `unavailable`.

## What this folder is

- `src/plugin.c`: the C bridge the engine loads (`lib{{NAME}}.so`). It finds the Java class `factoria.plugin.{{NAME}}.Backend` through
  the activity's class loader, registers four native callbacks (`resolve`, `reject`, `emit`, `log`) and forwards every request of the
  game to `Backend.request(token, method, argsJson)`.
- `android/`: a Gradle library module with the Java code (`src/main/java/factoria/plugin/{{NAME}}/`), its manifest, its R8 rules and
  `src/main/res/values/games-ids.xml`. `factoria export --platform android` copies it into the game's Gradle project; Gradle fetches
  Billing, Play Games and Play Integrity from Google's Maven repository (the versions are in `android/build.gradle`).
- `CMakeLists.txt`: builds the bridge with the Android NDK for one ABI at a time and copies it to
  `android/src/main/jniLibs/<abi>/lib{{NAME}}.so`.

## Build it

`factoria call platform.add_backend '{"backend":"googleplay"}'` does all of this. By hand, with the NDK and CMake that
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

The libraries are linked for 16 KB memory pages (required by Google Play for apps that target Android 15+) and stripped. A configure
that is not an Android NDK build stops with a message that says so.

## Play Games on or off

`android/src/main/res/values/games-ids.xml` holds the **Play Games Services project id**. It is empty by default: the backend then
offers purchases, the store page and Play Integrity, never calls the Play Games SDK, and logs one line saying how to turn it on. Set it
with `factoria call platform.add_backend '{"backend":"googleplay","playGamesId":"123456789012"}'` (or edit the file) and export again;
the backend then also offers achievements, leaderboards and cloud saves.

## Before real purchases and Play Games work

`platform.add_backend` prints these with your catalog's ids filled in (`nextSteps`).

1. **Play Console**: create the app with the game's package name (`factoria.json` `id`) and upload a signed build to a testing track
   (internal testing is enough). Billing and Play Integrity answer only for an app Play knows. Add your account as a **license
   tester** and install the app from the track's link, not with adb.
2. Create the **products** with exactly the ids of the catalog (`ids.googleplay`, else the catalog id; lowercase letters, digits, `_`
   and `.`).
3. **Play Games Services**: create the project, add an Android credential (the package name and the SHA-1 of the signing key: the upload
   key for adb installs, the Play App Signing key for builds from Play), turn on Saved Games, add testers. Create the achievements and
   leaderboards and copy the ids Play generates (`CgkI...`) into `ids.googleplay` of the catalog.
4. **Play Integrity**: link a Google Cloud project in Play Console > Test and release > App integrity; your server decodes the tokens.

In a running game, `fa.call("{{NAME}}.status")` from a script returns what the device lacks (`problems`): Google Play services, the
Play Store, the installer of the app, the Billing connection and the Play Games player.
