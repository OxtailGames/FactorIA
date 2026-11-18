Part of [RENDERING.md](../RENDERING.md): the screen-space effects of the post-processing stack that read the depth and normal prepass
(ambient occlusion and reflections now; fog joins this page when the renderer draws it).

# Rendering: screen-space effects

## Ambient occlusion

`ssaoEnabled` darkens creases and contact points of 3D meshes (GTAO: for a few directions on the screen the search looks up the
depth of the prepass and finds the highest horizon, then adds up how much of the hemisphere above the surface is open). `ssaoRadius` is in
world units (how far an occluder still counts), `ssaoIntensity` (0..4) is the power of the occlusion that multiplies the colour, and
`ssaoQuality` sets the cost: `low` (2 directions, 3 steps) and `medium` (3, 5) search at half the resolution of the camera's rectangle,
`high` (3, 6) and `ultra` (5, 8) at full resolution. `ssaoRadius` is limited to 0.01..20 (the field's range; a radius below 0.001
or an intensity of 0 switches the effect off). A blur that follows the surfaces (it does not mix a tap that is off the plane
of the pixel) removes the pattern of the search, and the apply pass of a half resolution search upsamples with the same weights.

- **Nothing is random.** The directions and steps are shifted by a fixed 4x4 pattern of the pixel, so the same scene gives the same picture on every run
  (golden screenshots do not flicker); an open flat floor keeps a few percent of error at a grazing angle, a crease is much darker.
- **In place.** The apply pass multiplies the occlusion into the game image (a blend, `DST_COLOR`), it does not make a new image. What
  was drawn into the game image before it is darkened too where it covers meshes (the prepass has only meshes): blended meshes, sprites, particles,
  text and **the interface drawn before the post passes** (a HUD in a frame without a `post` pass, or with `bloomScreenSpace`); a HUD drawn after (with a `post` pass) is not touched. A gamma scene gets
  the occlusion raised to `intensity * 1.5 / 2.2` and a linear scene to `intensity * 1.5`, which is the same linear result.
- **Where there is no occlusion.** Pixels with no opaque mesh (sky, sprites, background) are not changed; an intensity or radius of 0,
  the effect off, a frame with no opaque mesh, or a GPU without RGBA16F targets that blend and filter (the log says so once) make no
  pass and no image: the picture is the one without the effect. Each camera has its own passes (`camera:<n>/ssao-*`) over its own rectangle.
- **Seeing it.** `render.debug_view {"view":"ao"}` paints the occlusion alone as a grey over the camera's rectangle (white where it is open or
  there is no mesh), with the camera's own settings or, when it has none, the defaults (`ssao-view` replaces `ssao-apply`).

## What the ambient occlusion costs

Per camera, counted by `render.frame_graph`; sizes are for a camera rectangle of 1280x720. All of it is returned to the pool when
the frame ends, and nothing is made while the effect is off.

| `ssaoQuality` | Search size | Directions x steps | Horizon steps per output pixel | Passes | Extra memory |
|---|---|---|---|---|---|
| `low` | half (640x360) | 2 x 3 | about 1.5 | 4 (`ssao-ao`, `ssao-blur-h`, `ssao-blur-v`, `ssao-apply`) + `prepass` | the prepass image and two RGBA16F images of 1.8 MB each |
| `medium` | half | 3 x 5 | about 3.75 | 4 + `prepass` | the same |
| `high` | full (1280x720) | 3 x 6 | about 18 | 4 + `prepass` | the prepass image and two RGBA16F images of 7.4 MB each |
| `ultra` | full | 5 x 8 | about 40 | 4 + `prepass` | the same |

The cost does not double from one level to the next: "horizon steps per output pixel" is directions x steps (each step reads both
sides), divided by 4 where the search is at half size; the blur and the apply pass cost one full-screen read at every level. The prepass is
shared with the outline, the depth of field and the motion blur of the same camera.

## Screen-space reflections (`ssr`)

`PostProcess.ssrEnabled` makes opaque 3D surfaces mirror what the camera shows: the floor under a lamp shows the lamp, a wet street
shows the cars. It is a post effect of the camera's own stack (or of a volume): it works on the 3D picture of that camera, in linear
scene light, after the ambient occlusion and before the fog, the exposure, depth of field, bloom and the final pass, so the
reflected colour is the one the camera saw (a bright lamp reflects bright, and blooms in its reflection).

| Field | Default | Meaning |
|---|---|---|
| `ssrEnabled` | `false` | switches the effect on |
| `ssrIntensity` | `1` | 0..1: how much of the reflection is mixed in (0 draws nothing: no pass, no prepass) |
| `ssrMaxDistance` | `50` | world units a reflected ray travels (1..1000) |
| `ssrThickness` | `0.3` | world units behind a surface that still count as a hit (0.01..10) |
| `ssrSteps` | `32` | steps of the ray march, 8..128 (clamped; a NaN takes the default) |

### What is reflected

- **The ray.** Every pixel of an opaque mesh sends the mirror image of its view ray into the scene (the normal comes from the
  prepass, so a normal-mapped material reflects with its own normal), for at most `ssrMaxDistance`. The ray is followed across the
  screen in the prepass depth in `ssrSteps` equal steps of screen distance (a small deterministic jitter moves the first step, the
  same pattern every frame and every run, so the picture does not shimmer between runs) and the depth of the ray is interpolated
  correctly for a perspective camera. A step is a hit when the ray went behind the surface the prepass shows and was in front of it
  (or less than `ssrThickness` behind it) one step before; six bisections then find where it crossed. A ray that leaves the screen,
  passes the near plane or goes behind an object by more than `ssrThickness` finds nothing.
- **What a miss draws.** Nothing: the pixel keeps its own colour. Only what is on the screen can be reflected: an object behind the
  camera, outside the frame or hidden behind another object is not in the mirror, and a reflection fades out near the border of the
  screen (over the outer tenth) instead of ending in a line. Blended meshes, sprites, particles and the HUD are not in the prepass:
  they are not reflected (and they do not receive reflections: a pixel the prepass has no opaque mesh for is left alone, and so is the
  sky).
- **Fades.** The mixed-in amount is `ssrIntensity * fresnel` times four fades that remove the artefacts of the method: a ray that
  goes back toward the camera (it would need what is behind the viewer), a hit on the back of a surface (its normal faces away from
  the ray), a hit near the border of the screen and a hit near the end of `ssrMaxDistance`.

### How reflective a surface is

The renderer has no roughness or metalness image for the post stack to read, so the reflectivity is not a material property: every
opaque surface gets the **fresnel term** of the angle between its normal and the view, `F = 0.2 + 0.8 * (1 - N.V)^5`, multiplied by
`ssrIntensity`. A surface seen head-on reflects 20 % of `ssrIntensity`, one seen at a grazing angle (a floor far away, the side of a
street) almost all of it, as water, glass and a polished floor do. The result is a mix, `mix(scene, reflection, F * intensity)`: it
only takes colour from the picture itself, so a place with nothing bright to reflect does not get brighter. Choosing the reflectivity per surface (a roughness-driven blur, a mask) needs a material
image in the prepass and is not drawn yet; until then lower `ssrIntensity`, or put the effect in a volume (a box around the room with
the wet floor) so only that part of the world reflects.

### Cost and limits

- A frame without the effect (off, or `ssrIntensity` 0) declares no pass, makes no image and builds no shader, and draws the same
  bytes as before. The effect needs the prepass (`render.supports` answers `ssr` false and names the missing capability when the GPU cannot sample the depth or has no float targets) and
  float scene targets; where it is unsupported the stack still stores the fields and the game renders without it.
- Per camera, two passes: `<camera>/ssr-trace` (one full-screen pass of the camera's rectangle, `ssrSteps` depth reads per pixel at
  most, fewer where the ray leaves the screen early) and
  `<camera>/ssr-copy` (one copy back into the picture), and one image of the camera's size (the scene format, from the pool of the
  frame). `render.frame_graph` and the profiler panel list them with the other post-processing passes (the prefix `ssr`).
- A split screen traces each camera's rectangle on its own: a ray never leaves the rectangle of its camera, and each camera decides
  with its own stack.
- With multisampling the reflected colour is read from the resolved picture (one sample per pixel), and the result is written back to every sample.
- `ssrSteps` trades quality for time: with fewer steps a thin object can fall between two steps and its reflection breaks up; 32 is
  enough for floors and walls at the design resolution, 64..128 for thin railings.
- An orthographic 3D camera is traced too (the depth of the ray is then linear on the screen); a camera that draws into a texture has no
  stack, so no reflections.

```json
{ "type": "PostProcess", "ssrEnabled": true, "ssrIntensity": 0.8, "ssrMaxDistance": 30, "ssrSteps": 48 }
```
