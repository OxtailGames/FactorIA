# Rendering, the ray tracing denoiser (M79-P1n)

The ray traced shadows, ambient occlusion, reflections and global illumination of M79 trace a few rays a pixel, so every
signal comes out noisy. `RtDenoiser` (`engine/render/src/rt_denoise.{h,cpp}`, shaders `engine/render/shaders/rt_denoise.glsl`)
is the one denoiser they share: a temporal accumulation with reprojection followed by a variance-guided a-trous wavelet filter
(the family of SVGF and A-SVGF; the code is the engine's own, only the ideas are the published ones). It is a renderer-private
module: nothing in it is a public API, a component or a command. The ray traced ambient occlusion (P2b, `DenoiseKind::Occlusion`, signal id 2) and
the ray traced soft sun shadows (P2a-2, [ARCHITECTURE_RT_EFFECTS.md](ARCHITECTURE_RT_EFFECTS.md), "Soft shadows", `DenoiseKind::Visibility`,
signal id 1) are its callers, each signal with its own history per camera; the later ray passes declare a signal with `add_passes` and read the
image it returns. The renderer sweeps it every frame and releases it when ray tracing goes off.

Everything here runs as full-screen fragment passes through `fa::gpu`, so it works on every backend (Metal, D3D11, D3D12,
Vulkan, GL, WebGL2 shaders come from the same sokol-shdc source). No compute, no storage image, no vendor SDK.

## What a caller does

```cpp
RtDenoiser denoiser;                                   // one per renderer, owns every history
DenoiseCamera cam = make_denoise_camera(camInfo, camKey, serial, sceneKey, originShifts, prevViewProj, prevValid);
DenoiseSignal sig;  sig.kind = DenoiseKind::Visibility; sig.id = 1;      // id: this signal among the camera's
DenoiseInputs in;   in.noisy = ...; in.prepass = ...; in.width = w; in.height = h;
DenoiseOutput out = denoiser.add_passes(graph, targets, gpu, cam, sig, in, &drawCalls, "shadows");
// out.res: transient, r g b = the denoised signal, a = the variance of the estimate. Later passes list it in their reads.
denoiser.sweep(serial);                                // once a frame, after every camera asked
```

- `DenoiseKind`: `Visibility` (a shadow, 1 channel, in r), `Occlusion` (1 channel), `Diffuse` (rgb radiance), `Specular`
  (rgb radiance and the hit distance in a: world units, negative when the ray missed) and `Coverage` (M79-P3a-2: one channel, 1
  where the alpha of the input is a hit distance above 0, else 0; the input is a `Specular` signal's own image, whose hit
  distance steers the reprojection the same way). A one-channel signal comes out in r, g and b alike.
- `DenoiseInputs`: `noisy` (Rgba16F or Rgba32F), `prepass` (the camera's prepass: r linear view depth, gb octahedral
  view-space normal, a = 1 where a mesh was drawn), `velocity` (optional: rg = uvPrev - uvCurr of moved objects, the sentinel
  1024 where none moved), `roughness` (optional, specular: r). A `DenoiseImage` is either a transient of the frame graph (`res`
  and `targets`: the passes list it in their reads) or a texture view the caller keeps (`view`).
- `DenoiseSignal::enabled = false` is how a vendor denoiser takes over a signal, and it is in use (M79-P4b-2): when DLSS Ray
  Reconstruction will draw the frame, `Renderer::Impl::rr_signals` (renderer_upscale.cpp, decided once per frame in `build_graph` before the RT
  passes are recorded, from the state `vendor_upscale` uses) hands it the reflections (`Specular` and `Coverage`, signal ids from
  `rt_reflect_signal_id`) and the per-pixel GI (`Diffuse`, `kRtGiPixelSignalId`), and those calls pass `enabled = false`: `add_passes` declares nothing,
  returns `valid = false` and frees that signal's history now, and the composites read the noisy images. The AO and the shadow masks never take
  this path: they are visibility (a darkening and a mask applied before the upscaler), not radiance, and Ray Reconstruction has no guide for them. Frames that decided "take" and were not drawn by Ray Reconstruction show
  one noisy frame (a Super Resolution fall back) and the next frame's `add_passes` finds no history, so it reports `DenoiseReset::Fresh`
  (test: `rt_rr_signals_tests.cpp`). `add_passes` is not the place that decides: it only honours `enabled`. A call
  that cannot run also returns `valid = false` with `why`: an input is missing, the shaders did not compile
  (`unavailable()`), the history is over the budget (`refused()`), or the same signal was already declared for this camera in
  this graph. In every case the caller shows the signal undenoised.
- `DenoiseCamera::camKey` and `id` key the history. `serial` is the game frame (consecutive frames are consecutive numbers),
  `sceneKey` the scene's identity, `originShifts` the floating-origin rebases so far, `prevValid` the camera's rule that the frame
  before is its own (`PostPlan::prevValid`; false after a cut). `make_denoise_camera` fills `proj`, `halfX/halfY` and
  `prevFromView = prevViewProj * view.inverse()` from a `CameraInfo`; the matrices are the unjittered ones.

## The passes

Pass names are `<job>/denoise-guide` (once per camera and graph) and `<job>/denoise-<name>-<id>-...` with `name` = `DenoiseSignal::name`
or the kind's name and `id` the signal's (two signals of a camera with one name do not collide in the graph).

| Pass | Reads | Writes |
|---|---|---|
| `denoise-guide` | the prepass | the camera's guide history (Rgba16F, two images): r linear depth (0 where nothing was drawn), gba the WORLD-space normal |
| `-guide-half` | the camera's guide of this frame | the signal's own half guide (a half size signal only) |
| `-down` | noisy, the full guide, the half guide | the signal's block means at half size (a half size signal only) |
| `-temporal` | noisy (the block means at half size), the camera's guide of this frame (not the prepass), velocity, the guide history, colour and moment history, roughness | the accumulated colour (transient, a = the variance of the estimate) and the moments (history, two outputs of one pass) |
| `-atrous0` .. `-atrous<N-1>` | the previous iteration, moments, the camera's guide of this frame (not the prepass), roughness | a transient; step 1, 2, 4, ... pixels |
| `-up` | the last iteration, noisy, the full guide, the half guide | the full size result (a half size signal only) |
| `-debug` | the last iteration or the moments | a grey picture (only when `DenoiseSignal::debug` asks) |

The guide history is the previous frame's depth and normal in world space, so a camera that turned still compares like with like
(a view-space normal would differ between frames). The guide image this frame writes is also what every filter iteration reads for
the depth and the normal of its taps: one fetch of an already decoded world normal instead of the prepass's octahedral code decoded
again in every tap of every iteration, and the normals' cosine is a plain dot product (the pixel's own normal is turned back into
view space with the view's rotation, for the plane test).

The temporal pass reads the same guide image as the filter (its depth for the history test and its world normal for the cosine), not the
prepass: the prepass's octahedral normal is decoded once, by the guide pass.

Passes of a signal: `1 + iterations + (debug ? 1 : 0)`, and 3 more at half size (`-guide-half`, `-down`, `-up`; one iteration fewer, see
"Half resolution"); the camera's guide pass is one more for the first signal of a camera in a graph. Transient images: the
accumulation, one or two filter buffers (the iterations alternate) and the debug picture (half size: and the block means and the full size
result). Persistent images per signal: four (colour history and moments, two each, flipped every frame; six at half size: its own half guide
history is two more) plus the camera's two guide images.
`make_denoise_plan(signal, w, h, momentsF32)` reports all of these as a pure CPU result (`DenoisePlan`), which the tests check.

### Temporal pass

1. The sample is read; a NaN channel becomes zero and the others are clamped to 0 .. 65000. A radiance kind is firefly-clamped: the luminance of a
   sample brighter than `fireflyClamp` times (the mean of its 3x3 neighbours + 0.01) is brought down to that (`fireflyClamp` 0 = off; a
   visibility or an occlusion is bounded and never clamped).
2. Reprojection: the velocity image when it holds an entry (`|v| < 512`), else the camera's own movement from the depth
   (`prevFromView`). The four history pixels around that position are taken with bilinear weights, each only when it was drawn,
   its stored depth is within `depthTolerance` of the depth it should have (plus a slope term) and its world normal's cosine with
   this pixel's is at least 0.9. When no tap passes, the pixel is a disocclusion: its history length restarts at 1. A `Specular` or
   `Coverage` signal (a reflection does not move with its surface) first tries the position of the VIRTUAL point, the surface's view
   position moved `hit` further along the view ray (the accumulated hit distance, a miss counted as 60000; an orthographic camera moves it
   along its axis), reprojected with `prevFromView`; the depth test still uses the surface's own previous depth, widened by the slope
   over the pixels between the two positions. Only when no tap of the virtual position passes does it fall back to the surface's motion
   (and a velocity entry, which is the object's, keeps the surface motion). Nothing changes for the other kinds.
3. Accumulation: a running mean over the history length, which grows by one a frame up to `maxHistory` and then becomes an
   exponential mean. The first and second moments of the luminance are accumulated the same way (Rgba32F, or Rgba16F where the
   GPU cannot render to Rgba32F; variance by cancellation needs the precision).
4. Variance: the temporal variance `m2 - m1^2`; while the history is shorter than 4 frames the spatial variance of the 5x5
   pixels that show the same surface stands in for it and hands over as the history grows. The variance of the estimate is that
   divided by the history length.
5. Bounds for 16-bit images: the luminance the moments take is capped at 250 (its square fits a 16-bit moment image, the path of a GPU
   without Rgba32F), and every variance written (the `a` of the colour images) is capped at 60000 (a 16-bit float holds 65504: an
   infinity there would meet a filter weight of exactly 0 and make a NaN that grows with every iteration). The cost: above a
   luminance deviation of about 250 the filter sees the variance of 250, so the luminance weight is looser there.

### A-trous iterations

Each iteration is a kernel with holes (`step` pixels apart): a 3x3 `[1 2 1]/4` per axis in the first iteration (step 1: its taps are the
ones of the 3x3 variance read, so the pass costs about half of what a 5x5 did, and the filtered result is still the history), a 5x5 B3 spline
in the second (without its four corners, 1/256 each and 1.6% of the weight together: the weights of the other 21 taps are normalised without
them) and a 3x3 again from the third on (`kWideFrom`; those steps are 4, 8 and 16 pixels, the taps are far apart and the outer ring of a B3
adds little there: 9 taps instead of 21). The first iteration of a full size signal takes 1.3 ms at 1080p (M5, Metal, 54-entity scene; "Cost"
has the rest). A neighbour's weight is the kernel weight times
- a plane term, `exp(-d^2)` with `d` the distance of the neighbour's view-space position to this pixel's tangent plane over
  `depthTolerance * depth * (1 + 0.1 * step)`,
- the cosine of the normals to the power `normalPower` (a neighbour facing away has no weight),
- a luminance term `exp(-|dL| / sigma)`, with `sigma = lumaSigma * sqrt(3x3 Gaussian of the variance) + 1e-4`,
- for the signals that have one, the roughness term below.

The four terms are one `exp2` of the sum of their logarithms (one transcendental a tap instead of four).

A pixel that is already clean is not filtered: from the second iteration on (`kCalmFrom`; the variance it reads is then the filtered
one of a neighbourhood, not one pixel's, which is what makes it safe) a pixel whose standard deviation is under 0.003 of its
brightness plus 0.25 (`kCalmSd`: less than one level of an 8-bit picture) is copied, which costs its own two texels. The first iteration
never does: a pixel whose own history has no spread yet (a Bernoulli signal that was 0 every frame so far has a variance of exactly
0) must still take the signal from its neighbours (a test covers it). A converged static scene is mostly such pixels: the later
iterations of AO cost 0.1 to 0.3 ms at 1080p instead of 2 ms each (M5, Metal, 54-entity scene).

A pixel whose guide says nothing was drawn there (r = 0), and a reflection pixel the temporal pass did not denoise (its variance is -1, see
"Reflection pixels the caller does not read"), are copied the same way and are not taken as neighbours. The temporal and a-trous
callbacks also draw nothing when the camera's guide is not this frame's (the guide pass did not run, or its images are another frame's:
the slot's serial and the image the pass wrote are compared): a filter that read a stale guide would weigh the taps by another frame's
depth and normal. The graph's reads make the guide pass run before them in a normal frame, so this is a guard (no test reaches it), not a path a frame takes.

The variance is filtered with the squared weights, so each iteration's output carries the variance of its own estimate. The
result of iteration 0 is written to the colour history (that is why there are at least two iterations: the history stays
lightly filtered, the last iteration is for display only). Iteration `i` reads the result of `i - 1`.

A `Specular` signal and the `Coverage` of one limit the step by the lobe: the footprint of the reflection cone at the hit,
`roughness^2 * min(hitDistance, 64 * depth)` over the world size of a pixel, halved. A mirror (roughness 0) keeps its image; a
rough surface is filtered like a diffuse one. The roughness comes from `DenoiseInputs::roughness` or `DenoiseSettings::roughness`.
A `Specular` or a `Coverage` signal also multiplies a neighbour's weight by `exp(-8 |roughness - this pixel's roughness|)` when the
roughness image is bound (two surfaces of another roughness show other reflections). The lobe limit applies to both kinds (the coverage
of a mirror is as sharp as its image: it reads the accumulated hit distance of the signal it came from); until M79 POLISH-denoise-2 it ran
for `Specular` only, and the coverage of a mirror was blurred by the full step.
The hit distance is accumulated with the colour like the moments (a miss, negative, counts as 60000 units, a NaN as 0); the lobe limit reads it capped at 64 times the pixel's depth.

### Reflection pixels the caller does not read

The composite of the traced reflections reads the denoised image only where the roughness is in `[kRtReflectSharp, kRtReflectLimit]`
(0.25 to 0.65; the sharp pixels read the raw mirror image, the rougher ones are not traced). `DenoiseSignal::roughMin` and `roughMax` (a
`Specular` or `Coverage` signal with a roughness image; the renderer sets the two constants) tell the temporal pass: a pixel whose roughness
is outside the window, or whose alpha is exactly 0 (the kernel did not trace it: with or without a window), comes out as the sample with a
variance of -1, a history length of 0 and no accumulation. The filter copies those pixels and does not take them as neighbours, and the history
gather ignores their taps, so a value that nobody reads can neither cost nor bleed into a pixel that is read. It is a skip inside the existing
passes (the pixel's other work is not done), not a kernel change: the passes still cover the full screen. A pixel that enters the window
starts a new history. A signal without a window (0 to 1) denoises every traced pixel, as before.

### Half resolution

`DenoiseSignal::halfRes` (an `Occlusion` or a `Diffuse` signal; any other kind ignores it, see `DenoisePlan::halfRes`) runs the temporal
pass and the filter on half the width and height, rounded up (a quarter of the pixels, and of the history). The renderer sets it for the ray
traced ambient occlusion and the per-pixel global illumination: both are low-frequency (a hemisphere's occlusion, the indirect light), and
a joint bilateral upsample brings the edges back from the full guide. The soft shadows (a shadow's edge is the signal), the reflections
(sharp by nature) and the coverage keep the full size. The chain:

1. `-guide-half`: a half guide pixel is the nearest to the camera of the (up to four) drawn pixels of its 2x2 block (at an edge the block
   shows the surface in front). The signal's own history of it (`hg`, two Rgba16F images at half size) lets the temporal pass test
   disocclusion at half size.
2. `-down`: the mean of the block's pixels that show the half guide's surface (the depth within twice `depthTolerance` and a normal
   cosine of at least 0.9), so a block over an edge does not mix the two sides; a block of sky passes the plain mean.
3. `-temporal` and the iterations at the half size. One iteration fewer (`max(2, iterations - 1)`): a step of 2 full-size pixels covers
   what two steps did. The history is `ceil(w / 2) x ceil(h / 2)` and its config key changes, so a signal that switches size starts anew.
   The velocity image has the full size: the temporal pass reads it at the texel of the block that the half guide took (the first of the
   four with the half guide's depth), never at the corner the four texels share, where a point sampler's choice depends on the GPU.
4. `-up`: every full-size pixel takes the four nearest half pixels with the bilinear weights times a plane term and the cosine of the
   normals to the power `normalPower` (full guide against half guide), plus a floor of 0.001 of the bilinear weight so that a pixel that
   no half pixel matches (a thin feature) still gets a value; a pixel with nothing drawn, or with no weight at all, passes the noisy
   sample through, as the temporal pass does. A half pixel `q` is at `(2q + 1) / full size` in the full image (not `(q + 0.5) / half size`,
   which differs on an odd size).

The three half size programs (`guidehalf`, `down`, `up`) are compiled when the first half size signal asks, not with the others. A backend
that cannot compile them (only Metal ran them on a real GPU here; CI compiles and runs the GL and D3D11 ones) runs that signal as a full size one, says so
once in the log (`RtDenoiser::half_unavailable()`), and every other signal denoises as before.

Memory: the history is 64 bytes per half pixel (the 48 and the two 8-byte guide images), a third of a full size signal's 48 per pixel of
the camera: 31.6 MiB at 1080p against 94.9. The signals that carry a sharp edge in their own pixels (a shadow, a mirror) lose it at half
size, which is why only two kinds may ask for it.

### Settings

`DenoiseSettings` (all clamped by `sanitize_denoise_settings`; a number that is not finite takes its default): `iterations` 5
(2 to 6), `maxHistory` 32 (1 to 255), `fireflyClamp` 8 (0 to 64), `depthTolerance` 0.02 (0.001 to 0.5), `normalPower` 64
(1 to 256), `lumaSigma` 4 (0.5 to 16), `roughness` 0.5 (0 to 1). The guide's world normals are Rgba16F, so a normal is a unit vector to
about one part in a thousand: the filter takes the pixel's own length out (`normalize`) but not every tap's, so at a high `normalPower`
the cosine's power can be off by about `normalPower` times that (the weight of a tap of the same plane, 6% at the default 64, up to 25% at 256,
the same for every tap of a flat surface, so it changes the weights between planes more than within one). Keep `normalPower` at or under 64
unless a test of your own shows the edge needs more.

## History: when it holds

The history of a signal is reset (the frame starts a new one: `DenoiseOutput::reset` says why) by the first of these rules,
`denoise_reset_reason`:

| Reason | When |
|---|---|
| `Fresh` | no history yet (a first frame, a signal that was off) |
| `Resize` | the images have another size (the old ones are destroyed and made again) |
| `Gap` | the signal did not run on the frame before (`serial` is not the last one plus one) |
| `Scene` | `sceneKey` changed |
| `Origin` | `originShifts` changed |
| `Settings` | the kind, `maxHistory`, `fireflyClamp` or `depthTolerance` changed (the history's numbers mean something else); `iterations`, `lumaSigma`, `normalPower`, `roughness` and the debug view do not reset |
| `Cut` | `prevValid` is false |

`reset(camKey)` drops what a camera (or all, 0) accumulated; the next frame of each signal starts anew. `forget_targets()` frees
every history (a lost GPU or a resized window). `last_reset(camKey, id)`, `last_used_history`, `resets()` and
`history_image_count()` expose the state to tests.

The state of a slot is committed in the pass callbacks, not when the passes are declared: a graph that is declared and never run
does not make the next frame believe it blended with a history that was never written.

## Free when unused, the budget

- Nothing exists until the first `add_passes` with an enabled signal: no shader is compiled (`shaders_made()` false), no pipeline,
  no image. A signal switched off frees its history at once; `sweep(serial)` frees a signal that did not run on the frame before
  `serial` and a camera that did not ask.
- The histories of all cameras together may take 1 GiB (256 MiB on wasm32). The check runs before an image is allocated, in 64-bit
  with saturation. A refused signal is logged once ("Ray tracing denoiser: signal ... needs N MiB of history images (WxH) and the
  renderer may hold M MiB of them in all (K MiB are in use by the other signals and cameras) ... Hint: lower the render scale or the
  window size, or turn off a ray traced effect that is denoised") and returns `valid = false` with the same numbers in `why`
  ("the history images do not fit the budget of M MiB (N MiB wanted, K MiB in use)"); the caller shows the noisy image. Nothing stays
  allocated for it. `set_budget` is for tests.
- On wasm32 at 1080p the 256 MiB hold a camera's guide (31.6 MiB) and two full size signals (94.9 MiB each, 221 MiB in all) and one more
  half size signal (31.6 MiB, 253 MiB in all); the effects that ask later are shown noisy.

### Memory

Every pixel of a signal's history is 48 bytes (two colour images of Rgba16F, 8 bytes, and two moment images of Rgba32F, 16 bytes;
32 bytes when the GPU cannot render to Rgba32F and the moments are Rgba16F), and every camera's guide 16 bytes (two Rgba16F images).
A half size signal's history is 64 bytes per pixel of its half size image: the same images and its own guide history (two more Rgba16F images).
The budget counts these persistent images only. The frame's transient images (the accumulation and the two filter buffers, Rgba16F,
8 bytes a pixel each, the debug picture when asked) come from the frame graph's pool and alias with its other transients; they are not
in the budget.

| Size | Pixels | One signal (moments 32-bit) | A camera's guide | Signals that fit 1 GB with one guide |
|---|---|---|---|---|
| 1920x1080 | 2.07 M | 94.9 MiB | 31.6 MiB | 10 |
| 2560x1440 | 3.69 M | 168.8 MiB | 56.3 MiB | 5 |
| 3840x2160 (4K) | 8.29 M | 379.7 MiB | 126.6 MiB | 2 (3 with 16-bit moments, 253 MiB each) |

The signals of one camera (`renderer_impl.h`, `kRt*SignalId`): the sun's soft shadow 1, the local lights' visibilities 1 (up to three
lights packed in the three channels of one signal), reflections 2 (the radiance and the coverage), ambient occlusion 1, per-pixel
global illumination 1: six at most. The effects declare their signals in that order within a frame, so at 4K the third one that asks
is refused (the later effects are the ones shown noisy) and the log says so once; at 1440p the AO and the GI are half size signals (56.3 MiB
for the guide, 4 full size ones of 168.8 and two half ones of 56.3), so all six fit (844 MiB), at 1080p as well. Lowering the render scale or leaving an effect out brings the camera back under the budget.
`rt_denoise_plan_tests.cpp` checks these numbers.

## Cost

The GPU time of the denoiser's passes in one frame (M5, Metal, 54-entity scene `tools/cli/tests/fixtures/rt_cost`, 1920x1080, a Release build, a
temporary GPU timestamp per pass that is not in the engine, the median of three interleaved runs of the builds below, a static camera; a moving
camera, a second project of the same scene with the camera moving, gave 4.5 to 1.9, 9.0 to 6.5, 9.7 to 3.4 and 8.3 to 2.4 ms in the same order):

| Effect | M79 POLISH-denoise (start of this package) | Now | Where it went |
|---|---|---|---|
| ambient occlusion (half size) | 4.8 ms | 1.9 ms | half size (guide-half 0.1, down 0.4, temporal 0.2, iterations 0.36 + 0.14 + 0.07 + 0.07, up 0.4) |
| soft shadows (two signals, full size) | 9.0 ms | 6.2 ms | first iteration 2.6 to 1.3 ms for each of the two signals |
| reflections (image and coverage) | 11.1 ms | 4.9 ms | the temporal pass skips the pixels nobody reads, a 3x3 first iteration, three iterations for the coverage |
| per-pixel GI (half size) | 9.5 ms | 2.8 ms | half size, the 3x3 first iteration |

Before M79 POLISH-denoise the same four were 14.1, 29.6, 28.1 and 16.0 ms (M5, Metal, 54-entity scene). What is left of the soft shadows is
two temporal passes (1 ms each) and two first iterations (1.3 ms each): the shadow's edge is the signal, so they keep the full size. The
rest of the frame (the rays, the composites) is not the denoiser's: docs/RAY_TRACING.md, "What it costs", has the frame times. Only the M5 on Metal has been
measured; the GL (lavapipe) and D3D11 (WARP) numbers are not.

## Debug views

`DenoiseSignal::debug`: `HistoryLength` shows the history length over `maxHistory` as a grey level (a disoccluded pixel is dark
and brightens frame by frame); `Variance` shows `sd / (sd + 0.01)` of the final estimate's standard deviation (dark on a clean
signal). `DenoiseOutput::debug` is a transient of the same size, read like `res`. The public `Renderer::DebugView` is not wired
to it yet: the ray passes of the later packages do that.

## Determinism and portability

No random number or clock is used: the same inputs give the same bytes on a machine (the test compares two runs). Between GPUs
the last digits differ (floating point, 16-bit storage): a test compares with thresholds, never with equality across devices.
The guide and the filtered colours are Rgba16F; the moments Rgba32F (Rgba16F on a GPU that cannot render to it,
`force_moments_f16` for tests). On OpenGL a render target is bottom-up: every pass takes a flip flag the same way `TaaFx` does.

## Tests

`engine/render/tests/rt_denoise_plan_tests.cpp` (CPU, in `render_postprocess_core`): passes and images per kind, nothing for a
disabled signal, saturating byte counts, the 4K memory and how many signals fit the budget, settings clamping, the config key, the reset rule order, the free-when-unused state, the half size chain (passes, images, bytes, the kinds that ignore it) and the roughness window's clamping.

`engine/render/tests/rt_denoise_tests.cpp` (the host GPU, 64x48 images, the whole file takes about a tenth of a second on Metal (an Apple M5), not measured elsewhere; thresholds sit
5 to 10 times from what Metal measures, and each says its reasoning in a comment):
- a Bernoulli(0.3) visibility: the raw mean absolute error is 0.42; one frame filtered gives under 0.10 (measured 0.044), 24
  frames under 0.025 (measured 0.010); the sky, where no mesh was drawn, passes through;
- a diffuse radiance of three channels converges within 5% of the raw error of each channel;
- an edge in depth and an edge in the normal are not blurred (within 0.06 of the side's truth next to the edge; across it
  would be 0.4);
- a block of closer geometry starts at history length 1 and holds its own truth after four frames;
- the six reset reasons, the resize, and that changing `iterations` does not reset;
- a specular mirror keeps its temporal-only image while a rough surface is filtered (error under a tenth); the same for the coverage of a
  mirror and of a rough surface (the lobe limit; error under a half);
- a `Coverage` signal converges to the share of the rays that hit, and a reflection of a pattern behind a mirror, with the camera moving,
  stays closer to its truth with the true hit distance than with none (the virtual-motion reprojection: error 0.065 against the surface's
  0.262 on Metal, thresholds 0.1 and half of the surface's: a margin of 35% and 50%; the sine is smooth and the filter is the mirror's
  temporal blend, so a GL or lavapipe rasteriser's last digits move it by far less, and the thresholds stay);
- a specular signal with a roughness window: the pixels outside it and the untraced ones (alpha 0, value 50) come out as the sample to the
  half float's rounding, the pixels inside are filtered (error 0.008 against the raw 0.25) and the ones next to the skipped rows are not
  pulled towards them;
- a firefly of 1000 is clamped to under 6 (34 without) and a NaN does not spread;
- radiance noise of 0 to 4000 (a luminance deviation of 1150, far over what a 16-bit variance holds), diffuse and specular, with 32-bit and
  16-bit moments: every colour and debug value is finite, none is above the brightest sample and the mean stays within 10% (on Metal
  this passes with and without the bounds, since it saturates a 16-bit write; the case guards the platforms that write an infinity);
- the same inputs give the same bytes; the variance view is dark on a clean and bright on a noisy signal;
- every filter iteration and the temporal pass read the guide image the guide pass writes (the compiled graph's reads);
- a pixel whose history saw only zeros (variance exactly 0) still takes the signal from its neighbours (the first iteration never skips:
  127 of 880 pixels stayed dark when it did);
- a faint pattern (0.5 +- 0.001) comes out bit for bit the same from a filter of 2 iterations and one of 5 (the later iterations leave a
  calm pixel alone), a strong one (0 or 1) is smoothed further by the longer one;
- half size: an occlusion of 63x47 declares guide, half guide, down, temporal, four iterations and up, converges (first frame 0.013, 24
  frames 0.004 against the raw 0.42), passes the sky through, keeps a depth edge on an odd column apart (the edge's own columns within 0.006
  of their truth; blurred across it they would be 0.3 off); a half size diffuse keeps its colours; a specular signal asking for half
  size runs at full size;
- free when unused: no shader, pipeline or image before a signal asks, a disabled signal declares nothing, a camera is swept, the
  budget refuses with a reason that gives the MiB wanted, in use and allowed, a signal declared twice in a graph is refused.

Only Metal (an Apple M5) has run these tests so far: the llvmpipe and D3D11/WARP numbers are not measured yet.
