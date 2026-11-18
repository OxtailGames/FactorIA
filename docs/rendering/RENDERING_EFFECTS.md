Part of [RENDERING.md](../RENDERING.md): the screen-space effects of the post-processing stack that read the depth and normal prepass
(ambient occlusion, fog and sun shafts now; reflections join this page when the renderer draws them).

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

## Fog

`fogEnabled` fades what is far (and what is low) into `fogColor`, drawn from the depth of the prepass. Along the view ray from `fogStart`
to the surface (`L` world units long) the optical thickness is

    tau = (fogDensity * L)^2  +  L * (average height density along the ray)        f = 1 - exp(-tau)

and the pixel becomes `mix(scene, fogColor, f)`. The first term is the law of `SceneSettings.fogDensity` (exponential squared), so a scene
that moves its fog into the stack keeps its look; `fogDensity` is limited to 0..10. The height term is a layer of density
`fogHeightDensity` (0..10) that is constant at and below `fogHeightBase` (a world y) and thins above it as `exp(-fogHeightFalloff * (y - base))`
(`fogHeightFalloff` 0..10; 0 = a flat layer up to infinity); it is integrated exactly along the straight view ray, so a cube below the base
is thicker in fog than one above it at the same distance, and a camera inside the layer looking down sees more of it than one looking up.
A fog with no distance and no height density draws nothing.

- **The sky is not fogged.** Pixels where the prepass saw no opaque mesh (the sky, 2D, the background, the clear colour) are left as they are,
  as the forward fog of the mesh shader does not fog them either; so a scene's horizon does not have to match `fogColor`, and the sun
  shafts below still see the sky.
- **Not drawn twice.** A camera whose stack fog is drawn replaces `SceneSettings.fogColor` / `fogDensity` for the frame (the mesh shader's
  fog is switched off for it); a camera whose stack fog draws nothing (no density, or the effect off) keeps the scene's fog. A scene
  with no `fog` in its stack is byte for byte the frame it was.
- **What it covers.** Opaque 3D meshes, as the prepass has only them; blended meshes, sprites, particles, text and the interface drawn
  before the post passes are not fogged by their own depth (a blended mesh keeps the forward fog of the scene; the stack's fog replaces it
  when it is on, so blended meshes then show no fog), and a HUD drawn after the post passes is not touched. Turn the effect's colour to the
  sky's colour to hide the seam.
- **Colour space.** `fogColor` is a display colour in both modes; a linear scene blends in linear light with the colour converted, so a
  thick fog shows exactly `fogColor` on the screen.
- **Per camera.** Each camera of a split screen has its own `camera:<n>/fog-blend` pass over its own rectangle, with its own position and
  projection; an orthographic camera measures the distance along its view direction. The pass is one full-screen draw that reads only the
  prepass (it makes no copy of the picture); off, or with nothing to draw, it adds no pass and no prepass of its own.

## Sun shafts

`sunShaftsEnabled` draws light streaming from the sun through the gaps of the scene. The sun is the first directional `Light` of the scene
(the same direction the lighting uses), seen from each camera; with no directional light, or when the camera lights by the studio rig, there
are no shafts. Per camera:

1. `shafts-rays` makes a half resolution, one channel image. For each pixel it takes 48 taps along the screen line toward the sun
   (`sunShaftsLength`, 0..1, is the longest line, in screen heights; the taps are shifted by a fixed noise of the pixel, so the picture is the
   same on every run). A tap adds light only where the prepass saw no mesh (the sky) and the brightness of the scene colour there, as the
   screen shows it, is above `sunShaftsThreshold`; the light is `(brightness - threshold) / (1 - threshold)` times a glow that is strongest
   near the sun. Whatever stands between a pixel and the sun's sky blocks the taps behind it, so the rays stream away from the silhouettes.
2. `shafts-add` multiplies the rays by `sunShaftsColor * sunShaftsIntensity` (0..2) and adds the result onto the camera's rectangle.

- **Fades.** The sun's place on the screen is the projection of its direction. The shafts fade out smoothly as the sun leaves the screen (gone a
  little outside its edge) and as it passes the side of the camera; with the sun behind the camera there is no pass and the picture is the
  one without the effect. The same holds for an intensity or length of 0, or a threshold above the sky's brightness (the rays are 0).
- **Perspective cameras only.** A sun at infinity has no place on an orthographic camera, so none is drawn there.
- **Fixed cost.** 48 taps per half resolution pixel, whatever the settings; two passes and a half resolution one channel image per camera
  (RGBA16F), made only while the effect draws.
- **With the fog.** The fog leaves the sky alone, so the sky keeps the brightness the shafts need; both run before the exposure, depth of
  field and bloom, in this order: `ssao`, `ssr`, `fog`, `sunShafts`.
