# {{NAME}}: a native plugin

A native plugin of a FactorIA game: C (or C++, or anything that exports C functions) that adds script functions
(`plugins.{{NAME}}.add(1, 2)`) and commands (`factoria call {{NAME}}.info`). The game declares it in `factoria.json`:

```json
"plugins": { "{{NAME}}": { "path": "plugins/{{NAME}}", "platforms": ["windows"] } }
```

- `src/plugin.c`: the plugin. `include/fa_plugin.h` is the whole API, with its rules.
- `CMakeLists.txt`: builds it and copies the library into this folder, one subfolder per platform:
  `windows/{{NAME}}.dll`, `macos/lib{{NAME}}.dylib`, `linux/lib{{NAME}}.so`. Libraries it needs go next to it.

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

Then `factoria run` loads it, `factoria validate` reports a missing build, and `factoria export` puts the library next
to the game's executable. Add a platform to `"platforms"` once the plugin is built for it. The folder may live outside
the game (a private SDK): write its path as `"${MY_PLUGINS}/{{NAME}}"` and set the environment variable.

## Android

`android/` is a Gradle library module that the Android export adds to the game's app. Its Java code
(`src/main/java/factoria/plugin/{{NAME}}/Plugin.java`) is what `src/plugin.c` calls through JNI to compute `add`; an SDK's
Java API is reached the same way. The native library is not built by Gradle: build it once per ABI the engine ships
(`arm64-v8a`, `x86_64`) with the NDK's CMake toolchain file, and `CMakeLists.txt` copies each build to
`android/src/main/jniLibs/<abi>/lib{{NAME}}.so`, where the module packages it into the APK:

```bash
for abi in arm64-v8a x86_64; do
  cmake -S . -B build/android-$abi -DCMAKE_BUILD_TYPE=Release -DANDROID_ABI=$abi -DANDROID_PLATFORM=android-26 \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake
  cmake --build build/android-$abi
done
```

Add `"android"` to `"platforms"`, then `factoria export --platform android`. Keep the Java classes the C code looks up by
name in the package `factoria.plugin.{{NAME}}`: `consumer-rules.pro` keeps `factoria.plugin.**` when the app is minified.
A plugin that ships only `.aar` or `.jar` files can put them in `android/` instead of a module.

The engine's docs/EXTENDING.md ("Native plugins") has the details: `factoria docs read extending`.
