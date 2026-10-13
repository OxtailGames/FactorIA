# Vendored third-party code

All dependencies are vendored (copied verbatim) so the engine builds offline on
every platform with nothing but CMake and a C/C++ compiler. Do not edit files in
`external/` — wrap or patch from engine code instead. To upgrade, replace the
files and update this table.

| Library | Version / commit | License | Used by | Purpose |
|---|---|---|---|---|
| [sokol](https://github.com/floooh/sokol) | `5e94d12` (2026-10-12) | zlib | platform, render, audio | Window/app loop on all platforms, GPU abstraction (Metal, D3D11, GL, GLES3, WebGPU), audio stream, timing |
| [QuickJS-ng](https://github.com/quickjs-ng/quickjs) | `v0.17.0` | MIT | script | Embedded JavaScript (ES2023) for gameplay scripts |
| [Box2D](https://github.com/erincatto/box2d) | `v3.1.1` | MIT | physics | 2D rigid-body physics |
| [Dear ImGui](https://github.com/ocornut/imgui) | `v1.92.9b-docking` | MIT | editor | Immediate-mode editor UI |
| [stb](https://github.com/nothings/stb) | `2c980bb` (2026-08-01) | MIT / Public domain | render, audio | PNG/JPG decode + PNG encode, TrueType fonts, rect packing, Ogg Vorbis |
| [cgltf](https://github.com/jkuhlmann/cgltf) | `85cd623` (2026-02-02) | MIT | render | glTF 2.0 model loading |
| [dr_libs](https://github.com/mackron/dr_libs) | `dfe8377` (2026-09-01) | MIT-0 / Public domain | audio | WAV and MP3 decoding |
| [nlohmann/json](https://github.com/nlohmann/json) | `v3.12.0` | MIT | everywhere | JSON (scenes, project files, MCP, AI APIs) |
| [doctest](https://github.com/doctest/doctest) | `v2.4.12` | MIT | tests | C++ unit tests |

## Tools (not vendored)

`sokol-shdc` (shader cross-compiler) is fetched on demand by
`tools/shaders/fetch_shdc.sh` into `.cache/` (gitignored). Generated shader
headers are committed, so a normal build never needs it.
