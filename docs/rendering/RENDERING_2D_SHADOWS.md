Part of [RENDERING.md](../RENDERING.md): the shadows of `Light2D`, which stop at tiles and at `ShadowCaster2D` entities, and
the penumbra a light with a `size` gives them.

# Rendering: soft 2D shadows and shadow casters

A `Light2D` point light with `castShadows` casts shadows from two kinds of occluder:

- the solid tiles (`solidTiles`) of a `Tilemap` with `occludesLight` (always there since M18);
- every enabled `ShadowCaster2D` (M74.1): a sprite, a character, a prop or a plain shape.

Both are rays cut against the same row of distances per light, so they shadow each other, and `Light2D.size` softens the edge
of both. A scene with no `ShadowCaster2D` and every `Light2D.size` at 0 draws exactly the picture, with the same costs, as
before M74.1 (the goldens of the hard shadows are unchanged).

## ShadowCaster2D

Add the component to an entity; the entity's Transform (position, rotation, scale; a parent's too) places the outline.

| `shape` | The outline | Notes |
| --- | --- | --- |
| `spriteAlpha` (default) | The contour of the pixels of the entity's `Sprite` whose alpha is above `alphaThreshold` (default 0.5) | Needs a `Sprite` on the same entity (without one the caster blocks nothing and one warning says so). `region`, `size`, `pivot`, `flipX`, `flipY` and the pivot of a `SpriteAnimator` frame are followed. |
| `polygon` | `points`: `[x0, y0, x1, y1, ...]` in the entity's local space, at least 3 points | Convex or concave. More than 256 points are cut (one warning). |
| `box` | A rectangle of `size` centred on the entity | The cheapest: 4 segments. |

`lightLayers` is a bit mask of the `Light2D.lightLayers` the caster blocks (default -1, every light): the caster blocks a light
only when the two masks share a bit, so a roof can shade the street lights and let the indoor lamp through. A `Tilemap` with
`occludesLight` follows the same rule with `Tilemap.lightLayers` (default 1) against `Light2D.lightLayers` (default -1).

`selfShadow` decides what happens inside the outline. False (default): the caster is lit as the face of a tile is, so a
character stays lit by the torch it carries or walks past, and only what is behind it is dark. True: the shadow starts at the
near side of the outline, so the caster darkens itself behind its near edge. A light that is inside a caster's outline is not
blocked by that caster (a lamp held in a hand, a torch in a brazier).

### How a sprite's contour is made

The first frame a `spriteAlpha` caster is drawn, the engine reads the alpha of the texture's file, runs marching squares on the
pixels above the threshold (inside the `region` when the sprite has one), and simplifies each outline with Douglas-Peucker to
at most 256 segments in all (a closed outline of about 0.6 px accuracy; a bigger region is reduced by blocks first, so the
accuracy is coarser for a texture over 512 x 512 pixels). Holes are kept (a ring blocks only its ring), at most 16 outlines per
sprite, the biggest first, and specks under 1 px2 are dropped.

The contour is cached per texture, region and threshold (the flips mirror the same contour), so a thousand copies of a prop
make it once, and a sprite that moves, turns, scales or flips makes no new one. The cache keeps up to 4096 contours and 32 MB of
alpha planes, then drops the least recently used. A texture that is reloaded gets a new GPU image and so makes a new contour.

When the alpha cannot be read, the sprite's rectangle blocks light instead and one warning names the reason and the fix: the
texture is packed in an atlas by an export (its pixels are not in a file any more), it is a render target or a generated
texture, it is over 16 million pixels, or the file is missing. Use `box` or `polygon` for those sprites.

## Soft shadows: Light2D.size

`size` is the radius, in world units, of the light source. 0 (default) is a point: a hard edge (softened by about one pixel, as the tiles always were). Above 0 the shadow gets a penumbra that grows with the distance past the occluder, like the shadow of a
post under a street lamp: sharp where the occluder touches the floor, wide far from it. The transition is about
`2 x size x (d - b) / b` world units wide, where `b` is the distance from the light to the occluder and `d` the distance to the
point being shaded (the half-width of the blur is limited to 0.7 radians of the light's view). A box 20 units from a light of `size` 4 shades the floor
100 units past it with a transition about 40 units wide, and the floor right behind it with a sharp one.

Each pixel looks for the occluders around its direction (12 reads of the shadow row), takes their mean distance `b`, and averages
16 hard lookups over the penumbra with a tent weight. A pixel with nothing in the way pays the 12 reads only; a pixel in a
penumbra reads up to 44 texels in all, against 2 for a light with size 0. The shader branches on the size, so a scene whose lights
have size 0 runs the same code path as before. The penumbra of two occluders at different distances is the one of their mean
distance (an approximation: a thin fence near the light and a wall far away share one blur width).

## Many shadowed lights

Every `Light2D` with `castShadows` that reaches a solid tile or a caster and is among the lights a frame shades gets a row:
the old limit of 32 shadowed lights is gone, and the limit is now the 256 lights of a frame (`kMaxLights2D`, see
[PERFORMANCE.md](../PERFORMANCE.md), "2D lights"). The rows are one RGBA8 image of 1024 angles x up to 256 rows
(`stats.lights2dShadowed` counts them), so the atlas needs nothing a GPU lacks. When a frame has more lights in view than 256
the ones ranked last are left out of the frame altogether, and one warning per scene says how many.

A light's row is cached under a key of the light's position and radius, its layers and every occluder in its reach (tile edits and
the outline of each caster). A light that does not move, in a scene whose occluders in its reach do not move, neither recomputes
nor uploads its row, frame after frame (the frame still reads each caster's transform and hashes its outline, which grows with the number of
casters but touches no pixel); a moving caster recomputes only the rows of the lights it reaches. A row is computed on the
CPU, 1024 angles each time its key changes.

## Costs and caps

All caps count work and never time, so a scene gives the same picture on a slow machine as on a fast one.

| What | Cap | Beyond it |
| --- | --- | --- |
| `ShadowCaster2D` read per frame | 2048, in entity order | the others block no light, one warning |
| Segments of one caster | 256 (a contour is simplified to fit; a polygon is cut) | polygon: one warning |
| Casters one light's row reads | 512, in entity order | the others do not block that light, one warning |
| Outlines of one sprite | 16 | the smaller ones block nothing |
| Alpha pixels one contour reads | 512 x 512 | the region is reduced by blocks |
| Shadowed lights of a frame | 256 | the ones ranked last shine through walls, one warning per scene |

A caster is rasterised into the angles of the row it covers, so the cost of a row is the number of (segment, angle) pairs: a
box that fills 10 degrees of a light's view is about 100 texels, however many casters are in the scene, and a caster outside a light's
disc costs the bounding-box test only. Measured in a Debug build (-O1) on one Mac (Apple M5, Metal), 100 boxes and 64 lights of radius 120, a 320 x 180 frame read back
to the CPU, the numbers move by a millisecond from run to run: about 4 ms a frame with `size` 3 and every light moving (the 64
rows computed again each frame), about 2 ms with the same lights still, about 1 ms with the lights still and `size` 0. So a
row costs about 30 microseconds, and the penumbra about 1 ms for 64 lights that cover 240 x 240 pixels each. Two things grow a
row's cost: a light that reaches many large casters, and a sprite with a very detailed contour (use a polygon). A game that moves dozens of
casters through dozens of lights every frame is the case to measure with `factoria call perf.measure` on the target hardware.

The CPU makes the rows on every backend (the same rows the tiles used), so there is no GPU path that needs compute or a
float render target; a GPU ray cast is a possible follow-up for scenes with hundreds of moving casters.

## Teaching degradation and checks

- `render.supports` rows `2dSoftShadows` and `2dShadowCasters` are true wherever the renderer draws (they need nothing a
  backend might lack).
- Warnings, each once per scene or per renderer: a `spriteAlpha` caster without a `Sprite`, a texture whose alpha cannot be read,
  a polygon over 256 points, more than 2048 casters, a light that reaches more than 512 casters, more than 256 lights.
- A caster on a hidden layer (an entity the camera's mask does not draw) casts no shadow in that camera's view, like a tile map.
- Determinism: nothing in the rows depends on time or randomness; the same scene gives the same row on every run.
- `renderStats().lights2dShadowed` is the number of rows a frame made or reused; a light with `castShadows` that reaches
  nothing solid is lit without a row and is not counted.

Related: [Performance budgets](../performance/PERFORMANCE_AREAS.md) ("2D lights"), [the 2D lighting recipe](../ai-guide/AI_GUIDE_RECIPES_PRODUCTION.md).
