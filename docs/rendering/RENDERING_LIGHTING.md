Part of [RENDERING.md](../RENDERING.md): the lighting of 3D scenes, what a Light, the scene settings and a MeshRenderer say about it, and
what the renderer draws of it today.

# Rendering: lighting (M73)

M73 brings the lighting of a leading engine to FactorIA in six steps: many lights at once with area lights, cookies and IES profiles
(M73.1); shadows for every kind of light, in cascades for the sun (M73.2); an HDR environment, reflection probes and a physical sky
(M73.3); baked lightmaps and light probes (M73.4); volumetric fog, decals, subsurface scattering and realtime global illumination
(M73.5); and the material layers clear coat, sheen, anisotropy and transmission (M73.6).

**What is there today (M73-P0): the fields, and nothing that draws them.** Every field below is reflected, validated, saved in the scene
and read back, and shows up in `docs.components` and in the typings, so a scene, a prefab or a tool can already set it. The renderer
does not read any of them yet: a scene with every field set looks exactly as it does without them, except that a Light of
`type: "area"` shines like a point light of the same `range` until M73.1. The doc string of each field says which step brings it.
The defaults are what the engine did before, so a scene made before M73 loads, looks and saves as it did (a default is never written
to the file).

## Light

| Field | Values | Default | Brought by |
|---|---|---|---|
| `type` | `directional`, `point`, `spot`, `area` | `directional` | `area`: M73.1 (a point light until then) |
| `innerAngle` | 0..89 degrees | 0 | M73.1: a spot's full-strength cone; 0 = the cone fades as it does today |
| `shape`, `size` | `rectangle`, `disc`, `tube`; metres | `rectangle`, [1, 1] | M73.1, area lights only |
| `cookie` | a texture | none | M73.1 |
| `ies` | an `.ies` file | none | M73.1 |
| `castShadows` | bool | false | directional lights only today; point and spot lights: M73.2 |
| `shadowResolution` | 0..4096 | 0 (the engine picks) | M73.2 |
| `shadowBias`, `shadowNormalBias` | 0..1 | 0 (the engine's own) | M73.2 |
| `shadowFilter`, `shadowSoftness` | `pcf`, `hard`, `pcss`; 0..10 | `pcf`, 1 | M73.2 |
| `shadowDistance` | metres, 0..100000 | 0 (the scene's) | M73.2 |
| `mode` | `realtime`, `baked`, `mixed` | `realtime` | M73.4a: `baked` lights stop lighting lightmapped entities (see "Lightmaps"); `mixed`: M73.4d |
| `volumetric` | 0..10 | 0 | M73.5 |

## Scene settings

| Field | Values | Default | Brought by |
|---|---|---|---|
| `shadowCascades` | 1..4 | 1 | M73.2 |
| `shadowCascadeSplit`, `shadowCascadeBlend` | 0..1; 0..0.5 | 0.5, 0.1 | M73.2 |
| `shadowDistance` | metres, 0..100000 | 0 (the engine's own fit) | M73.2 |
| `shadowAtlasSize` | 512..8192 texels per side | 4096 | M73.2 |
| `contactShadows` | bool | false | M73.2 (needs a GPU that can sample the depth) |
| `environmentMap`, `environmentIntensity`, `environmentRotation` | an HDR image; 0..100; degrees | none, 1, 0 | M73.3 |
| `skyModel` | `gradient`, `physical` | `gradient` | M73.3 |
| `lightmaps` | a `.lightmap.json` file | none | M73.4a |

## MeshRenderer

| Field | Values | Default | Brought by |
|---|---|---|---|
| `lightmapScale` | 0..100 | 1 | M73.4a (0 = never lightmapped); the bake's texel density: M73.4c |
| `contributeGI`, `receiveGI` | bool | true, true | `receiveGI`: M73.4a (false = ignores its lightmap entry); `contributeGI`: M73.4c (bake), M73.5 (realtime GI) |
| `clearcoat`, `clearcoatRoughness` | 0..1 | 0, 0.03 | M73.6 |
| `sheenColor`, `sheenRoughness` | colour; 0..1 | black, 0.5 | M73.6 |
| `anisotropy`, `anisotropyRotation` | -1..1; degrees | 0, 0 | M73.6 |
| `specular`, `ior` | 0..1; 1..3 | 1, 1.5 | M73.6 |
| `transmission`, `thickness` | 0..1; metres | 0, 0 | M73.6 |
| `attenuationColor`, `attenuationDistance` | colour; metres | white, 0 | M73.6 |
| `subsurface` | 0..1 | 0 | M73.5 |

A value outside its range, or a name that is not one of the listed words, is refused where it is written (the scene file on load, the commands that set a component field, a script property write) with the field, the allowed range or words and a "did you mean" for a misspelt word.

## Lightmaps

A lightmap is light computed once and stored in an image: the diffuse light of the sun, the lights of mode `baked` and the sky, with the
bounces between surfaces, so a static level looks lit by global illumination for the price of one texture read. M73.4a is the part that
draws it; the `lightmap.bake` command that writes the files comes with M73.4c, so until then the files are made by tools that use the
baker (docs/design/ARCHITECTURE_BAKING.md, repository only, not in the binary) or by hand.

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
primitives included, gets a generated unwrap (xatlas, with a gutter between the charts), the same on every platform and run and kept in
memory with the mesh (nothing is written next to the model). A mesh with more than 250,000 triangles and no `TEXCOORD_1` cannot be
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

**The texel density.** `lightmap_texels_per_meter` (C++, `fa/scene/lightmap_manifest.h`) gives the density the bake will use for an entity:
16 texels per metre times `MeshRenderer.lightmapScale`, 0 when the scale is 0.

## Asking what the renderer draws: render.supports

`render.supports` (C++ `Renderer::supports(name)`) answers for each lighting feature below with `false` and the status `planned (M73)`
until its step lands; then it follows the GPU. A game that wants a feature checks it first and falls back, so it never relies on
what is not drawn.

`clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles` (M73.1); `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows` (M73.2); `environmentMap`, `reflectionProbes`, `physicalSky` (M73.3); `lightmaps` (M73.4a), `lightProbes` (M73.4d);
`volumetricFog`, `decals`, `subsurface`, `realtimeGI` (M73.5); `clearCoat`, `sheen`, `anisotropy`, `transmission` (M73.6).

A new capability row, `float32Targets`, says whether the GPU can render to and sample R32F and RGBA32F images: the shadow atlas of
M73.2 is one. It is `true` where the GPU reports both formats as renderable and sampleable.
