Part of [RENDERING.md](../RENDERING.md): the lighting of 3D scenes, what a Light, the scene settings and a MeshRenderer say about it, and
what the renderer draws of it today.

# Rendering: lighting (M73)

M73 brings the lighting of a leading engine to FactorIA in six steps: many lights at once with area lights, cookies and IES profiles
(M73.1); shadows for every kind of light, in cascades for the sun (M73.2); an HDR environment, reflection probes and a physical sky
(M73.3); baked lightmaps and light probes (M73.4); volumetric fog, decals, subsurface scattering and realtime global illumination
(M73.5); and the material layers clear coat, sheen, anisotropy, specular / IOR and transmission (M73.6; the first four are drawn).

**What is there today (M73.1, M73.2, M73.5b): the fields, many lights, area lights, cookies, IES profiles, the shadows of the sun, of point lights and of spot lights, and projected decals.** Every field below is reflected,
validated, saved in the scene and read back, and shows up in `docs.components` and in the typings, so a scene, a prefab or a tool can
set it. The renderer reads `innerAngle`, `shape`, `size`, `cookie` and `ies`, the shadow fields of the lights and of the scene (the "Brought by" column says
`drawn` for them), and lights a view with up to 1024 lights at once (see "Many lights" and "Area lights, cookies and IES profiles"), and draws `Decal` components (see "Decals"); it does not read the other fields yet (except the sky fields, `skyModel` and the rows after it, which M73-P3d draws: see "The physical sky"): a
scene with only those set looks exactly as it does without them. The doc string of each field says which step brings it.
The defaults are what the engine did before, so a scene made before M73 loads, looks and saves as it did (a default is never written
to the file).

## Many lights (M73.1a)

A view is lit by up to **1024 lights at once**, 32 of them directional. The renderer does not loop over all of them for each pixel: it
cuts the view into a grid of tiles and depth slices (clusters, about 64 pixels square), finds the lights whose `range` reaches each
cluster, and every pixel reads only the lights of its own cluster. A scene with hundreds of small lights costs about what the lights
that overlap each pixel cost, so give every light the smallest `range` that looks right (the light fades to zero at `range`): a large
range makes the lists long.

- **Which lights.** Point, spot and area lights whose `range` sphere (for an area light, plus the radius of its emitter) is outside the camera's view are left out
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

## Area lights, cookies and IES profiles (M73.1b)

**Area lights.** `type: "area"` is a rectangle, a disc or a tube (`shape`, `size`) centred on the entity. A rectangle and a disc lie in the
entity's X and Y axes and emit from their front, the side its forward direction (-Z) points to: the back lights nothing. A tube is a line
of light along the entity's X axis (`size.x` long, `size.y` thick) and emits all around. The shading is one integral over the whole
emitter (linearly transformed cosines, with tables fitted for the engine's own specular term), so the highlight is the shape of the
light, long for a strip and round for a disc, and the diffuse term follows its extent: a panel above a wall lights it softly with no
hard centre. `intensity` and `color` mean what they do for a point light: far from a surface an area light lights it like a point
light of the same intensity at its centre (a test compares both to 5 %); near the surface the light is bounded, never infinitely
bright. `range` is measured from the surface of the emitter, not from its centre. With `castShadows` an area light casts shadows like a
point light (six faces from its centre, "Shadows of point and spot lights"), and with `shadowFilter: "pcss"` the penumbra is as wide as
the emitter: a larger `size` gives a softer shadow, `shadowSoftness` scales it. This is an approximation: the shadow is cast from the
centre of the emitter, so a very large panel close to a wall shows a sharper edge than a true area light would, and the penumbra of a
tube is as wide along its length as across it. The six faces are cheap, but an area light with `pcss` and no `shadowResolution` gets a
smaller shadow map the larger it is (down to 64 texels a face), so set `shadowResolution` for a big emitter whose shadow you look at closely.
A material with a clear coat, sheen or anisotropy layer gets the area light for its base layer and the light of a point at the nearest
spot of the emitter for the other layers. A material with its own `lighting()` or `light()` hook and a full shader get the light of
ONE point of the emitter, the one nearest to where the reflection of the view hits it (nearest to the surface when it misses), so the
highlight follows the shape of the light; they do not integrate the whole emitter. A GPU that cannot filter RGBA16F images
draws every area light as a point light at its centre (`render.supports areaLights` says which). The 2D lighting treats an area light as a point light.

**Cookies.** `cookie` is a texture (PNG, JPG, TGA, BMP; at most 4096 pixels a side) the light projects, and the picture's colour times
its alpha multiplies the light's colour: white lets it through, black stops it, a transparent pixel stops it too. A spot light
projects it through its cone, perspective, the edge of the cone (`spotAngle`) on the edge of the picture. A directional light
projects it straight along its forward direction and repeats it over the world, one copy every `size` metres along the light's X and
Y axes, starting at the world origin. A point light projects it all around: the picture is read as an equirectangular panorama
(longitude across, latitude down, the centre of the picture in the light's forward direction, -Z) and turns with the entity. It is
stored as a cube of six faces of 254 x 254 texels, so a 1024 x 512 or 2048 x 1024 picture is the size that is useful. An area light
ignores `cookie` and `ies` (a warning says so once). A cookie that cannot be read is reported once and the light is drawn without it.

**IES profiles.** `ies` is an `.ies` file (the LM-63 photometric format of lamp makers, type C) on a point or a spot light: the light
then shines with the measured distribution of that lamp instead of the same amount in every direction. Import one with `assets.import`
(it lands in `assets/lights/`; a file that is not photometric data, is type A or B, has an unordered or out-of-range angle table, or
no light in it is refused with the line that is wrong). The nadir of the profile (vertical angle 0) points along the entity's forward
direction (-Z), so a downlight is a light turned to look down. The table is divided by its largest value, so the file only SHAPES
the light: `intensity` stays the brightness in the brightest direction, whatever the candela of the lamp. Horizontal symmetry is
folded as the file says it (one plane, a quarter, a half, the whole circle). The profile is baked to 64 x 32 values and read with
bilinear filtering, so a sharp edge is a few degrees wide; a file with more than 1024 angles on an axis is refused.
`assets.import` reports the name, the angle counts and the peak candela; a directional light ignores `ies` (a warning says so once).

**The light atlas.** The tables of the area lights, every cookie (resampled to 254 x 254 texels, tiled with a border) and every profile
live in ONE RGBA16F image of 1024 texels per row and at most 4096 rows (32 MB), made when a light first asks for it and again when the set
changes or a file is hot-reloaded. A scene without area lights, cookies or profiles makes no atlas and draws and costs exactly what it did.
About 60 cookies fit (a point light's cube takes the room of six); the ones over that are dropped (the lights are drawn without, and a warning says how many). The same
packing is used on every backend, in the order of the sorted paths, so the image is the same bytes every time.

**Precision.** The area-light shading runs in full float (`highp`) on every GLES3 and WebGL2 GPU, whatever the default of the fragment stage
(a test reads the generated shader to check it). The LTC tables are stored in half floats, which is a relative error of about 0.1 %:
invisible next to the 2 % the fit itself has.

## Light

| Field | Values | Default | Brought by |
|---|---|---|---|
| `type` | `directional`, `point`, `spot`, `area` | `directional` | `area`: drawn (M73.1b) |
| `innerAngle` | 0..89 degrees | 0 | M73.1a (drawn): a spot's full-strength cone; 0 = the cone fades as it does today |
| `shape`, `size` | `rectangle`, `disc`, `tube`; metres | `rectangle`, [1, 1] | drawn (M73.1b): the area light's emitter; a directional cookie's tile |
| `cookie` | a texture | none | drawn (M73.1b): spot, directional and point lights (a point light's is an equirectangular picture) |
| `ies` | an `.ies` file | none | drawn (M73.1b): point and spot lights |
| `castShadows` | bool | false | drawn: the first directional light that casts is the sun (M73.2a); point and spot lights share a budget (M73.2b) |
| `shadowResolution` | 0..4096 texels per cascade (sun) or per tile (point, spot) | 0 (the engine picks: sun 2048 for one cascade, 1024 for several; point and spot from the distance) | drawn (M73.2a, M73.2b) |
| `shadowBias`, `shadowNormalBias` | metres, 0..1 | 0 (the engine's own: 1.5 texels of the map) | drawn (M73.2a, M73.2b) |
| `shadowFilter`, `shadowSoftness` | `pcf`, `hard`, `pcss`; 0..10 | `pcf`, 1 | drawn (M73.2a, M73.2b) |
| `shadowDistance` | metres, 0..100000 | 0 (the scene's) | drawn (M73.2a, M73.2b: fades out and limits point and spot lights) |
| `mode` | `realtime`, `baked`, `mixed` | `realtime` | M73.4a: `baked` lights stop lighting lightmapped entities (see "Lightmaps"); `mixed`: M73.4d |
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
| `lightmaps` | a `.lightmap.json` file | none | M73.4a |
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
  light is limited to 64 (its brightest channel, colour kept). The mirror level and the background show the picture as it is, except that `environmentIntensity` can push a sun past what the half float holds: after the gain the brightest channel is limited to 65000, colour kept, so a sun never becomes infinity (and a black spot after the tone mapping). The cost: a sun is
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
| `lightmapScale` | 0..100 | 1 | M73.4a (0 = never lightmapped); the bake's texel density: M73.4c |
| `contributeGI`, `receiveGI` | bool | true, true | `receiveGI`: M73.4a (false = ignores its lightmap entry); `contributeGI`: M73.4c (bake), M73.5 (realtime GI) |
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

## Shadows of point and spot lights (M73.2b)

A `Light` of type `spot` with `castShadows` has one shadow map, a perspective view along its axis; a `point` light (and an `area` light, from its centre) has six, one per face of a cube. A spot whose `spotAngle` is over 70 degrees takes the six faces too, because one
view cannot hold it. They live in the same shadow atlas as the cascades of the sun (`SceneSettings.shadowAtlasSize`), so a scene that
casts from many lights shares one image and one pass.

- **The budget.** The lights that cast are ranked every frame by how much they matter to the camera: their brightness (the largest colour
  channel times `intensity`) scaled by `range^2 / (range^2 + distance^2)` with the distance from the light to the camera; equal scores keep the
  order of the scene, so the result depends on the scene only and never on time. A map is `shadowResolution` texels per side (64..2048,
  rounded down to a power of two); with 0 it is 1024 (512 per face of a cube) while the camera is within the light's `range` and halves each
  time the camera is twice as far, never under 64. When the atlas is full the largest maps of the point and spot lights are halved, the least
  important light's first, and when even that is not enough the least important light loses its shadow whole (a point light never has
  some of its faces only). The sun's cascades keep the size they asked for until every local map is at its minimum (64) and no local
  light is left to drop: they are shrunk and dropped last. A frame also holds at most 64 maps in all, the sun's cascades included. A baked
  light (`mode` baked) with `castShadows` gets a map only while a mesh that is not lit by a lightmap (and receives shadows) is within its
  `range`: its shadows are in the lightmaps, a lightmapped surface skips the light, so the map would only serve the moving objects. A light that loses
  its shadow is lit as if `castShadows` were off, and the engine warns once, naming the fixes: raise `shadowAtlasSize`, lower
  `shadowResolution`, set `shadowDistance` or turn `castShadows` off on the lights that matter less.
- **Distance.** `Light.shadowDistance` (else `SceneSettings.shadowDistance`; 0 in both = no limit) fades the shadow out between 75% and 100%
  of that distance from the camera, and a light farther than that plus its `range` is not given a map at all: it costs nothing. A light whose
  range reaches no shadow caster costs nothing either, and a scene without local casters is drawn exactly as before.
- **Filters and bias.** `pcf`, `hard` and `pcss` work as for the sun, with the same code. `shadowBias` and `shadowNormalBias` are metres;
  0 picks 1.5 texels of the map at the surface's distance from the light (a texel of a perspective map grows with the distance), which
  suits most scenes; the slope term of the bias follows how the surface leans against the map's axis, so a surface facing the light
  at the corner of a cube face does not shadow itself. `shadowSoftness` is the angular size of the light for `pcss` (the penumbra a larger light casts).
- **Cost.** Each tile is drawn with the casters whose box meets the light's range and the tile's view (a cube face only draws what is in
  its view), and every one of those draws counts in `stats.drawCalls`; `stats.shadowCasters` counts the meshes that
  cast into any map. The atlas has only the size the maps of the frame need (at most `shadowAtlasSize`; 4096 x 4096 is 64 MB of `R32F`, plus its depth
  buffer), and is grown but never shrunk during a run.
- **GPUs.** `render.supports` with `{"feature": "pointShadows"}` or `{"feature": "spotShadows"}` follows `float32Targets` like the sun's.

Contact shadows (M73.2c, `contactShadows` still has no effect) come next.

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
| `angleFade` | 0..90 degrees | 60 | The angle, between the surface's normal and the projector's axis, up to which the decal has full strength. Beyond it the strength falls as `cos(angle) / cos(angleFade)` and reaches 0 only when the surface is edge-on (90 degrees): at the default 60 it is full up to 60 degrees off, half at 75 and 0 at 90. A smaller `angleFade` starts fading sooner and keeps the decal from smearing over walls seen at a slant; 90 keeps full strength until the surface is edge-on. |
| `sortOrder` | integer | 0 | Decals are painted in ascending `sortOrder`, so a later one paints over an earlier one; equal values keep the order in which the world visits its `Decal` components (a stable sort). The same order decides which decals stay when a cluster is over its 32 (see the limits): the lowest `sortOrder` are kept. |
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
once; `stats.decalsDropped` counts the rest), **32 decals per cluster of the view** (the first 32 in painting order stay: the lowest `sortOrder`) and **131072** list entries per view
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
until its step lands; then it follows the GPU (`cascadedShadows` does, `environmentMap` and `physicalSky` are true wherever the GPU renders to RGBA16F and filters it, `areaLights`, `lightCookies` and `iesProfiles` need RGBA16F images that filter, and `clusteredLights` and `decals` are `true` on every backend that draws). A game that wants a feature checks it first and falls back, so it never relies on
what is not drawn.

`clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles` (M73.1); `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows` (M73.2); `environmentMap`, `reflectionProbes`, `physicalSky` (M73.3; `environmentMap` and `physicalSky` are drawn); `lightmaps` (M73.4a), `lightProbes` (M73.4d);
`volumetricFog`, `decals` (M73.5b, drawn), `subsurface`, `realtimeGI` (M73.5); `clearCoat`, `sheen`, `anisotropy` (M73.6a, drawn: they follow the
backend, which every one supports) and `transmission` (M73.6b).

A new capability row, `float32Targets`, says whether the GPU can render to and sample R32F and RGBA32F images: the shadow atlas of
M73.2 is one (the cascaded shadows need it). It is `true` where the GPU reports both formats as renderable and sampleable.
