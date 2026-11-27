Part of [RENDERING_LIGHTING.md](RENDERING_LIGHTING.md): lightmaps, baking, light probes and mixed lights. The Light, the scene settings and the rest of the M73 lighting are on that page.

# Rendering: lightmaps and baked light (M73.4)

A lightmap is light computed once and stored in an image: the diffuse light of the sun, the lights of mode `baked` and the sky, with the
bounces between surfaces, so a static level looks lit by global illumination for the price of one texture read. The `lightmap.bake`
commands compute it (see "Baking" below); the renderer draws it (the rest of this section).

**What you set.** `SceneSettings.lightmaps` is the project path of a manifest (`scenes/level.lightmap.json`). It lists, for each entity
(by its stable id), the mesh it was baked for, the page (a Radiance `.hdr` next to it) and the rectangle of the page that is its
lightmap. The renderer loads it with the scene and reads it again when a file changes on disk, so a new bake shows up without a restart.
An entity is lit by its lightmap when it is listed, has `MeshRenderer.receiveGI` on and `lightmapScale` above 0, and is not skinned.

**What it looks like.** The baked light **replaces** the ambient light and the sky's diffuse light on that surface (it already holds
them); the sky's reflections stay, and so do realtime lights. A light with `mode: "baked"` does not light a lightmapped entity at run time
(its light is in the page) but does light every entity that has no lightmap entry, so a scene shows no dark objects before it is
baked. `mode: "mixed"` and `realtime` lights are drawn as always. An entity that is not listed, or whose page or mesh cannot be used,
is drawn exactly as without lightmaps.

**Lightmap UVs.** A lightmap needs every triangle to have its own place in the unit square. The model's second UV set (glTF
`TEXCOORD_1`) is used when every part has it (it must be inside 0..1 without overlap: author it that way); any other mesh, the
primitives included, gets a generated unwrap (xatlas, with a gutter between the charts): the same mesh gives the same unwrap on every run
of one build (single-threaded, no seed, the engine's own trigonometry), and it is kept in memory with the mesh (nothing is written next to
the model). Another compiler or platform is not guaranteed to give the same bits, and the manifest stores a hash of the geometry with its
unwrap UVs: when it differs, the entity is reported as `lightmap-stale` and drawn without a lightmap until it is baked again on that
build. A project that ships to several platforms should give its meshes their own `TEXCOORD_1`, which every build reads as it is. A mesh with more than 250,000 triangles and no `TEXCOORD_1` cannot be
unwrapped: give it one or use a lower-poly mesh for the bake. The unwrap splits vertices along the seams of its charts, so a
lightmapped entity is drawn from vertices of its own, and it is not batched with other entities.

**Files.** The manifest is JSON (`version`, `uvVersion`, `settingsHash`, `pages`, `entities`); a page is a Radiance `.hdr` whose first row
is the top, with page uv (0, 0) at the top-left; a texel is the irradiance divided by pi (what a white diffuse surface shows) in linear
colour. The page uv of a lightmap uv is `uv * (sx, sy) + (ox, oy)` of the entity's `scaleOffset`. Mistakes are named with the file and the
JSON pointer, with what to change, and the scene is drawn without the lightmap: an unknown key, a page that is missing, an entry whose
mesh is not the one that was baked (the model changed: bake again, `render.assets` lists it as `lightmap-stale`).

**With your own materials.** The engine's own mesh shader and a custom mesh material that lists `"uv1"` in `vertexAttributes` (docs/SHADERS.md) are lightmapped; on a lightmapped entity that material's `uv1` is the lightmap UV, not the model's second UV set, so a
material that textures with `uv1` should not be on a lightmapped entity (set `receiveGI` to false there). A full-shader material and a
material that reads compute buffers are never lightmapped. A material that does not list `"uv1"` is not lightmapped either: it has
no place to get the UV from.

**The texel density.** `MeshRenderer.lightmapScale` multiplies the bake's `texelsPerMeter` (16 by default): 16 texels per metre times
`lightmapScale`, and 0 means the entity is never lightmapped. `lightmap_texels_per_meter` (C++, `fa/scene/lightmap_manifest.h`) gives the number.

## Baking

`lightmap.bake` (one call, waits for the end), or `lightmap.bake_start` with `lightmap.bake_status` and `lightmap.bake_cancel` (a job that
runs on the engine's job threads, so the editor and an agent stay responsive), compute the lightmaps of the open scene and write them next
to it. The editor's **View > Lightmap** window starts a bake, shows the phase and a progress bar, and has a Cancel button.

```
factoria call lightmap.bake '{"texelsPerMeter":16,"samples":64}' --project .
factoria call lightmap.bake_start '{}' --project .          # -> {"job":"bake:1"}  (inside one engine: the editor, MCP, a --batch)
factoria call lightmap.bake_status '{"job":"bake:1"}'        # -> {"state":"running","phase":"trace","progress":0.4,"etaSeconds":12,...}
factoria call lightmap.bake_cancel '{"job":"bake:1"}'
```

**What is baked.** The scene's `Light` entities of mode `baked` (the whole light) and `mixed` (only the indirect light: the direct light stays
realtime, so its shadows and highlights move), a `realtime` light is left out. The sky comes from `sky`: `auto` (the environment map when the scene
has one, else the ambient light), `environment`, `gradient` (`skyColor` and `horizonColor`), `ambient` or `none`. A `physicalSky` or a
`skyMaterial` cannot be evaluated by the baker: the bake uses the gradient and says so in `warnings`. A light's `intensity`, colour,
`range` and `falloff` (the engine's or the inverse-square one), the spot cone, and the softness of a light (`shadowSoftness` when `shadowFilter` is `pcss`, the size of an
area light) are mapped; `Disc` and `Tube` area lights are baked as rectangles of the same area (a disc as the square of the same area, a tube as
its length by its thickness). Meshes with `emissive` light the scene through the bounces. Every active `MeshRenderer` is part of the scene the rays hit: it
shadows and bounces light unless `castShadows` or `contributeGI` is off (turn `contributeGI` off on what moves, so it leaves no shadow in the
lightmaps); only those with `receiveGI` on, `lightmapScale` above 0 and no `unlit` get a lightmap. Textures are not read: a surface bounces its
`color` (and `emissive`). A skinned mesh is baked in its bind pose.

**Where it goes.** `path` (default: the scene's name with `.lightmap.json`, `scenes/main.lightmap.json`) names the manifest; the pages are
`<name>.lightmap.<hash>.<n>.hdr` next to it, written first (a page with the same bytes is not written again), the manifest last. A file that is
being written fails with the path and what to close (a Windows file open in another program cannot be replaced; close it and call again,
or pass another `path`); the files of a failed bake are removed. After a good bake the pages of the same name that the new manifest no
longer uses are deleted. The entities' squares are packed into pages of at most `maxPageSize` texels (up to 256 pages), `texelsPerMeter`
per metre of surface, with a gutter of `dilatePasses` texels (default 4, 0..64): the empty texels around each baked piece are filled with the mean of the filled ones next to them, one texel further per pass, so bilinear filtering does not bleed. Texels farther than that from a piece stay empty (black), so a mesh whose UVs are read past the gutter shows dark edges. Only the border of each chart is extended: the seams between two charts are not stitched, so a seam can show a step of light.

**It shows at once.** The bake asks the renderer to read the manifest again and, with `apply` (the default), sets `SceneSettings.lightmaps`
to it **in memory**: a later `factoria call` starts a new engine from the files, so keep the setting with `scene.save` in the same batch
(`factoria call --batch`), or write `"lightmaps": "scenes/main.lightmap.json"` into the scene's `settings` once. The editor does it as one
undo step and marks the scene as changed; Save keeps it. When another scene was opened while the job ran, the files are written and
nothing is set (`handOver` says so).

**Cost.** The work is `texels x samples` gather rays plus `texels x lights x shadowSamples` shadow rays, times the bounces. `maxRays` (default
5e10) refuses a bake over that many before it traces one; as a guide one core traces 2 to 10 million rays per second, so 1e9 rays is minutes
on a laptop. Start with `texelsPerMeter` 8 and `samples` 16 for a draft, then raise them. The result is the same bits with any number of
threads and on every run (a seed: `seed`). Cancel is looked at in every phase (the BVH, the layout, the rays, the denoiser, the gutter); a
cancelled bake changes no file. The rest of the arguments (`bounces`, `denoiseRadius`, `rayEpsilon`, ...) are in the command's schema (`api.commands`).

**A fast preview on the GPU.** `"device":"gpu"` traces the texels on the graphics card with ray queries instead of the CPU: a scene that takes minutes on the
CPU takes seconds (on an Apple M5 a Cornell room of 98,000 texels and 64 samples took 5.2 s on the CPU and 45 ms on the GPU). The light is the CPU's up to the
GPU's own rounding (a tiny difference, never a different look) and the same on every run of one GPU and driver, but it is **not** byte for byte the CPU's, so
the default stays `"cpu"`: use the GPU while you place lights and walls, and bake the final one on the CPU. `"auto"` uses the GPU when this machine has one that
traces rays (not a software one such as WARP or lavapipe, which `"gpu"` still accepts) and the CPU otherwise. The result's `device` says which one baked (`{requested, used, name, note, process}`; `note` is why it was the CPU, `process` is `"here"` or `"helper"`). The GPU needs
ray tracing (Metal on Apple silicon, D3D12 or Vulkan with ray queries elsewhere, [Ray tracing](../RAY_TRACING.md)). It works from the editor (Lightmap panel, Device), MCP and a
`factoria call` with graphics too: a Mac process that already holds the only Metal context of the process (the editor, a window) runs the bake in a child
`factoria session --no-graphics --no-scene` (`process` is `"helper"`; the progress and Cancel work the same). It needs the `factoria` program next to the editor (or `FA_FACTORIA_EXE`);
if it is missing, or the child crashes or the GPU resets, the editor is not affected: `"gpu"` fails with the reason, `"auto"` bakes on the CPU and says why in `device.note`.
`FA_LIGHTMAP_HELPER=always|never` forces the choice. `samples`, `bounces` and `shadowSamples` have the CPU's ranges on the GPU too: outside them the bake is refused, never clamped.
Light probes are always baked on the CPU (a scene with no lightmap texels and only probes says so in `device.note`).

## Light probes and mixed lights (M73.4d)

A `LightProbeGroup` is baked by the same job (phase `probes`); a mesh with no lightmap gets the probes' light, and a `baked` light no longer lights it twice. See [Light probes and mixed lights](RENDERING_LIGHT_PROBES.md) (`docs.read rendering-light-probes`).

