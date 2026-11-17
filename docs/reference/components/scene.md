[Back to the index](../README.md)

# Components: Scene

## SceneSettings

Scene-wide settings stored under "settings" in the scene file: lighting, fog, gravity and background music.

| Field | Type | Default | Description |
|---|---|---|---|
| `ambientLight` | color | `[0.25,0.25,0.3,1.0]` | Base light added to all lit 3D surfaces so shadows are not pitch black. It is also the base light of lit 2D visuals (Sprite.lit, Tilemap.lit): a lit sprite shows its texture multiplied by this colour plus the Light2D lights. Raise it to [1, 1, 1] and the lit sprites look unlit. |
| `gravity2D` | vec2 | `[0.0,-980.0]` | 2D gravity [x, y] in world units/s^2 (default 980 pixels/s^2 downwards). |
| `gravity3D` | vec3 | `[0.0,-9.81,0.0]` | 3D gravity [x, y, z] in m/s^2 (default 9.81 downwards). |
| `fogColor` | color | `[0.5,0.6,0.7,1.0]` | Color distant 3D objects fade to. |
| `fogDensity` | float | `0.0` | Fog thickness; 0 disables fog. Range 0.0..10.0. |
| `skyColor` | color | `[0.45,0.62,0.85,1.0]` | Top color of the 3D background gradient (used when a perspective camera clears). |
| `horizonColor` | color | `[0.8,0.85,0.9,1.0]` | Bottom color of the 3D background gradient. |
| `music` | asset (audio) | `""` | Looping background music asset path. Empty = none. Loading a scene stops every sound and the music, then starts this track again, even when the previous scene had the same one; music a script started with audio.music(path, {persist: true}) keeps playing through the load, and is not restarted when this is the same track. |
| `musicVolume` | float | `0.6` | Volume of the background music, 0..1. Range 0.0..1.0. |
| `lightScale` | float | `1.0` | Size of the Light2D light buffer as a fraction of the picture, 0.25 .. 1 (default 1: one light pixel per picture pixel). Lower values make lights cost less fill rate and look softer (the light is smoothed up to the picture); use 0.5 on mobile or the web when many lights are on screen. Only matters when a scene has lit visuals and Light2D lights. Range 0.25..1.0. (since 0.3.0) |
| `colorSpace` | enum: gamma \| linear | `"gamma"` | How lighting, blending and the post effects are computed. gamma (default, what every project made before M71 uses, so old projects keep their exact look): on the sRGB-encoded values, with 8-bit targets. linear: in linear light with float render targets (RGBA16F, or RGBA8 with dithering where the GPU cannot), textures marked as sRGB decoded when read and the result encoded for the display: lights add up and fade as they do in the world, and values above 1 survive to the bloom and the tonemap (PostProcess). Costs a bigger render target (twice the memory of RGBA8) and looks different: colours picked by eye in gamma space need a second look, so switch it on deliberately. render.supports {"feature": "linearColor"} says whether this build and GPU can. M71 is in progress: until its linear pipeline lands the value is stored and the picture stays in gamma. (not released yet, on main after 0.30.1) |
| `hdrOutput` | enum: off \| auto | `"off"` | off (default): the picture is shown in the standard range. auto: use a high dynamic range display where the platform allows it (Windows HDR10 or scRGB, macOS EDR); on any other display it is the standard range, with no error. It needs colorSpace linear to show anything above white. render.supports {"feature": "hdrOutput"} says whether this backend can; it is false until M71 draws to HDR displays. (not released yet, on main after 0.30.1) |
| `paperWhiteNits` | float | `200.0` | Only used with hdrOutput auto on an HDR display: the brightness of white (1.0) in nits (cd/m2), 80..1000. 200 is comfortable indoors, 400 and more suits a bright room; the display shows brighter highlights above it. Range 80.0..1000.0. (not released yet, on main after 0.30.1) |

