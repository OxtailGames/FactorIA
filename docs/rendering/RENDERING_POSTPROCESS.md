# Rendering: the post-processing stack

Part of [Rendering](../RENDERING.md): the post-processing stack of a camera (bloom, exposure, tonemap, colour grading, lens effects, colour filter), its effects, the LUT and the commands. The render targets, the depth and normals prepass, capture and HDR output stay on that page.

## Post-processing: bloom, exposure, tonemap, colour grading, lens effects, colour filter

A `PostProcess` component (`docs.components`; docs/COMPONENTS.md is repository only, not in the binary) on the entity of a `Camera` is that camera's stack of screen effects; on an entity
without a camera it is a volume that blends into the stacks of the cameras inside it. Every effect is off by default, and **a frame
without any stack declares no pass and makes no render target**: the picture goes straight to the screen, as before. **Every camera
has its own stack**, also in a split screen or with a viewport smaller than the screen: its `post` pass, its prepass, its coverage
image and its automatic exposure work over that camera's rectangle of the picture only, in the camera's own pixels (the pixelate
grid, the lens centre, the vignette, the grain and the dither start at the corner of the rectangle, so the two halves of a split
screen look alike). Two things stay one per frame, taken from the camera that draws first: the **bloom** (it runs over the whole
picture, before the final passes) and the **colour filter** (it is the last step over everything the screen shows).
A scene that still has the bloom or colour filter keys that `Camera` had until 0.32 fails to load with a message that says to use a `PostProcess`.
The passes of camera `n` are named `camera:<n>/post`, `camera:<n>/prepass` and so on. Where the cameras' rectangles do not cover the
picture, or overlap, a `post-base` pass first draws the picture the way a frame without effects would (the encode of a linear scene, a
copy of a gamma one), and a camera without a stack over one with a stack gets that plain pass over its own rectangle, so the stack
of one camera never reaches another's pixels.

The passes of a frame (bloom, exposure, prepass, ambient occlusion, shafts, depth of field, motion blur, `post`, the HUD and the colour
filter), each with when it runs and what it draws, are on the page [The passes of a frame](RENDERING_PASSES.md)
(`docs.read rendering-passes`); `render.frame_graph` lists them and `RenderStats::passes` times them.

A game in the default gamma colour space with only bloom or only a colour filter gets exactly the passes it had before the stack
existed (the old pictures are byte for byte the same). Exposure and tonemap decode the stored colours to light, work in linear
light and encode back, so `exposureEv` +1 doubles the light, not the stored number. A stack without the ten effects below runs the
same code as before: they are switched on by a bit mask, so an effect that is off costs no sample and no arithmetic.

### The effects of the final pass

Ten effects run in the `post` pass, in the order of this table (`render.supports {"feature": "<effect>"}` is true where this build
draws them). They work in display space (the encoded values the screen shows), the same on an SDR and on an HDR output, except the
two that bend the picture and the pixelation, which move the place it is read from.

| Effect | Fields (`PostProcess`) | What it does |
|---|---|---|
| `radialBlur` | `radialBlurIntensity`, `radialBlurCenter`, `radialBlurSamples` | The picture streaks away from the centre: `radialBlurSamples` taps along the line from the pixel toward `radialBlurCenter`, as far as `radialBlurIntensity` says, averaged. It reads the scene, so it acts before the grade and the other display effects. `camera.radialBlur` starts a pulse of the same blur (see "Transient screen effects"). |
| `lensDistortion` | `lensDistortionIntensity` (-1 pincushion .. 1 barrel), `lensDistortionScale` (zoom), `lensDistortionCenter` | Moves the point each pixel reads. It acts while the picture is sampled, so the bloom glow bends with it. Where the lens reads outside the picture the pixel is **black** (raise the scale to hide it). |
| `chromaticAberration` | `chromaticAberrationIntensity` | Red and blue are read at slightly different distances from the centre, growing toward the edge; green stays. Read at the same moment as the lens; the sample is clamped to the picture's edge. |
| `colorGrading` | `colorGradingTemperature`, `Tint`, `Lift`, `Gamma`, `Gain`, `Contrast`, `Saturation`, `HueShift`, `colorGradingLut`, `colorGradingLutContribution` | After the tonemap and the encode, in display space: white balance, gain, lift, gamma, contrast around mid grey, saturation, hue rotation, then the LUT. Nothing is clipped at white, so an HDR value above 1 stays above 1. |
| `vignette` | `vignetteIntensity`, `Smoothness`, `Roundness`, `Center`, `Color` | Mixes the display value toward `vignetteColor` toward the edge of the screen. The same on SDR and HDR (it works on the encoded value). |
| `sharpen` | `sharpenIntensity` | Contrast-adaptive: it reads the four neighbours (each shaded the same way as the pixel) and sharpens less where the local contrast is already high, so edges ring less. |
| `outline` | `outlineMode` (`depth`, `sprite`), `outlineColor` (alpha = opacity), `outlineWidth`, `outlineDepthThreshold`, `outlineNormalThreshold`, `outlineAlphaThreshold` | Lines at the edges of things, drawn over the sharpened picture (see [The outline](RENDERING_EFFECTS.md#the-outline)). |
| `pixelate` | `pixelateSize` | Every pixel of a block of `pixelateSize` design pixels shows the colour at the block's centre (the block grid starts at the top-left of the camera's rectangle of the picture, so a block cut by the right or bottom edge reads its centre clamped to the picture). It moves the place everything of the final pass reads (the lens, the grade, the vignette, the sharpen and the outline see the block centre, so the outline is blocky too); only the film grain and the dither stay per pixel. |
| `posterize` | `posterizeLevels` | Each colour channel of the display value is cut to `posterizeLevels` evenly spaced values (`round(c * (n - 1)) / (n - 1)`), after the grading, the vignette, the sharpen and the outline. An HDR excess above white is kept as it is. The 1/255 dither is switched off while it is on, since it would move a value off its level. |
| `filmGrain` | `filmGrainIntensity`, `Size`, `Animated`, `LuminanceResponse` | An integer hash noise added to the display value, weighted toward the mid tones by `LuminanceResponse` (1) or even (0). It is seeded by the engine's frame counter (`world.frame()`), so a recorded or replayed run gives the same grain; `filmGrainAnimated` false uses a fixed seed. It is added before the dither and the colour filter. |

### Ambient occlusion and the other screen-space effects

`ssaoEnabled` darkens creases and contact points of 3D meshes (passes `ssao-*`, drawn before the bloom). Its section, its costs, the
effects that follow it (reflections, fog) and the outline (`outlineEnabled`, depth and sprite mode) are on the page
[Screen-space effects](RENDERING_EFFECTS.md).

A gamma scene's stored colours are display values already: the effects use them as they are, and a scene with exposure or tonemap
decodes, tonemaps and encodes first. A linear scene always runs the conversion. On an HDR output the final pass goes above paper
white only when exposure or tonemap is on (see "HDR output"); a stack with only these effects is drawn in the standard range.

### Depth of field and motion blur

Two effects that read the depth prepass ("Depth and normals") and work on the **scene colour**, before the bloom and the final pass (so
they blur light, and the HUD, drawn over them, is never blurred). They need opaque 3D meshes in view: a camera without any (a 2D game)
draws a frame without them. Every camera has its own passes and its own focus (a split screen blurs each rectangle on its own). With
both off there is no pass and no prepass for them: the picture is the one without them, byte for byte.

- **`depthOfField`.** Each pixel gets a signed circle of confusion from its linear view depth: 0 inside the band of `depthOfFieldFocusRange`
  world units centred on the focus distance, growing smoothly to `depthOfFieldNearBlur` (in front) or `depthOfFieldFarBlur` (behind), in
  design pixels times the render scale. Where no mesh was drawn (the sky, sprites, shapes) the depth counts as infinite: the far blur
  applies. `dof-down` halves the picture and keeps the circle, `dof-gather` blurs it with a disc of taps (a fixed per-pixel rotation, so
  every run draws the same frame; about 4 taps per pixel of radius, at most 64), `dof-composite` mixes the sharp picture with the blur.
  A sharp object never takes colour from a blurred one behind it; a blurred near object spreads past its silhouette.
  `depthOfFieldBokeh` weights bright points so they show as discs. **Autofocus:** with `depthOfFieldTarget` the focus is that entity's
  view depth, moved toward it each frame by `1 - exp(-depthOfFieldFocusSpeed * dt)` of the way (engine clock: the same frames give the
  same focus on every machine). The focus is state of the renderer, one per camera; the first frame, a camera that did not draw the frame
  before, no target, a destroyed target or one behind the camera use `depthOfFieldFocusDistance` at once.
- **`motionBlur`, `motionBlurMode`.** A pixel's velocity is the screen distance between its point now and in the frame before; the
  picture is smeared along it over `motionBlurIntensity` of it (the shutter, 0 to 1). `motionBlurMode` chooses where the velocity comes from:
  - **`"object"` (the default).** The velocity image of the depth prepass (RG16F, `uvPrev - uvCurr`, unjittered; the pass that writes it is described in the repository's docs/design/ARCHITECTURE_RENDERING_TEMPORAL.md
    (repository only, not in the binary)), so **an object that moves on its own blurs along its own way** and a
    still one next to it stays sharp. The vector is cut to `motionBlurMaxRadius` design pixels (1 to 64, default 24, times the render
    scale; the longest streak is twice that, centred on the pixel). A pixel nobody wrote a velocity for (the sky, anything the prepass
    does not draw) uses the camera's own movement rebuilt from the depth, as the camera mode does. The filter is McGuire's
    (a fast, stable feature-aware motion blur): the longest vector of every block of pixels the size of the radius, the longest of the
    3 x 3 blocks around a pixel, and a depth-aware gather that adds a fast object over a slower pixel behind it, adds a pixel behind a fast
    object only as far as that pixel's own blur reaches, and never smears a sharp background into a moving object. The taps are
    `motionBlurSamples` at most (the preset's knob, 32 at the most; a short streak uses fewer), jittered by a fixed pattern.
    The picture of one run is the picture of every run. The edge of the moving object itself stays defined (the blur spreads
    mostly outside its silhouette): that is how this filter looks, not a lost blur.
  - **`"camera"`.** The depth and the previous view-projection only, so only the camera's movement blurs, the way every earlier version
    did, bit for bit. No velocity image is asked for.
  - **Why the default does not change existing games much.** No example of the engine turns `motionBlur` on and the effect is off by
    default, so a game that does not set it is untouched (no pass, no prepass, no velocity image: tested bit for bit). In a game that
    does, a static scene seen by a moving camera blurs about as before: the velocity image of a static mesh holds the camera's motion and
    the sky falls back to the same reconstruction, so the two modes differ by the weights of the taps only (tested within a bound). What
    changes is that the moving objects blur too. A game that wants the old look exactly sets `motionBlurMode` to `"camera"`.
  - **Where it runs.** After the temporal antialiasing and before the bloom, so it blurs the resolved picture; with the temporal upscaler it
    blurs the render-size picture before the resolve (the velocity image is unjittered, so the blur never follows the jitter). Where the
    velocity image cannot be made (a GPU with no RG16F target, a frame with global illumination replacing the prepass) or the shaders fail,
    the camera mode draws instead, with one log line.
  - No blur on the first frame or after the camera did not draw (a camera switch, a deactivated camera); the per-object mode still asks
    for the velocity image on those frames so the objects keep their models of the frame before. A camera moved to another place
    between two frames is **not** told from a very fast one: it blurs with the longest streak for that frame.
- **Both on.** `dof-down`, `dof-gather`, `dof-composite` (into a scratch image of the camera's size), then the motion blur, which reads the
  scratch and writes the picture: `motion-blur` in the camera mode, and in the object mode `motion-velocity` (the blur vector and the depth of
  every pixel), `motion-tile-x` and `motion-tile-y` (the longest vector of each block) and `motion-blur` (the gather). Each alone ends with
  a copy (`dof-copy`, `motion-copy`): a pass cannot read the image it writes.
- **Cost.** The prepass, a scratch image of the camera's size and, for the depth of field, two half-size `RGBA16F` images. If the GPU
  cannot make them the effects are skipped for that size, and the log says so once.

### Colour grading with a LUT

`colorGradingLut` is the project path of a `.cube` file (the 3D lookup table that DaVinci Resolve, Photoshop and most grading
tools export). `assets.import` takes a `.cube` into `assets/luts/`; the importer parses it, reports its size and title, and refuses
a file the renderer could not use, with the line number (a 1D table, a size outside 2 to 65, a domain other than 0 to 1, a wrong
row count). A table of any size from 2 to 65 is used as it is (16, 32 and 64 are the usual ones). It is stored as an 8-bit strip
texture (the slices of blue tiled side by side) and sampled with a manual trilinear blend, so the result does not depend on the
backend. The LUT adds `(lut(x) - x) * colorGradingLutContribution` to the graded colour, where `x` is the colour looked up
(clamped to 0..1), so a contribution of 0.5 is half of it and a value above 1 keeps its excess. A path that does not resolve is
skipped (the rest of the stack is drawn). The LUT is applied last, in display space: use one exported for sRGB.

Cost (a 1280x720 frame, counted by `render.frame_graph`; the extra render targets are RGBA16F where the GPU draws in float, 8 bytes a
pixel, else RGBA8):

| Setting | Extra full-screen passes | Extra memory |
|---|---|---|
| no `PostProcess` | 0 | 0 |
| `colorFilterEnabled` alone | 1 | one full-size target |
| manual `exposureEnabled` and/or `tonemapEnabled` | 1 (`post`; the HUD draws as before, into another target) | one full-size target, and with a HUD a second one with a depth buffer |
| `exposureMode` auto | 2 more (32x32 and 1x1) | a few KB |
| `bloomEnabled`, `bloomRadius` 20 | 4 (`bloom-bright`, two blurs, `bloom-composite`) | two 320x180 targets, 0.9 MB |
| `bloomEnabled`, `bloomRadius` 64 | 6 | four smaller targets, 0.6 MB |
| colour grading, vignette, chromatic aberration, lens distortion, sharpen, pixelate, posterize or film grain, alone or together | 1 (`post`; sharpen shades the pixel's four neighbours too, about five times that part's work; the LUT one table lookup) | one full-size target |
| `outlineEnabled`, depth mode | 1 (`post`, reads 4 texels of the prepass) + `prepass` | one full-size target and the prepass image (16 bytes a pixel) |
| `outlineEnabled`, sprite mode | 1 (`post`, up to 17 texels of the coverage) + `sprite-coverage` (the 2D batches again) | one full-size target and one RGBA8 image (4 bytes a pixel) |
| everything on except outline, with a HUD | 8: auto exposure 2 + bloom 4 + `post` 1 + `color-filter` 1 (its own pass because the HUD went between) | the sum of the above |

The time of each pass is in `render.frame_graph` with `profileFrames` (`passTimes[].gpuMs` on D3D11 and OpenGL, `cpuMs` of the
recording everywhere; Metal has no GPU timer in sokol_gfx, so `gpuMs` is -1 there). A full-screen pass reads one texture and
writes one: on a GPU its cost is the fill rate of the frame, and bloom's chain runs at a quarter of the pixels or less.

Where to see what the effects cost: `render.frame_graph` has a `postProcess` object with the post-processing passes (`bloom-*`,
`exposure-*`, `post`...) and their summed `cpuMs` and `gpuMs`; the GPU time is `null` with `gpuStatus` `"unavailable"` and a reason where
the backend has no timer (never 0), and the editor's Profiler panel shows the same in its "Post-processing" tab. The effects that share
the single `post` pass are not timed one by one (no per-effect estimate): `post` is their total
([PERFORMANCE_PROFILING.md](../performance/PERFORMANCE_PROFILING.md)).

Things to know:
- **Linear scenes.** `SceneSettings.colorSpace` `linear` with nothing that converts the picture (no exposure, tonemap or colour filter)
  adds no pass: the copy to the screen encodes it, as in "Color space". With any of them the `post` pass reads the linear light, converts
  it and encodes it once (the screen copy then only copies), and the HUD is drawn after it in display colours.
- **The HUD is not exposed.** A game that wants its HUD to follow the exposure draws it into the world instead. The colour filter
  does cover it (it is the player's setting).
- **`bloomScreenSpace`.** With `post` in the frame the HUD is drawn after it, so it never glows whatever the field says; without
  `post` the field works as before.
- **Lens dirt.** `bloomLensDirt` is a texture (stretched over the screen) that multiplies the glow by `1 + dirt * bloomLensDirtIntensity`.
- A camera that draws into a texture (`renderTarget`) never has a stack: the effects are for the picture the player sees.

### Reading and changing the stack: commands, looks and the editor panel

- `postprocess.get {"id": "camera", "resolved": true}` answers with the stack the camera draws, computed on the CPU (it works without a
  window): `layers` (the camera's own PostProcess, then each volume the camera is inside, with
  its priority, weight and influence) and `effects`, every effect in the order it runs with `enabled` and, for each parameter of an
  effect that runs, `{value, from, strength}`. `from` is `own`, `volume:<entity id>` or `default`, so "why is the picture
  this dark" has an answer: the field that sets it and the entity that owns it. Without `resolved` it reads the component's own fields.
- `postprocess.set {"id", "fields"}` writes fields of a PostProcess (added when the entity has none: on a Camera entity it is the
  camera's own stack, on an entity without a Camera a volume) and `postprocess.presets` lists the looks. `postprocess.apply_preset
  {"id", "preset"}` applies one: without `"keep": true` the look replaces every effect of the target with exactly its own (the
  volume's shape, size and priority stay), with it only the effects the look names change. The looks are data, not code
  (`engine/runtime/data/postprocess_presets.json`): `neutral` (everything off, the way back), `cinematic`, `retro`, `noir`, `dreamy`,
  `vivid` and `horror`, built only from fields that exist. A look that names an effect this renderer does not draw
  (`render.supports` says `false` with the reason: a GPU without float targets or without the depth prepass, say) still
  applies, and the answer says so: `notDrawn` lists them and `note` explains that their fields are stored and show where
  the renderer can draw them. `drawnChecked` is false when there is no renderer to ask
  (`graphics=false`).
- **View > Post-processing** (docs/EDITOR.md) is the same stack on screen: a camera chooser, each effect in the order it runs with its
  switch, a "running" or "off" mark, whether this renderer draws it (`unsupported` with the reason on hover), its fields
  with the source of each value, one button per look and a **Stack off (A/B)** check that draws the game without any post-processing
  to compare (`Renderer::set_post_bypass`: it changes no data and ends when the panel closes, collapses or is hidden behind another tab; while it is on, every capture of the game shows the picture without the stack too). Every edit goes through
  `postprocess.set` or `postprocess.apply_preset`, one undo step each, to the camera's own PostProcess or to the volume picked under
  "Edit"; an effect this renderer does not draw (unsupported on this GPU) cannot be switched on from the panel (a look that switched it on can be switched off).
