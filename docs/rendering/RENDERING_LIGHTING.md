Part of [RENDERING.md](../RENDERING.md): the lighting of 3D scenes, what a Light, the scene settings and a MeshRenderer say about it, and
what the renderer draws of it today.

# Rendering: lighting (M73)

M73 brings the lighting of a leading engine to FactorIA in six steps: many lights at once with area lights, cookies and IES profiles
(M73.1); shadows for every kind of light, in cascades for the sun (M73.2); an HDR environment, reflection probes and a physical sky
(M73.3); baked lightmaps and light probes (M73.4); volumetric fog, decals, subsurface scattering and realtime global illumination
(M73.5); and the material layers clear coat, sheen, anisotropy, specular / IOR and transmission (M73.6; the first four are drawn).

**What is there today (M73.1a, M73.2a): the fields, many lights and the cascaded shadows of the sun.** Every field below is reflected,
validated, saved in the scene and read back, and shows up in `docs.components` and in the typings, so a scene, a prefab or a tool can
set it. The renderer reads `innerAngle`, the shadow fields of the directional light and of the scene (the "Brought by" column says
`drawn` for them), and lights a view with up to 1024 lights at once (see "Many lights"); it does not read the other fields yet (except the sky fields, `skyModel` and the rows after it, which M73-P3d draws: see "The physical sky"): a
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
| `environmentMap`, `environmentIntensity`, `environmentRotation` | an equirectangular `.hdr` file; 0..100; degrees | none, 1, 0 | drawn (M73-P3a-2, see "The environment map") |
| `environmentBackground` | bool: draw the map as the background too | true | M73-P3a-2 |
| `skyModel` | `gradient`, `physical` | `gradient` | M73-P3d (drawn, see "The physical sky") |
| `skySunSize`, `skyTurbidity`, `skyExposure` | degrees 0.1..10; 1..10; 0..16 | 0.53, 2, 1 | M73-P3d |
| `skyGroundAlbedo`, `skyTintsSun` | colour; bool | grey 0.3, true | M73-P3d |
| `cloudCoverage`, `cloudDensity`, `cloudAltitude`, `cloudWind` | 0..1; 0..1; metres 300..12000; metres per second [x, z] | 0.25, 0.6, 2500, [8, 3] | M73-P3d |

## The physical sky

`SceneSettings.skyModel = "physical"` replaces the colour gradient with a sky computed from physics: a sun with a disc, an atmosphere
(Rayleigh scattering of the air, Mie scattering of dust and haze, absorption of ozone, plus an approximation of the light that
scatters more than once) and a layer of clouds. It is drawn as the background of every perspective camera that clears, and the same
sky is baked into the image-based lighting (unless an `environmentMap` is set: that lights instead, see "The environment map"), so the reflections of a metal ball and the ambient light of every mesh follow it: a
mirror under a blue sky with a few clouds shows both, and a sun that sets turns the whole scene orange and then dark blue.

- **The sun** is the directional light the renderer puts first (its slot 0): the one with `castShadows`, else the brightest directional
  light (a point or spot light never is the sun). Its direction, colour and intensity drive the sky, so turning the light (a day cycle) moves the sun across the sky.
  Without a directional light the sun stands overhead. The sky is scaled by the colour times the intensity of that light.
- **The light tints with the sky** (`skyTintsSun`, on by default): the colour of the light is multiplied by what the air lets through of
  a sun at that height, relative to a sun overhead, so a sun on the horizon is orange and weak and a sun below it gives no light, and
  by what the clouds let through on average (`cloudCoverage`, `cloudDensity`: up to 92 % less under a full heavy overcast). The colour
  you chose for the light is the colour at noon. Switch it off to keep the light exactly as authored. Limits: the clouds shade the sun
  light as one number for the whole scene (a cloud over the camera does not cast a moving shadow on the ground), the sun's shadow map
  is not changed, and the ambient light of the clouds' shade is the baked sky, not a per-pixel term.
- **Where it sits.** Where a sky material draws the sky (`skyMaterial`), the material wins and the physical sky is not drawn. A camera
  with `lighting: "studio"` or an orthographic camera shows no sky, as before. The sky is a function of the viewing direction only, like
  a skybox: the observer is 10 m above a flat ground, wherever the camera stands, and the clouds are a layer at `cloudAltitude` above that.
- **Clouds** are a procedural layer (a noise of five octaves), covering the sky by `cloudCoverage`, thick by `cloudDensity`, drifting
  along `cloudWind` with the **game clock** (`world.time()`, never the wall clock: a replay or a fixed step shows the same sky, and a
  paused game freezes the clouds).
- **When the lighting is rebuilt.** The picture itself follows the sun and the clock every frame. The baked environment is rebuilt in one
  frame the first time, when the air, the sun's colour, the exposure or the clouds' shape change, and when the sun moved more than a
  degree since the last bake; a sun that moves slowly (a day cycle) and drifting clouds rebuild it in three slices over three frames,
  a third of the work each, so no frame pays for all of it. The environment sees the sun rounded to a quarter of a degree and the
  clock to 2 s steps (only while the clouds drift), so it is the same at 30 and at 144 fps; the meshes follow the sun with that step.
- **What it costs.** On Metal (Apple M-series, 320 x 180, the test "what the tables and a bake cost" prints the numbers for your
  machine): a frame in which nothing changed only draws the sky as one full-screen triangle (0.4 ms for the whole frame here); the first frame and a change of `skyTurbidity` or
  `skyGroundAlbedo` draw two small tables of the air (about 5 ms for both on that GPU, and never again until one of those changes); a
  sun that moves a bit every frame adds about 1.6 ms (the sliced bake); a whole bake adds about 3.7 ms. The images take about 330 KB (half
  floats). The Direct3D 11 and OpenGL numbers were not measured on this host.
- **Where the GPU cannot.** The tables are RGBA16F render targets that filter. Without them `render.supports` answers false for
  `physicalSky` with that reason, and a scene that asks for the physical sky draws the gradient (an error is logged once).

## The environment map (M73-P3a-2)

`SceneSettings.environmentMap` is a Radiance `.hdr` panorama. It is the background of the scene and the image-based lighting of every
mesh: the ambient light, and what a metal or glossy surface reflects, come from the picture. Import one with
`assets.import {"source": "C:/art/sky.hdr"}` (it lands in `assets/hdri/`, kind `hdri` in `assets.list`) and set the field to its path.

- **What a file may be.** Equirectangular (latitude-longitude) only: twice as wide as it is tall (1 % off is accepted). A cube cross, a strip of six
  faces and a mirror-ball light probe are refused by `assets.import` and `project.validate` with the layout named ("square: a light probe")
  and how to convert it, and at run time the scene is drawn as if the field were empty, with one error in the log. At least 8 x 4.
  Picture width is capped at 4096 for the GPU: a wider file (up to 8192 x 4096 pixels on a 64-bit target, 4096 x 2048 on WebAssembly and
  32-bit ones; more is refused from its header before any memory is asked for) is shrunk to 4096 x 2048 when it is loaded, with a box
  filter. 2048 x 1024 is enough for lighting.
- **Orientation.** The middle of the picture is straight ahead along -Z, and +X is to its right (the picture is not mirrored). A positive
  `environmentRotation` turns the environment counter-clockwise seen from above: what was at +X is at -Z for 90. The picture, the
  reflections and the lighting turn together.
- **Brightness.** The file's values are linear light; `environmentIntensity` multiplies them (0 to 100). A gamma scene
  (`colorSpace: gamma`) shows the picture encoded to sRGB as every colour is, a linear scene as it is: the same picture either way.
- **Who draws what.**

  | | `skyMaterial` set | no `skyMaterial` |
  |---|---|---|
  | the background | the sky material (even a broken one: the gradient, never the picture) | the map, when `environmentBackground` is true; else the physical sky or the gradient |
  | the lighting and reflections | the map | the map |

  Without an `environmentMap` the lighting is baked from the sky that is drawn, the sky material, the physical sky or the gradient, as before.
  `environmentIntensity` multiplies the lighting of any of them, and the background of the map. The physical sky's `skyTintsSun` tint of the sun
  light does not change: it follows the sun and the air, not the map, so turn `skyTintsSun` off when the map has its own sun. A scene without
  `environmentMap` is drawn exactly as before.
- **Highlights.** A photograph of the sun holds values a million times the sky's. The file's NaN and negative values become 0; a texel above 60000
  (the half float holds 65504) is scaled down to it with its colour kept, after the shrinking. The bake takes the sky's own number of samples (32 to 128 a
  pixel, whatever the picture), so the cost does not depend on the file; and so a sun does not leave fireflies, one sample of the blurred levels and of the ambient
  light is limited to 64 (its brightest channel, colour kept). The mirror level and the background are not limited. The cost: a sun is
  a little dimmer in the ambient light and in rough reflections than its energy says, sharp in a smooth mirror. Never time- or CPU-dependent: the same file gives the same pixels.
- **When the lighting is baked.** In one frame, when the map, the rotation or the intensity change, when the file changes on disk (hot
  reload) and the first time; a frame in which none changed draws only the background. It is the bake of the sky (60 small passes), not a second one:
  the picture is drawn into the cube the sky is drawn into. Turning `environmentBackground` on and off does not bake.
- **Where the GPU cannot.** The picture is an RGBA16F texture with its mip chain (a 32-bit float texture does not filter on GLES 3 and WebGL 2 without an
  extension), and the cubes of the bake are RGBA16F too. Without half-float targets `render.supports` answers false for `environmentMap`, and a scene that sets it
  draws as without a map (one error in the log). The size is 85 MB for 4096 x 2048, 21 MB for 2048 x 1024.

## MeshRenderer

| Field | Values | Default | Brought by |
|---|---|---|---|
| `lightmapScale` | 0..100 | 1 | M73.4 |
| `contributeGI`, `receiveGI` | bool | true, true | M73.4 (bake), M73.5 (realtime GI) |
| `clearcoat`, `clearcoatRoughness` | 0..1 | 0, 0.03 | drawn (M73.6a), see "The material layers" |
| `sheenColor`, `sheenRoughness` | colour; 0..1 | black, 0.5 | drawn (M73.6a) |
| `anisotropy`, `anisotropyRotation` | -1..1; degrees | 0, 0 | drawn (M73.6a) |
| `specular`, `ior` | 0..1; 1..3 | 1, 1.5 | drawn (M73.6a) |
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

## The material layers (M73.6a)

The standard mesh shading (every MeshRenderer without a custom material, and a custom material's `Surface`) has four layers on top of
the base metal / roughness model. They are drawn on every backend (OpenGL, GLES3 and WebGL2, D3D11, Metal) with the same GGX model as the
base; a material that leaves them at their defaults draws exactly the picture it drew before (the golden images did not change), and
costs at most one uniform branch.

| Layer | Fields | What it does |
|---|---|---|
| Clear coat | `clearcoat`, `clearcoatRoughness` | A second, glossy dielectric layer over the surface (car paint, lacquer, wet clay): its own GGX highlight on the geometric normal (a normal map does not bend it), and the base underneath is dimmed by what the coat reflects (Fresnel of F0 0.04), so the paint is a little darker where the coat shines. |
| Sheen | `sheenColor`, `sheenRoughness` | A soft glow at grazing angles (velvet, satin, cloth): a Charlie distribution lobe tinted by `sheenColor`; the base underneath is scaled by `1 - max(sheenColor) * E`, the energy the sheen takes, so the surface never gains light. Black (the default) is off. |
| Anisotropy | `anisotropy`, `anisotropyRotation` | The highlight stretches along the tangent (brushed metal, hair, vinyl records): a negative value stretches it across. `anisotropyRotation` turns the direction, in degrees, around the normal. Needs tangents (a model without a TANGENT attribute gets them generated from its UVs). |
| Specular | `specular`, `ior` | The reflectance at normal incidence of a non-metal, `F0 = ((ior - 1) / (ior + 1))^2 * specular`: the default ior 1.5 and specular 1 give 0.04 exactly, so nothing changes; water is 1.33 (0.02), diamond 2.4 (0.17), `specular` 0 switches the dielectric reflection off. A metal's reflectance is its colour; the specular does not change it. |

Image-based light (the sky or the `environmentMap`) gets the layers too, by approximation: the coat reflects the environment along the
geometric normal with F0 0.04 (the pre-filtered mip of `clearcoatRoughness`); the sheen adds the environment along the normal at
`sheenRoughness`, tinted by `sheenColor` and by a table of the sheen's directional albedo (a 7 x 9 table, worst error 0.06, mean 0.003;
`tools/shaders/sheen_albedo.py` makes it); the anisotropic reflection bends the reflected direction toward the stretch (the bent normal
of McAuley 2015). They are not the path-traced truth; they are right in the sense that matters, a layer reflects its sky and never adds energy.

### Layers from a glTF model

A model's `KHR_materials_clearcoat`, `KHR_materials_sheen`, `KHR_materials_anisotropy`, `KHR_materials_specular` and `KHR_materials_ior`
become the layers of its parts: the factors always (`clearcoatFactor`, `clearcoatRoughnessFactor`, `sheenColorFactor`,
`sheenRoughnessFactor`, `anisotropyStrength`, `anisotropyRotation`, `specularFactor`, `specularColorFactor`, `ior`), clamped to the ranges of
the table (a value outside is clamped and named). A `MeshRenderer` field that is not at its default replaces the model's value of
that layer for the whole renderer, field by field (`materialColors` and the rest work as before); the packed textures below still
modulate it.

The mesh shader has no texture unit free for more maps, so the textures of the extensions are packed at import into the free channels of
the maps the part already binds. The packing is deterministic (bilinear resampling in fixed point, to the largest size among the sources of a map, at most
4096 x 4096), and a channel with no texture is 255 so the factor alone decides:

| Map the part binds | R | G | B | A |
|---|---|---|---|---|
| occlusion | the occlusion (255 if none) | `clearcoatTexture` R | `clearcoatRoughnessTexture` G | `sheenRoughnessTexture` A |
| metallic-roughness | `anisotropyTexture` B (strength) | roughness (`metallicRoughnessTexture` G) | metallic (B) | `specularTexture` A |

What does not fit is never dropped silently: the import writes a warning with the file, the material name and what is used instead.
Not packed: `clearcoatNormalTexture` (the coat follows the geometric normal), `sheenColorTexture` (`sheenColorFactor` is used),
`specularColorTexture` (`specularColorFactor` is used) and the direction (red and green) of `anisotropyTexture` (the direction is the
tangent turned by `anisotropyRotation`); a texture file that cannot be read (`its factor alone is used`), and a set whose packed size would pass
4096 x 4096. An editable mesh (`mesh.*` commands, a model converted to a mesh) keeps only the factors: its textures are not carried.

## Asking what the renderer draws: render.supports

`render.supports` (C++ `Renderer::supports(name)`) answers for each lighting feature below with `false` and the status `planned (M73)`
until its step lands; then it follows the GPU (`cascadedShadows` does, `environmentMap` and `physicalSky` are true wherever the GPU renders to RGBA16F and filters it, and `clusteredLights` is `true` on every backend that draws). A game that wants a feature checks it first and falls back, so it never relies on
what is not drawn.

`clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles` (M73.1); `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows` (M73.2); `environmentMap`, `reflectionProbes`, `physicalSky` (M73.3; `environmentMap` and `physicalSky` are drawn); `lightmaps`, `lightProbes` (M73.4);
`volumetricFog`, `decals`, `subsurface`, `realtimeGI` (M73.5); `clearCoat`, `sheen`, `anisotropy` (M73.6a, drawn: they follow the
backend, which every one supports) and `transmission` (M73.6b).

A new capability row, `float32Targets`, says whether the GPU can render to and sample R32F and RGBA32F images: the shadow atlas of
M73.2 is one (the cascaded shadows need it). It is `true` where the GPU reports both formats as renderable and sampleable.
