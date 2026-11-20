Part of [RENDERING.md](../RENDERING.md): the lighting of 3D scenes, what a Light, the scene settings and a MeshRenderer say about it, and
what the renderer draws of it today.

# Rendering: lighting (M73)

M73 brings the lighting of a leading engine to FactorIA in six steps: many lights at once with area lights, cookies and IES profiles
(M73.1); shadows for every kind of light, in cascades for the sun (M73.2); an HDR environment, reflection probes and a physical sky
(M73.3); baked lightmaps and light probes (M73.4); volumetric fog, decals, subsurface scattering and realtime global illumination
(M73.5); and the material layers clear coat, sheen, anisotropy and transmission (M73.6).

**What is there today (M73.1a, M73.2a, M73.5b): the fields, many lights, the cascaded shadows of the sun and projected decals.** Every field below is reflected,
validated, saved in the scene and read back, and shows up in `docs.components` and in the typings, so a scene, a prefab or a tool can
set it. The renderer reads `innerAngle`, the shadow fields of the directional light and of the scene (the "Brought by" column says
`drawn` for them), and lights a view with up to 1024 lights at once (see "Many lights"), and draws `Decal` components (see "Decals"); it does not read the other fields yet: a
scene with only those set looks exactly as it does without them, except that a Light of `type: "area"` shines like a point light of
the same `range` until M73.1b. The doc string of each field says which step brings it.
The defaults are what the engine did before, so a scene made before M73 loads, looks and saves as it did (a default is never written
to the file).

## Many lights (M73.1a)

A view is lit by up to **1024 lights at once**, 32 of them directional. The renderer does not loop over all of them for each pixel: it
cuts the view into a grid of tiles and depth slices (clusters, about 64 pixels square), finds the lights whose `range` reaches each
cluster, and every pixel reads only the lights of its own cluster. A scene with hundreds of small lights costs about what the lights
that overlap each pixel cost, so give every light the smallest `range` that looks right (the light fades to zero at `range`): a large
range makes the lists long.

- **Which lights.** Point, spot and (until M73.1b) area lights whose `range` sphere is outside the camera's view are left out
  (`lightsCulled` in `game.render_stats`). When more than 1024 lights are in view (or more than 32 are directional) the most
  relevant ones are kept: the shadow-casting sun first, the other directional lights by brightness, then the local lights by brightness
  scaled with the distance to the camera; `lightsDropped` counts the rest.
- **The limits, as counts.** 128 lights per cluster (the first 128 in the scene's relevance order stay) and 524288 list entries per
  view. A scene that reaches them has `lightClusterClipped > 0` in the render stats: lower the ranges or the number of lights that
  overlap. `lightClusters`, `lightClusterEntries` and `lightMaxPerCluster` show how full the lists are. Nothing here depends on the
  speed of the machine.
- **Same picture.** A scene with up to 32 lights in view looks exactly as before.
- **innerAngle.** A spot is at full strength inside `innerAngle` and fades to nothing at `spotAngle` (a smoothstep of the cosine of the
  angle); 0 keeps the fade the engine always had (from the edge of the cone to a cosine a quarter of the way to its axis).
- **Shaders.** `fa_light_count()` and `fa_light(n, i)` of a material's `lighting()` hook give the lights of the pixel's cluster
  (docs/shaders/SHADERS_LIGHTING.md).

## Light

| Field | Values | Default | Brought by |
|---|---|---|---|
| `type` | `directional`, `point`, `spot`, `area` | `directional` | `area`: M73.1 (a point light until then) |
| `innerAngle` | 0..89 degrees | 0 | M73.1a (drawn): a spot's full-strength cone; 0 = the cone fades as it does today |
| `shape`, `size` | `rectangle`, `disc`, `tube`; metres | `rectangle`, [1, 1] | M73.1, area lights only |
| `cookie` | a texture | none | M73.1 |
| `ies` | an `.ies` file | none | M73.1 |
| `castShadows` | bool | false | directional lights: drawn (M73.2a; the first light that casts is the sun); point and spot lights: M73.2b |
| `shadowResolution` | 0..4096 texels per cascade | 0 (the engine picks: 2048 for one cascade, 1024 for several) | drawn (M73.2a) |
| `shadowBias`, `shadowNormalBias` | metres, 0..1 | 0 (the engine's own: 1.5 texels of the cascade) | drawn (M73.2a) |
| `shadowFilter`, `shadowSoftness` | `pcf`, `hard`, `pcss`; 0..10 | `pcf`, 1 | drawn (M73.2a) |
| `shadowDistance` | metres, 0..100000 | 0 (the scene's) | drawn (M73.2a) |
| `mode` | `realtime`, `baked`, `mixed` | `realtime` | M73.4 |
| `volumetric` | 0..10 | 0 | M73.5 |

## Scene settings

| Field | Values | Default | Brought by |
|---|---|---|---|
| `shadowCascades` | 1..4 | 1 | drawn (M73.2a) |
| `shadowCascadeSplit`, `shadowCascadeBlend` | 0..1; 0..0.5 | 0.5, 0.1 | drawn (M73.2a) |
| `shadowDistance` | metres, 0..100000 | 0 (the engine's own fit) | drawn (M73.2a) |
| `shadowAtlasSize` | 512..8192 texels per side, the most the atlas may have | 4096 | drawn (M73.2a) |
| `contactShadows` | bool | false | M73.2 (needs a GPU that can sample the depth) |
| `environmentMap`, `environmentIntensity`, `environmentRotation` | an HDR image; 0..100; degrees | none, 1, 0 | M73.3 |
| `skyModel` | `gradient`, `physical` | `gradient` | M73.3 |

## MeshRenderer

| Field | Values | Default | Brought by |
|---|---|---|---|
| `lightmapScale` | 0..100 | 1 | M73.4 |
| `contributeGI`, `receiveGI` | bool | true, true | M73.4 (bake), M73.5 (realtime GI) |
| `clearcoat`, `clearcoatRoughness` | 0..1 | 0, 0.03 | M73.6 |
| `sheenColor`, `sheenRoughness` | colour; 0..1 | black, 0.5 | M73.6 |
| `anisotropy`, `anisotropyRotation` | -1..1; degrees | 0, 0 | M73.6 |
| `specular`, `ior` | 0..1; 1..3 | 1, 1.5 | M73.6 |
| `transmission`, `thickness` | 0..1; metres | 0, 0 | M73.6 |
| `attenuationColor`, `attenuationDistance` | colour; metres | white, 0 | M73.6 |
| `subsurface` | 0..1 | 0 | M73.5 |

A value outside its range, or a name that is not one of the listed words, is refused where it is written (the scene file on load, the commands that set a component field, a script property write) with the field, the allowed range or words and a "did you mean" for a misspelt word.

## Cascaded shadows of the sun (M73.2a)

The first directional light with `castShadows` is the sun. Its shadow is cut into `SceneSettings.shadowCascades` (1..4) cascades along
the camera's view: the first one covers the stretch nearest the camera, with the finest texels, the last one reaches
`shadowDistance` (the light's, else the scene's, else what the shadow casters need). `shadowCascadeSplit` sets where the cuts fall
(0 evenly, 1 logarithmic: a lot of detail near the camera) and `shadowCascadeBlend` the part of a cascade over which it fades into the
next, so no seam shows. Each cascade is a square map of `shadowResolution` texels (0 = 2048 for one cascade, 1024 for several), all of
them in one shadow atlas that has the size they need, at most `shadowAtlasSize` and the GPU's own limit; when they do not fit, the
farthest cascade is shrunk first (down to 128) and then dropped, the same on every frame.

- **Stable.** A cascade is a sphere around its slice of the view, so it does not change size as the camera turns, and its centre moves
  in whole texels: a still shadow stays on the same texels while the camera moves (no shimmer, no crawling edges).
- **Filters.** `pcf` (default) averages 16 taps of a fixed small disc. `hard` is one tap: the sharpest and cheapest. `pcss` finds the
  casters in front of the receiver and widens the blur with the distance to them (a contact stays sharp, a far shadow gets a wide
  penumbra); `shadowSoftness` is the light's size (1 = a sun of about 6 degrees; 0 = the narrowest penumbra, a plain PCF of 1.5 texels: for a hard shadow use `hard`). The sampling pattern is turned per pixel by a
  fixed noise, so a still picture never changes between frames.
- **Bias.** `shadowBias` is metres along the light and `shadowNormalBias` metres along the surface normal; 0 picks 1.5 texels of the
  cascade, which suits most scenes. A larger value hides acne and peels the shadow off its caster.
- **Memory.** The atlas is R32F: 2048 x 2048 is 16 MB, four cascades of 1024 the same, and it is grown but never shrunk during a run.
- **GPUs.** It needs `float32Targets` (`render.supports` with `{"feature": "cascadedShadows"}` says so before a scene is run). Without
  them the engine warns once and draws no shadow: it never falls back silently to another look.
- **Looking at it.** `render.debug_view` with `"cascades"` tints every surface by its cascade (red, green, blue, yellow; grey past the
  last), and `FA_RENDER_DEBUG_VIEW=cascades` does the same for a whole run.

Only the sun casts shadows in this step; point and spot light shadows (M73.2b) and contact shadows (M73.2c, `contactShadows` still has
no effect) come next, in the same atlas.

## Decals (M73.5b)

A `Decal` component paints a texture on the meshes inside its box, the way a stencil or a sticker does: bullet holes, blood, dirt,
scorch marks, painted signs, a wet patch. It is a **projected** decal: the entity's box (the unit cube scaled and placed by the entity's
transform) is a projector that looks along its local **-Z** (the way a `Light` or a `Camera` looks) and paints every receiver surface
inside the box that faces it. Rotate the entity so -Z points at the wall, the floor or the roof.

| Field | Values | Default | Meaning |
|---|---|---|---|
| `albedo` | a texture path | none | The colour image. Its alpha says where it paints (a ring, a splat); without it the decal is a solid box of `color`. |
| `normal` | a texture path | none | A tangent-space normal map: relief that bends the lighting where the decal paints (bumps, scratches, bullet dents). |
| `color` | colour | white | Multiplies the albedo; its alpha scales the cover. |
| `opacity` | 0..1 | 1 | How much of the albedo (and of the relief) the decal paints. Fade a decal out by lowering it. |
| `normalStrength` | 0..4 | 1 | The strength of the relief. 0 is flat. |
| `angleFade` | 0..90 degrees | 60 | A surface turned further than this from facing the projector gets no decal, fading in between: it stops the decal from smearing over walls that are seen edge-on. 90 lets it reach every face. |
| `sortOrder` | integer | 0 | Decals are drawn in ascending `sortOrder` (ties in the order of the world); a later one paints over an earlier one. |
| `layers` | 0..65535 | 0 | A bit mask of the **decal layers** it paints: bit n is `MeshRenderer.decalLayer` n. 0 paints every layer. |

On the receiving side `MeshRenderer.receiveDecals` (default true) turns decals off for a mesh, and `MeshRenderer.decalLayer` (0..15,
default 0) says which layer it belongs to: a decal paints a mesh when the mesh receives decals and its layer is in the decal's `layers`.
A character that must stay clean, or a floor that takes only the footprints, uses these.

How it looks:

- A decal changes the surface's **albedo** and **normal** before the lights run, so it is lit, shadowed and reflected like the surface
  under it (a decal on a shiny floor stays shiny; `metallic` and `roughness` are the mesh's). It does not add light by itself.
- The box ends sharply at its sides (the decal ends at the edge of its picture) and fades over the last tenth of its depth, so a
  decal does not show a flat cut where the projection ends.
- Albedo and normal are read with mip levels chosen from how large the decal is on the screen, so a far decal does not sparkle.
- Decals draw on the opaque and the transparent meshes alike. The depth prepass and the shadow maps do not see them: a decal never
  casts a shadow and never changes the silhouette.
- A scene without decals draws the same picture as before (every golden of the engine stayed the same), and costs nothing more.

Limits, all counts (never time): **256 decals** per view (a view with more draws the first 256 in the order of the world and warns
once; `stats.decalsDropped` counts the rest), **32 decals per cluster of the view** and **131072** list entries per view
(`stats.decalClusterClipped` counts what is lost; 0 is normal), and the textures of all decals share **one atlas** of at most 4096 x
4096 pixels (or the GPU's own limit) and 96 MB: each texture is scaled to at most 1024 pixels on its longer side, and when they do not
all fit the biggest are halved (down to 16 pixels) and then the last are left out, the same on every run. A decal whose `albedo` cannot be
read or does not fit is **not drawn** and the engine says which texture once (`stats.decalsDropped` counts it); a `normal` that
cannot be read just adds no relief. The atlas is rebuilt when a decal names a texture it does not hold, when a texture file is reloaded
or when the scene's colour space changes (a hitch of a frame; give the decals of a level in the first frame, or keep the set stable).

`stats.decals` is how many decals were drawn. `render.supports` with `{"feature": "decals"}` is true on every GPU.

**Not the same as `texturing`.** A model's `texturing` section (a project's model file) also has "decals": those are baked into the model's
texture by the CPU when the model is made, one fixed picture. A `Decal` component is live: it moves, fades and is added or removed
while the game runs, and any mesh in its box receives it.

For a snippet material the engine applies decals itself (the `surface` hook's result is painted over). A **full shader** calls
`fa_apply_decals` itself, see [SHADERS_LIGHTING.md](../shaders/SHADERS_LIGHTING.md), "Decals".

## Asking what the renderer draws: render.supports

`render.supports` (C++ `Renderer::supports(name)`) answers for each lighting feature below with `false` and the status `planned (M73)`
until its step lands; then it follows the GPU (`cascadedShadows` does, and `clusteredLights` and `decals` are `true` on every backend that draws). A game that wants a feature checks it first and falls back, so it never relies on
what is not drawn.

`clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles` (M73.1); `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows` (M73.2); `environmentMap`, `reflectionProbes`, `physicalSky` (M73.3); `lightmaps`, `lightProbes` (M73.4);
`volumetricFog`, `decals` (drawn, M73.5b), `subsurface`, `realtimeGI` (M73.5); `clearCoat`, `sheen`, `anisotropy`, `transmission` (M73.6).

A new capability row, `float32Targets`, says whether the GPU can render to and sample R32F and RGBA32F images: the shadow atlas of
M73.2 is one (the cascaded shadows need it). It is `true` where the GPU reports both formats as renderable and sampleable.
