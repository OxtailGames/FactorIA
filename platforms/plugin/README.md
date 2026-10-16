# {{NAME}}: a native plugin

A native plugin of a FactorIA game: C (or C++, or anything that exports C functions) that adds script functions
(`plugins.{{NAME}}.add(1, 2)`) and commands (`factoria call {{NAME}}.info`). The game declares it in `factoria.json`:

```json
"plugins": { "{{NAME}}": { "path": "plugins/{{NAME}}", "platforms": ["windows"] } }
```

- `src/plugin.c`: the plugin. `include/fa_plugin.h` is the whole API, with its rules.
- `CMakeLists.txt`: builds it and copies the library into this folder, one subfolder per platform:
  `windows/{{NAME}}.dll`, `macos/lib{{NAME}}.dylib`, `linux/lib{{NAME}}.so`. Libraries it needs go next to it.
  On iOS: a static library per SDK, `ios/iphoneos/lib{{NAME}}.a` and `ios/iphonesimulator/lib{{NAME}}.a`.

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

For iOS, on a Mac with Xcode, build both SDKs (the device and the simulator; the export needs both):

```bash
cmake -S . -B build-iphoneos -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos -DCMAKE_OSX_DEPLOYMENT_TARGET=16.3
cmake --build build-iphoneos --config Release -- -sdk iphoneos
cmake -S . -B build-iphonesimulator -G Xcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphonesimulator -DCMAKE_OSX_DEPLOYMENT_TARGET=16.3
cmake --build build-iphonesimulator --config Release -- -sdk iphonesimulator
```

`factoria export --platform ios` links those libraries into the app (`factoria docs read mobile`, "Native plugins (iOS)").

Then `factoria run` loads it, `factoria validate` reports a missing build, and `factoria export` puts the library next
to the game's executable. Add a platform to `"platforms"` once the plugin is built for it. The folder may live outside
the game (a private SDK): write its path as `"${MY_PLUGINS}/{{NAME}}"` and set the environment variable.

The engine's docs/EXTENDING.md ("Native plugins") has the details: `factoria docs read extending`.
