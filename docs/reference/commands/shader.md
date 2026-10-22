[Back to the index](../README.md)

# Commands: shader

## `shader.compile`

Since 0.2.0.

Compile a custom material's GLSL snippet for the dialects of some platforms and report errors with file, line and fixes.

Checks the material file (*.material.json, schemas/material.schema.json) and compiles its snippet with sokol-shdc, injected into the engine's mesh shader, for every shader dialect of the platforms asked (default: all six: hlsl5 for Windows, glsl430 for Linux, metal_macos, metal_ios and metal_sim for macOS and iOS, glsl300es for Android and web). Some errors exist in one dialect only (a gradient inside a loop is fine in GLSL and refused by HLSL), so compile for the platforms you ship. Returns {ok, material, dialects, errors: [{file, line, column, message, hint, source}], cached}: a snippet error is mapped to the line of your snippet, with the offending line in `source` and a fix in `hint` (an unknown field of Surface gets "did you mean albedo?", texture(waves, uv) gets the separate-sampler form); a mistake in the material file has a JSON `pointer` instead of a line. Fix the file and call again until ok, then look at the result with game.screenshot. Results are cached in .factoria/shader-cache by content, so an unchanged material compiles instantly. Needs sokol-shdc: the factoria downloads carry it next to factoria; otherwise `factoria setup shaders` installs it, or set SOKOL_SHDC. The snippet is GLSL 450 (Vulkan style) with no @ tags and no main: `void surface(in SurfaceInput i, inout Surface s)` is required, `void vertex(inout VertexData v)` optional. Params are globals named like the JSON keys; textures are sampled with texture(sampler2D(name, name_smp), uv); names starting with fa_ are the engine's. Example: {"material": "materials/water.material.json", "platforms": ["windows", "web"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/water.material.json (the .material.json suffix may be left out). |
| `platforms` | array | no | Platforms whose shader dialects to compile for. Omit for all. |

