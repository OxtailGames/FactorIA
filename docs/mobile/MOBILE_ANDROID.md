# Mobile: Android and iOS, page 1 of 4

Part of [Mobile: Android and iOS](../MOBILE.md) (the entry page lists every page).

## Android

`factoria export --platform android` writes the Gradle project **and builds the app with it** (`--format aab` builds the
Google Play bundle, `--format gradle` only writes the project). Details of the export: [EXPORTING.md](../exporting/EXPORTING_MOBILE.md#android).

The quickest way to get the prerequisites: `factoria setup android` downloads a JDK 21 and the Android SDK (platform 36,
build-tools 35.0.0, platform-tools; you read and accept the SDK license first) into `~/.factoria` and tells `factoria export`
where they are, and `factoria setup players` downloads the prebuilt `mobile/` libraries for an exe that has none next to it
([EXPORTING.md](../exporting/EXPORTING_SETUP.md#setting-up-this-computer)). The editor has the same as buttons. By hand:

Prerequisites (the export checks them first and says what is missing and how to set it up):

- A JDK 17 or newer (Android builds are tested with 17 and 21). The export finds `JAVA_HOME`, Android Studio's bundled JDK
  and Unity Hub's; or set `android.jdk` in `~/.factoria/export.json`.
- The Android SDK (Android Studio installs it; or the command-line tools): `ANDROID_HOME`, the usual folder of your OS, or
  `android.sdk` in `~/.factoria/export.json`. Accept its licenses once: `sdkmanager --licenses`. Gradle then downloads the
  platform (`platforms;android-36`, the default `targetSdk`) and build tools it needs by itself. That is all in **prebuilt**
  mode: no NDK, no CMake.
- Only in **source** mode (engine developers): an NDK r27+ (r26's libc++ has no std::format, `ndk;27.2.12479018`) and
  CMake 3.31 (`cmake;3.31.6`; the engine needs 3.24+, the SDK default is older), so
  `sdkmanager "platforms;android-36" "build-tools;35.0.0" "ndk;27.2.12479018" "cmake;3.31.6"`. Any CMake 3.24+ works: the export
  reads the version of the SDK's newest one, or of one on your computer (offline, without `sdkmanager`) and gives it to Gradle
  through `cmake.dir` ([EXPORTING.md](../exporting/EXPORTING_MOBILE.md#android)).
- No Gradle install: the export writes the project's own Gradle wrapper, and the first build downloads Gradle, the Android
  Gradle plugin and the SDK platform (internet needed once; everything is cached after it).

Steps: `factoria export --platform android`; the app is `<out>/<game>-android/<game>-debug.apk`, then
`adb install -r <game>-debug.apk` and `adb logcat -s factoria`. The report's `nextSteps` print the exact commands.
Prebuilt: Gradle only packages `app/src/main/jniLibs/<abi>/libfactoria_player.so` and the game, which takes seconds once
Gradle and the plugin are cached. Source: the first build compiles the whole engine for two ABIs (several minutes). To build
for one ABI only, edit `abiFilters` in `app/build.gradle` of the exported project. The libraries of the download are
already stripped, so Gradle prints no strip warning for them. The project also opens directly in Android Studio.

If the build fails the export folder stays (with `build.log`) and the error names the cause when it knows it:

| Gradle says | What to do |
|---|---|
| licenses not accepted | `sdkmanager --licenses` of the SDK the error names (or Android Studio > SDK Manager > SDK Tools), then export again |
| unsupported class file version / Java version | use a JDK 17 or 21: `android.jdk` in `~/.factoria/export.json` or `JAVA_HOME` |
| SDK location not found | `ANDROID_HOME`, or `android.sdk`; the folder needs `platform-tools` and `platforms` |
| could not resolve / download / timed out | the first build needs the internet (services.gradle.org, Google Maven, dl.google.com); check the proxy, then export again |

Without Gradle (just the native library, as CI does): `export ANDROID_NDK_HOME=...; ./scripts/build-android.sh`
produces `build/android-arm64/player/libfactoria_player.so`.

Logs: `adb logcat -s factoria` (tag `factoria`: the engine log and the sokol messages; a native crash is under `libc` and `DEBUG`).

### Signing and release

Debug builds are signed with the debug key of your machine automatically; that is fine for trying the app on a phone or an
emulator, and Google Play refuses it. For release:

1. Create a keystore once, outside the project folder and outside git:
   `keytool -genkeypair -v -keystore ~/keys/upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`.
2. In `factoria.json`: `"export": {"android": {"signing": {"keystore": "/Users/me/keys/upload.jks", "alias": "upload"}}}` (the
   Platform settings window of the editor writes the same keys). The keystore is not copied into the app: a keystore inside
   the project is left out of the export, with a warning.
3. Give the passwords to the export, never to a file of the project: the environment variables
   `FACTORIA_ANDROID_KEYSTORE_PASSWORD` and `FACTORIA_ANDROID_KEY_PASSWORD` (the second defaults to the first), or
   `android.keystorePassword` / `android.keyPassword` in `~/.factoria/export.json` (this computer only, owner-readable).
4. `factoria export --platform android --release` builds `<game>.apk` (signed; check it with
   `apksigner verify --print-certs`), and `--format aab --release` builds `<game>.aab`, the bundle **Google Play takes**
   (upload it in the Play Console; with Play App Signing the key above is your upload key).

To upload the bundle from FactorIA: `publish.googleplay` runs `fastlane supply` with a service account key
(`FACTORIA_GOOGLEPLAY_JSON_KEY`) and refuses a debug-signed bundle. The first bundle of a new app must be uploaded by hand in
the Play Console; the service account, the track and the release notes are in
[EXPORTING.md](../exporting/EXPORTING_STORES.md#google-play) (`publish_googleplay {"dryRun":true}` shows the command).

The passwords reach Gradle only as environment variables of its process: they are not in `gradle.properties`, `build.gradle`,
`build.log` or any file of the export, nor on a command line. A release export without a keystore **fails** (the AAB it
would produce is one Google Play rejects), with the steps above in its hint. To try a release build on your own device with
the debug key anyway, add `--allow-debug-key` (`"allowDebugKey": true` in the `project.export` command): the export then
warns and signs with the debug key; never upload that build. A keystore that does not exist, or missing passwords, are
reported by the plan (`project.export` with `dryRun`) before Gradle starts. To build by hand inside the exported project, set the same variables and run `./gradlew assembleRelease`
(APK) or `./gradlew bundleRelease` (AAB).

### 16 KB memory pages

Android 15 devices may use 16 KB memory pages and Google Play requires apps that target Android 15+ to support them. The
player links with `-Wl,-z,max-page-size=16384` (the NDK r27 default is 4 KB), and Gradle aligns the native libraries inside
the APK to 16 KB; check an APK with `zipalign -c -P 16 -v 4 <apk>` (from the SDK's `build-tools`).

Never commit the keystore or passwords.

### Orientation

`display.orientation` in `factoria.json`: `landscape` -> `sensorLandscape`,
`portrait` -> `sensorPortrait`, `any` -> `fullSensor` in `AndroidManifest.xml`.
The app is full screen; the game renders at its design resolution with the
project's `scaleMode`.

### Lifecycle

- Going to the background and back keeps the process: the game gets `Suspended`/`Resumed` (`player: suspended`,
  `player: resumed` in the log) and the GL surface is rebuilt.
- Scripts hear it with `game.on("suspend", fn)` and `game.on("resume", fn)`; `game.on("blur", fn)` and
  `game.on("focus", fn)` fire when the window loses or gains focus (desktop, and a phone's system dialogs), and
  `game.focused` says which. Held inputs are released on suspend and blur, so no key or finger stays stuck.
- `"pauseOnSuspend"` in `factoria.json` (default `true`) freezes the simulation (`time.scale` 0, the same as
  `game.paused = true`) and the music while the app is in the background and restores them on resume. The `suspend`
  handlers run first, so a game that opens its own pause menu there (`game.paused = true`) stays paused after resume,
  waiting for the player. Set `false` for a game that must keep running (a timer, a server clock).
- Tests: `game.suspend()`, `game.resume()`, `game.blur()` and `game.focus()` in `factoria:test` do what the OS does.
- Which of `blur`, `suspend` and `quit` a platform raises: phones raise `suspend` and `resume` when the app leaves and
  returns to the foreground and `blur` and `focus` for system dialogs; they never raise `quit`. A browser tab raises `suspend`
  when it is hidden (a phone browser: when the player switches apps), `resume` when it is shown, `blur` and `focus` with the
  page's focus, and `quit` on `pagehide`; desktop windows raise `blur` and `quit` but not `suspend`. The table is in
  SCRIPTING.md ("Window close"). The web copies the save folder to IndexedDB right after those handlers run.
- Configuration changes the manifest lists (orientation, screen size, density, dark mode, locale, font size, the SIM's
  `mcc`/`mnc` and the others in `android:configChanges`) are handled in place: the game keeps running.
- A change of the app's assets paths cannot be listed: a new wallpaper colour palette or theme (Android 12+), a system
  overlay turned on or off (e.g. the display-cutout emulation of the developer options). Android then relaunches every
  activity. A destroyed NativeActivity ends the process (sokol_app exits so that the next start has fresh globals), and
  the activity is `stateNotNeeded`, so Android starts the game again in a new process: it restarts from its first
  scene, as after a cold start.
- Back and closing the game destroy the activity too; the process ends and the game is not started again.
- When the process ends this way it ends at once (`_exit`, see `engine/platform/src/sokol_impl.c`): the engine is not
  shut down and no script callback runs. Save progress while the game runs: `storage.set` writes the key's file in the
  app's internal folder immediately. The `storage.setAsync` writes still waiting are made right after the `suspend`
  handlers run, so a save in the `suspend` handler (with `set` or `setAsync`) is on disk before the process can end.

### Native plugins on Android

A native plugin ([EXTENDING.md](../EXTENDING.md), section G) has an `android/` folder in its own folder, next to its
`src/`. `factoria call project.new_plugin` writes all of it; add `"android"` to the plugin's `"platforms"` in `factoria.json`
once the library is built:

```
plugins/example/
  CMakeLists.txt  src/plugin.c  include/fa_plugin.h     the C code, built with the NDK (below)
  android/
    build.gradle                                        a Gradle library module (namespace factoria.plugin.example)
    consumer-rules.pro                                  keeps factoria.plugin.** when the app is minified
    src/main/AndroidManifest.xml                        the SDK's permissions and components, merged into the app's
    src/main/java/factoria/plugin/example/Plugin.java   the Java the C code calls through JNI (src/main/kotlin works too)
    src/main/jniLibs/<abi>/libexample.so                the library: built by CMake, not by Gradle
```

**Build the library once per ABI the engine ships**, `arm64-v8a` (phones) and `x86_64` (the emulator); `CMakeLists.txt`
copies each build to `android/src/main/jniLibs/<abi>/`:

```bash
for abi in arm64-v8a x86_64; do
  cmake -S plugins/example -B plugins/example/build/$abi -DCMAKE_BUILD_TYPE=Release -DANDROID_ABI=$abi \
        -DANDROID_PLATFORM=android-26 -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake
  cmake --build plugins/example/build/$abi
done
```

Any recent NDK works (CI uses `sdkmanager "ndk;27.2.12479018"`); `ANDROID_PLATFORM` is the game's `minSdk` (26 by default). The
template links with 16 KB pages, like the player ([16 KB memory pages](#16-kb-memory-pages)). A library missing for an
ABI is not an export error (the module may build it itself): on a device of that ABI the plugin does not load, the log
says `cannot load libexample.so` and scripts that use it get that error.

**The export** (prebuilt and source mode alike) copies the module to `plugins/<name>` of the Gradle project, without
`build/`, `.gradle/` and `.cxx/`; adds `include ':plugin_<name>'` to `settings.gradle` and
`implementation project(':plugin_<name>')` to `app/build.gradle`; declares the Android Gradle plugin for libraries in the
root `build.gradle` (the same version as the application plugin); and writes the game's SDK levels to `gradle.properties`
(`factoria.compileSdk`, `factoria.minSdk`), which the template's `build.gradle` reads. A plugin that is only `.aar` /
`.jar` files (no `build.gradle` in `android/`) has them copied to `app/libs/<name>` and added as
`implementation fileTree(dir: 'libs/<name>', include: ['*.aar', '*.jar'])`. The module's folder inside the project is
never part of the game's assets. The export fails, naming the folder (`factoria validate` warns), when `android/` has
neither a `build.gradle(.kts)` nor an `.aar` / `.jar`.

**Java code and `hasCode`.** The manifest has `android:hasCode="true"` in every export: the engine is native except for
one Java class, `factoria.engine.Ime` (`app/src/main/java/factoria/engine/Ime.java`, the input method connection that lets
a keyboard compose into a `TextField`, [TEXT.md](../TEXT.md#what-composes-where)), and a plugin's Java or Kotlin code,
`.aar` or `.jar` files are loaded with it. A project that keeps its own manifest with `android:hasCode="false"` still
runs: the keyboard then sends keys only, and the log says so once. The exported project
allows Google and Maven Central as repositories, and Gradle refuses repositories declared in a module
(`FAIL_ON_PROJECT_REPOS`): an SDK from another repository ships as `.aar` files.

**Manifest placeholders for ads.** The template's `app/build.gradle` defines three manifest placeholders that the `admob` plugin's manifest
uses (`<meta-data>` for the AdMob app id, the test flag and the audience), read from `gradle.properties`, where the export writes them:
`factoria.ads.appId` (Google's sample app id in a development export; `platform.ads.appIds.android` in a `--release` export, the sample id when the
catalog has none), `factoria.ads.test` (`true` unless `--release`) and `factoria.ads.audience` (`platform.ads.audience`). A game without the
plugin carries no `<meta-data>` for them, so nothing changes. [PLATFORM.md](../platform/PLATFORM_ADS.md#8-ads-google-admob-and-consent-on-android-and-ios)
has the ads side.

**AndroidX.** The template's `gradle.properties` sets `android.useAndroidX=true`: the Google SDKs a plugin brings (Play
Billing, Play Games, Play Integrity) depend on AndroidX libraries, and Gradle refuses to build them without it. The player
itself uses no AndroidX code, so nothing in a game without such a plugin changes.

**Calling Java from C.** `api->native_handle("android.activity")` is the game's `ANativeActivity*`: `->vm` is the
`JavaVM*` for JNI and `->clazz` the activity object. The game's thread is not attached to the VM, so attach it for the
call (`GetEnv`, then `AttachCurrentThread` and `DetachCurrentThread` when it was detached). `FindClass` on a native thread
only sees the system's classes: load the plugin's own classes through the activity's class loader
(`getClassLoader().loadClass("factoria.plugin.example.Plugin")`), then call the static method. Check for a pending Java
exception after each call that can throw and clear it (`ExceptionDescribe` logs it and clears it): JNI calls with an
exception pending are undefined, and the checked JNI of debug builds and emulators aborts the process. `src/plugin.c` of the template does all of this for `add(a, b)`: copy `java_add` and `add_in_java` for your own
calls.

CI covers it: the `android-apk` job scaffolds this plugin outside the game (`${FA_CI_PLUGINS}/example`), builds
`libexample.so` for both ABIs, exports, and checks that the APK carries both libraries and `factoria/plugin/example/Plugin`
in its dex; `android-emulator` then checks that the game's script got `add(1, 2) = 3` from the Java class and the output
of `example.info` (`FA_SMOKE_EXPECT` of `scripts/android-smoke.sh`).
