Part of [RENDERING.md](../RENDERING.md): the screen-space effects of the post-processing stack that read the depth and normal prepass
(ambient occlusion now; reflections and fog join this page when the renderer draws them).

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
