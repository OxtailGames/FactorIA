Part of [RENDERING_LIGHTING.md](RENDERING_LIGHTING.md): projected decals and the volumetric fog with light shafts. The Light, the scene settings and the rest of the M73 lighting are on that page.

# Rendering: decals and volumetric fog (M73.5)

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
- Albedo and normal are read with mip levels chosen from how large the decal is on the screen, so a far decal does not sparkle (up to mip level 3: the atlas gutter around each tile holds a bilinear tap of that level, so a read never reaches a neighbouring tile).
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

## Volumetric fog and light shafts (M73.5)

`SceneSettings.volumetricFog = true` fills the space between the camera and what it sees with a medium that the lights shine through:
the ambient light makes it glow, the sun and the point and spot lights that ask for it draw **shafts** in it, and the shadows of the
shadow atlas cut those shafts (a sun through a gap in a roof, a spot behind a pillar). The medium's colour is `fogColor`.

- **A light asks for its shafts** with `Light.volumetric` above 0 (0..10, the strength: 1 scatters as much light as a white surface
  would reflect). A light with 0 never shines in the fog, a directional light included. A light's shadows cut its shafts when it
  casts them (`castShadows`); a light that casts none still scatters, with no shadows. Which lights are drawn is the camera's own
  choice: up to 4 directional lights in table order, and of the point and spot lights the 4, 8 or 16 (by `volumetricQuality`) with
  the highest score times `volumetric` (the score of the clustered lights: brightness over distance to the camera; ties go to the
  lower table index). `stats.volumetricLightsDropped` counts those left out.
- **The medium.** Extinction `volumetricDensity` per metre at `volumetricHeightBase` and below it, falling by `exp(-volumetricHeightFalloff * h)` above
  it (0 = the same density at every height, a flat fog). The light that reaches the camera is scattered with the Henyey-Greenstein
  phase function of `volumetricAnisotropy` (0 = evenly, towards 1 = forward, a sun in your face; negative = back). The fog scatters
  `volumetricAmbient` times `ambientLight` everywhere, so it glows even where no light reaches. The medium ends at the surface behind the pixel or at `volumetricDistance`
  metres, in the sky. How much of the picture shows through is `exp(-optical depth)`, computed in closed form from the density
  along the ray, so the quality changes the noise of the shafts and never the amount of fog.
- **One fog, never two.** While a camera draws the volumetric fog, its **analytic fog is off**: `SceneSettings.fogDensity` and the
  `PostProcess` fog (`fogEnabled`) of that camera do nothing, since they would fog the same distance twice. The sun shafts of the
  `PostProcess` stack (`sunShaftsEnabled`, a screen-space glow around the sun) are a different effect and still draw; they are
  not needed once the sun's `volumetric` is on. A camera that cannot draw the volumetric fog (an orthographic or studio camera, no
  depth prepass, a GPU without RGBA16F render targets, `volumetricDensity` 0) keeps its analytic fog as if the switch were off.
- **Transparent meshes.** The fog is blended over the finished picture, using the depth of the opaque surfaces, so a blended mesh
  (alpha below 1, a particle, a sprite, glass) is fogged like the opaque surface behind it, not by its own distance. A pane of glass in
  front of a wall shows the wall's fog, and a transparent mesh in the middle of the medium does not scatter. This is the price of
  adding no texture to the mesh shader; in the sky (no opaque surface) a transparent mesh is fogged as far as `volumetricDistance`.
- **It is not the analytic fog.** The light the medium scatters is `(ambient + sum of lights * phase * volumetric) * fogColor`, so at the same
  density it looks different from `fogDensity` (which is a flat colour that replaces the surface): with little light the volumetric fog is darker than `fogColor`.
  A camera that falls back to the analytic fog (an orthographic camera, a GPU without the render targets) therefore shows a visible jump in the look of the same scene.
- **Off costs nothing.** A scene without `volumetricFog` compiles no shader, adds no pass and no memory, and draws the very same picture as before
  (the test compares it to the last bit).

**How it is drawn** (every backend, with no compute shader). Two passes in the camera's own job: `vol-march` raymarches the
medium at half or a quarter of the camera's resolution into an RGBA16F image (the light that reaches the camera, and the
transmittance), reading the depth prepass, the shadow atlas and the light data texture; `vol-apply` blends that image over the
picture (`picture * transmittance + light`) after the post material slot and before the reflections, with a depth-aware upsample: each
pixel of the picture takes its four nearest pixels of the small image, weighted by how near their depth is to its own, so a fog edge never bleeds
over a silhouette. The picture is not copied and no mesh shader changes. Shadows are read with one tap (the jitter and the upsample soften them): the sun's from the cascaded atlas, a local
light's from its tile or cube face.

**Quality, by platform.**

| `volumetricQuality` | Fog image | Steps (ambient, sun) | Lights (point, spot) | Samples per light | Meant for |
|---|---|---|---|---|---|
| `low` | 1/4 x 1/4 | 16 | 4 | 6 | phones and the web (GLES3, WebGL2) |
| `medium` (default) | 1/2 x 1/2 | 32 | 8 | 10 | integrated GPUs |
| `high` | 1/2 x 1/2 | 48 | 16 | 16 | desktop GPUs |

The mapping is a suggestion: the engine never changes the quality by itself, and the same scene draws the same on every
backend. **The cost** is bounded by the table and never by the scene: a march pixel takes at most `steps` samples for the ambient light and
the sun plus `lights x samples` for the local lights, and the loops have a fixed top (64 steps, 24 samples, 4 + 16 lights); the number of lights in the scene never
raises it. At 1920 x 1080 `medium` marches 960 x 540 pixels (a quarter of the picture), `low` 480 x 270 (a sixteenth). The image is RGBA16F
(8 bytes a pixel: 4 MB for `medium` at 1080p, 1 MB for `low`) and is a transient of the frame graph, shared with other passes of the frame when their sizes match. The profiler shows
the two passes as `<camera job>/vol-march` and `<camera job>/vol-apply`.

**Determinism.** There is no random number, no clock and no history of earlier frames: the jitter of the samples is interleaved gradient noise of the pixel of
the fog image, so a still scene is the same picture on every frame and every run (it shows as a fine fixed grain at `low`), and a fast camera has no ghosts. For
the same reason a replay or a fixed step reproduces the picture.

**Stats** (`game.render_stats`, `Renderer::stats()`, summed over the frame's cameras): `volumetricCameras` (cameras that drew it),
`volumetricLights` (the lights they scattered) and `volumetricLightsDropped`.

**Limits.** Area lights have no shafts (only directional, point and spot lights are listed). The sun's shadows come from the cascades the camera draws, so a shaft beyond the
last cascade (further than the shadow distance) is unshadowed. With few steps (`low`) and a long `volumetricDistance` each step is long, so thin shafts and
small gaps come out coarse and grainy: shorten the distance or raise the quality. Point and spot lights are read from the light data texture the mesh shaders use, so a light the renderer left out of it (more lights than the
per-camera limit, `stats.lightsDropped`) has no shafts either. The medium has no emission, no per-light color of its own and no local fog volumes. The shadow of the
sun is read from the cascades the camera draws that frame: a sun with `castShadows` off shines through everything. Light cookies (M73.1)
are not read yet: the march multiplies each local light by its attenuation and cone in `local_atten` (shaders/volumetric.glsl), which is
where a cookie lookup goes, with the light's table index at hand.

