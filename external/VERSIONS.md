# Vendored third-party code

All dependencies are vendored (copied verbatim) so the engine builds offline on
every platform with nothing but CMake and a C/C++ compiler. Do not edit files in
`external/` — wrap or patch from engine code instead. To upgrade, replace the
files and update this table. A new library also goes in `third_party_components()`
(`tools/common/src/notices.cpp`): its license text then ships with the downloads and
every exported game, and a tooling test fails until it is there.

| Library | Version / commit | License | Used by | Purpose |
|---|---|---|---|---|
| [sokol](https://github.com/floooh/sokol) | `5e94d12` (2026-10-12) | zlib | platform, render, audio | Window/app loop on all platforms, GPU abstraction (Metal, D3D11, GL, GLES3, WebGPU), audio stream, timing |
| [QuickJS-ng](https://github.com/quickjs-ng/quickjs) | `v0.17.0` | MIT | script | Embedded JavaScript (ES2023) for gameplay scripts |
| [Box2D](https://github.com/erincatto/box2d) | `v3.1.1` | MIT | physics | 2D rigid-body physics |
| [Dear ImGui](https://github.com/ocornut/imgui) | `v1.92.9b-docking` | MIT | editor | Immediate-mode editor UI |
| [stb](https://github.com/nothings/stb) | `2c980bb` (2026-08-01) | MIT / Public domain | render, audio | PNG/JPG decode + PNG encode, TrueType fonts, rect packing, Ogg Vorbis |
| [cgltf](https://github.com/jkuhlmann/cgltf) | `85cd623` (2026-02-02) | MIT | render | glTF 2.0 model loading |
| [Basis Universal](https://github.com/BinomialLLC/basis_universal) | `v2.50` (`9bebe16`) | Apache-2.0 (encoder extras: BSD-3-Clause, MIT) | render (transcoder), tooling (encoder) | KTX2 textures: the transcoder turns them into ASTC, BC7 or ETC2 at load time; `factoria export` encodes them (UASTC, ETC1S) |
| [HarfBuzz](https://github.com/harfbuzz/harfbuzz) | `14.6.0` (2026-10-05) | MIT | render | Text shaping: ligatures, kerning, Arabic joining, Hebrew, Indic scripts and the other complex scripts |
| [SheenBidi](https://github.com/Tehreer/SheenBidi) | `v3.0.0` (2026-01-24) | Apache-2.0 | render | Unicode Bidirectional Algorithm: paragraph direction and embedding levels for right-to-left text |
| [dr_libs](https://github.com/mackron/dr_libs) | `dfe8377` (2026-09-01) | MIT-0 / Public domain | audio | WAV and MP3 decoding |
| [qoa](https://github.com/phoboslab/qoa) | `bc05897` (2026-09-27) | MIT | audio, tooling | QOA audio: decoding in the engine, WAV to QOA conversion in `factoria export` |
| [nlohmann/json](https://github.com/nlohmann/json) | `v3.12.0` | MIT | everywhere | JSON (scenes, project files, MCP, AI APIs) |
| [doctest](https://github.com/doctest/doctest) | `v2.4.12` | MIT | tests | C++ unit tests |
| [SDL_GameControllerDB](https://github.com/mdqinc/SDL_GameControllerDB) (Linux lines only; data, not code) | `c1d5289` (2026-10-02) | zlib | platform | Gamepad mappings for Linux pads (`external/sdl_gamecontrollerdb/`, embedded in the binary) |

`external/basis_universal/` holds `transcoder/` and `encoder/` unmodified, minus what the engine cannot use: the
WebAssembly bindings (`encoder/basisu_wasm_*`) and `encoder/basisu_xbc7_encode.cpp` (XBC7, an experimental format; it
includes zstd unconditionally and zstd is not vendored). `external/CMakeLists.txt` builds the transcoder into every
player with only the output formats the engine asks for (ASTC 4x4, BC7, ETC2 RGBA8, RGBA8) and no Zstandard
supercompression, and the encoder into `fa_tooling` only, where it stubs the two XBC7 functions `basisu_comp.cpp` calls.

`external/harfbuzz/` holds the 14.6.0 release's `src/` reduced to the files `src/harfbuzz.cc` (its amalgamation) includes,
unmodified, plus `COPYING`: no tests, no subsetter sources, no FreeType/ICU/GLib/CoreText/DirectWrite glue (those compile to
nothing without their `HAVE_*` macros). `external/CMakeLists.txt` builds it with `HB_LEAN` and `HB_NO_AAT`. `external/sheenbidi/`
holds `Headers/` and `Source/` of the v3.0.0 release, built through its unity file `Source/SheenBidi.c` (`SB_CONFIG_UNITY`).

## Tools (not vendored)

`sokol-shdc` (shader cross-compiler) is fetched on demand by
`tools/shaders/fetch_shdc.sh` into `.cache/` (gitignored). Generated shader
headers are committed, so a normal build never needs it.
