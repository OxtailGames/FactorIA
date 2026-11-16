# Mobile: Android and iOS, page 2 of 4

Part of [Mobile: Android and iOS](../MOBILE.md) (the entry page lists every page).

## iOS

Prerequisites: macOS, the full Xcode app (not only command line tools; run
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`), CMake 3.24+,
an Apple developer team for devices (a free Apple ID works for your own device). `factoria setup` checks them,
`factoria setup cmake` installs CMake and `factoria setup xcode` opens Xcode's App Store page and lists the steps that need
your password ([EXPORTING.md](../exporting/EXPORTING_SETUP.md#setting-up-this-computer)).

Steps: `factoria export --platform ios`, then on the Mac, in the exported folder:

```bash
./build_ios.sh --simulator --run                          # build, start in the iOS Simulator, console in the terminal
FA_IOS_DEVELOPMENT_TEAM=<TEAMID> ./build_ios.sh --run     # the same on the connected iPhone or iPad (see teamId below)
./build_ios.sh [--simulator] --build [-- <xcodebuild arguments>]   # only build (the .app path is printed)
./build_ios.sh [--simulator]                              # create build/FactorIA.xcodeproj and open it in Xcode
```

`--run` installs the app and starts it with its console (stdout and stderr, so the engine log) in the terminal; Ctrl+C
ends the game. Simulator builds need no team: they are built unsigned and signed ad hoc. In Xcode instead: choose the
`factoria_player` scheme, set Team under Signing & Capabilities and press Run.

#### Play a replay on the Simulator

`simctl` can neither tap nor rotate, so the player does both itself when the Simulator starts it with two environment
variables: `FA_INPUT_REPLAY=<replay.json>` (the file `input.record` writes, the one `factoria run --input` plays; the
Simulator reads the Mac's disk) and `FA_ORIENTATION=portrait|landscape`. The command `player.run_ios_sim` sets both, boots a
simulator (an iPhone, or an iPad with `device`), installs the `.app`, waits for the player's `player: replay done after N
frames` line, takes a screenshot and stops the app:

```bash
factoria call player.run_ios_sim '{"app":"build/export/my-game-ios/build/Debug-iphonesimulator/factoria_player.app",
  "input":"replays/play.json","device":"iPad Pro 13-inch","orientation":"landscape","screenshot":"build/ipad.png"}'
```

`dryRun: true` prints the `simctl` commands and runs nothing, on any computer. The replay's presses, keys, mouse, touch and
gamepad entries are applied by frame number to the frames the window runs, which last as long as the screen takes (not the
fixed step of a headless run), so a game that moves by `dt` may end up elsewhere than in the recording: look at the screenshot.
iOS only turns the screen to an orientation the Info.plist allows (`display.orientation`, `export.ios`). Only a Mac with Xcode
runs it; a real iPad is a different check (`./build_ios.sh --run`), and so is a real touch.

The export fills in what `factoria.json` says (`icon`, `export.ios`; [EXPORTING.md](../exporting/EXPORTING_SETUP.md#platform-settings)):
`export.ios.teamId` is the default of `FA_IOS_DEVELOPMENT_TEAM` inside `build_ios.sh` (the environment variable still
wins, so one script serves several developers), `export.ios.buildNumber` is the app's `CFBundleVersion` (the `version` is
`CFBundleShortVersionString`), and the icon is the `Assets.xcassets` next to the script (an opaque 1024x1024 `AppIcon`
over `export.ios.iconBackground`).

A device needs, once: a cable (or the same network after the first pairing), "Trust this computer" accepted on it,
Developer Mode on (Settings > Privacy & Security > Developer Mode; it restarts the device; the switch shows up only after
the device was connected to Xcode once), and a team. The team id is the `OU` of your "Apple Development" certificate
(`security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject`) or Xcode > Settings > Accounts; a
free Apple ID works for your own devices. The first build for a team registers the connected device with it and
creates the provisioning profile (`xcodebuild -allowProvisioningDeviceRegistration`), which needs the device connected
during the build: `build_ios.sh` picks the first connected iPhone or iPad (`FA_IOS_DEVICE=<udid>` picks another,
`xcrun devicectl list devices` lists them). Building for "any device" with no device connected fails on a team's first
build with "Your team has no devices from which to generate a provisioning profile".

**Prebuilt** (the macOS download): the export holds a small `CMakeLists.txt`, `cmake/` and `lib/<iphoneos|iphonesimulator>/*.a`
next to `game/`, and `build_ios.sh` configures that folder. No engine source is needed, only Xcode and CMake. The libraries
are the player and the whole engine as static archives (`libfactoria_player_main.a` is the player: `main` comes from
`sokol_app` inside `libfa_platform.a`); the exported project links the archives of the SDK it is configured for, with the
same frameworks as the engine presets. There is no XCFramework because the exported project is configured per SDK (device
or simulator), like the `ios` presets, and CMake's Xcode generator (3.24) cannot link one. The simulator archives hold
`arm64` and `x86_64`. The iOS libraries are in the macOS package only (the Windows and Linux ones carry Android), but you
can still prepare an iOS project on Windows or Linux: `factoria setup players --platforms mobile` downloads the macOS
package and keeps its `mobile/` (Android and iOS) under `~/.factoria/players/<version>/mobile`, and `factoria export
--platform ios` finds it there, with no `--mobile-dir`. Copy the exported folder to a Mac to build it. **Source**: the export holds only `game/` and `build_ios.sh`, which runs CMake on the engine checkout.

`build_ios.sh` runs the CMake named by `FACTORIA_CMAKE` when it is set, else the CMake 3.24+ the export found
(`factoria setup cmake` installs one when there is none), else `cmake` from `PATH`.

Direct use of the engine checkout (no export):

```bash
cmake --preset ios-simulator -DFA_GAME_PROJECT_DIR=/path/to/game -DFA_GAME_BUNDLE_ID=com.example.mygame \
      -DFA_GAME_NAME="My Game" -DFA_GAME_VERSION=1.0.0 -DFA_GAME_ORIENTATION=portrait
cmake --build --preset ios-simulator --target factoria_player -- -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO
```

CMake variables: `FA_GAME_PROJECT_DIR`, `FA_GAME_BUNDLE_ID`, `FA_GAME_NAME`,
`FA_GAME_VERSION`, `FA_GAME_BUILD` (`CFBundleVersion`; default `FA_GAME_VERSION`), `FA_GAME_ORIENTATION`,
`FA_GAME_ASSET_CATALOG` (path of an `.xcassets` folder with an `AppIcon` set; no icon when empty),
`FA_GAME_PRIVACY_MANIFEST` (a `PrivacyInfo.xcprivacy` copied to the root of the app),
`FA_GAME_NON_EXEMPT_ENCRYPTION` (`ON` writes `ITSAppUsesNonExemptEncryption` as true; default `OFF`) and
`FA_IOS_DEVELOPMENT_TEAM`. They feed
`platforms/ios/Info.plist.in` (full screen, MetalKit, orientation lists for
iPhone and iPad, launch screen via `UILaunchScreen`) and the Xcode target (the catalog is compiled into `Assets.car`,
`ASSETCATALOG_COMPILER_APPICON_NAME` is `AppIcon`). The game folder is copied
into the bundle after linking with the same exclude rules as `factoria export`
(`platforms/common/copy_game.cmake`). Without `FA_GAME_PROJECT_DIR` the app
starts with a red screen and logs why.

### Native plugins (iOS)

A game's native plugins ([EXTENDING.md](../EXTENDING.md), section G) are static libraries on iOS, linked into the app. The
plugin's folder holds one per SDK: `ios/iphoneos/lib<name>.a` (arm64) and `ios/iphonesimulator/lib<name>.a` (arm64 and
x86_64, like the player's simulator libraries). The template's `CMakeLists.txt` builds them with CMake's Xcode generator,
one SDK at a time (the commands are in its `README.md`), and defines `FA_PLUGIN_STATIC`, so that `FA_PLUGIN_INIT(<name>)`
defines `fa_plugin_init_<name>` instead of the exported `fa_plugin_init`: several plugins live in one executable.

`factoria export --platform ios` needs both libraries of every plugin declared for iOS (it names the missing file) and
copies the plugin's `ios/` folder to `plugins/<name>/` next to `build_ios.sh`, which passes `-DFA_GAME_PLUGINS=<name;name>`
and `-DFA_GAME_PLUGIN_DIR=<export>/plugins` to CMake. In both modes (`platforms/ios/plugins.cmake`, used by
`player/CMakeLists.txt` and by the exported `CMakeLists.txt`) the app links the libraries of the SDK it is configured for
and gets a generated source that calls `fa_register_static_plugin("<name>", fa_plugin_init_<name>)` from a static
constructor, before `main` (the source is the app's own, not an archive's, so the linker keeps it). The engine finds the
registered entry point instead of loading a library. A plugin declared for iOS that
the app was built without (no `FA_GAME_PLUGINS`) logs the warning "it is not linked into the app", and a script that uses
it gets that reason as an error, as for any plugin that does not load.

Direct use of the engine checkout: add `-DFA_GAME_PLUGINS=example -DFA_GAME_PLUGIN_DIR=/path/to/plugins` to the
`cmake --preset ios-simulator` command above, with `/path/to/plugins/example/iphonesimulator/libexample.a` in place (the
device build needs `iphoneos/`). CI does this with the example plugin (the `ios` job runs `scripts/ios-smoke.sh` with
`FA_IOS_PLUGIN_PROBE=1`).

**The plugin manifest, `ios/plugin.json`.** A static library cannot say which system frameworks it uses, whether it is
written in Swift, or which capabilities the signed app needs. The plugin says so in `ios/plugin.json` (optional; a plugin
without one needs nothing):

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

| Key | Meaning | What the export does |
|---|---|---|
| `frameworks` | System frameworks the plugin's code uses, by name (`"StoreKit"`, no `.framework`). | `build_ios.sh` passes `-DFA_GAME_PLUGIN_FRAMEWORKS=StoreKit;GameKit`; `platforms/ios/plugins.cmake` links each into the app. |
| `swift` | `true`: the plugin is written in Swift. | `-DFA_GAME_PLUGIN_SWIFT=ON`: the app gets what Xcode adds to a target with Swift code: the toolchain's Swift library folder for the SDK (the back-deployment libraries a Swift static library asks for) and the run path to the OS's Swift runtime, `/usr/lib/swift`. |
| `xcframeworks` | Vendored XCFrameworks, relative to the plugin's `ios/` folder (`"frameworks/GoogleMobileAds.xcframework"`). | The export checks that each is in the copied plugin (`plugins/<name>/frameworks/...`; it fails naming the file and how to get it when not) and has an iOS slice. `-DFA_GAME_PLUGIN_XCFRAMEWORKS=...`: `platforms/ios/plugins.cmake` links the slice of the SDK the app is built for (device or simulator). A **static** XCFramework (a `.a` or a static `.framework`) is only linked; a **dynamic** one is also embedded in the app's `Frameworks/` folder and code signed (`-DFA_GAME_PLUGIN_EMBED_XCFRAMEWORKS`). A game with XCFrameworks links with `-ObjC`, so that Objective-C categories of a static SDK load. |
| `infoPlist` | Keys the plugin needs in the app's `Info.plist`: any plist value, written as JSON (strings, booleans, numbers, lists, objects: `SKAdNetworkItems` is a list of objects). | The export writes them into `InfoPlistExtra.xml` next to `build_ios.sh` (`-DFA_GAME_INFO_PLIST_EXTRA`) and `Info.plist.in` inserts them. Two plugins that set the same key to different values fail the export, naming both. |
| `entitlements` | Capabilities of the signed app: a key to a boolean, number, string or list of strings. `$(TeamIdentifierPrefix)` and `$(CFBundleIdentifier)` are Xcode's build settings. | The entitlements of all plugins are merged into `factoria_player.entitlements` next to `build_ios.sh` (`-DFA_GAME_ENTITLEMENTS=...`, which the project's `CODE_SIGN_ENTITLEMENTS` points to), so Xcode's automatic signing turns the capabilities on for the App ID. Two plugins that ask for the same entitlement with different values fail the export, naming both. |

A manifest with a mistake (an unknown key, a wrong type) fails the export with the file, the JSON pointer and a "did you
mean". The AdMob plugin ([PLATFORM.md](../platform/PLATFORM_ADS.md#ads-on-ios)) is the example of `xcframeworks` and `infoPlist`: Google's two
XCFrameworks (a download, copied in by `platform.add_backend` with `"sdk"`, ignored by git) and the `SKAdNetworkItems` list; the
export adds the app id (`GADApplicationIdentifier`) and, for the tracking sheet, `NSUserTrackingUsageDescription`, translated to
an `InfoPlist.strings` per language of the game (`<tag>.lproj/InfoPlist.strings`, copied into the app) when
`platform.ads.trackingDescriptionKey` is set and the game is localized. The Apple plugin ([PLATFORM.md](../platform/PLATFORM_APPLE_GOOGLE.md#6-apple-storekit-2-game-center-and-icloud)) is the example of all
three keys: Swift code built with `xcrun swiftc`, StoreKit and GameKit, Game Center and iCloud entitlements. When the catalog has `platform.products`, the export also writes `Products.storekit` (a StoreKit
configuration made from the catalog, one localization per language of the game, with or without the plugin) and `build_ios.sh` references it from the Xcode scheme (`storekit_scheme.cmake`, run
after CMake generates the project): running the project from Xcode sells the products without App Store Connect.
`./build_ios.sh --run` launches with `simctl`, which does not use it.

A plugin written in Swift builds with the Xcode toolchain (`xcrun swiftc`; the Apple plugin's `CMakeLists.txt` is the
example): one static library per SDK, and an entry point defined with `@_cdecl` that a small C file
(`fa_plugin_init_<name>`) calls. Third-party code comes as an XCFramework (`xcframeworks` above). Not supported yet: Swift
packages and CocoaPods. A plugin for macOS that has no SDK for it (AdMob) registers nothing and logs why, so the service is
missing there instead of failing.

App Store: archive from Xcode (Product > Archive) with a distribution
certificate and provisioning profile, and export the archive as an `.ipa` (Organizer > Distribute App > App Store Connect >
Export). `publish.appstore` uploads that `.ipa` to App Store Connect and TestFlight with an App Store Connect API key: the key,
the build number, the processing time and what to do in TestFlight are in [EXPORTING.md](../exporting/EXPORTING_STORES.md#app-store-connect-testflight)
(`publish_appstore {"dryRun":true}` shows the `xcrun altool` command; it runs on a Mac). The icon comes from the game's `icon` (without one the app has the default
icon and the export warns); the launch screen is the plain `UILaunchScreen` of `Info.plist.in`, change it in Xcode
if you want a branded one. Raise `export.ios.buildNumber` for every upload. What the two stores ask about privacy is in
[Store privacy forms](MOBILE_PRIVACY.md#store-privacy-forms).
