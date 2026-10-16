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

The engine's docs/EXTENDING.md ("Native plugins") has the details: `factoria docs read extending`.
