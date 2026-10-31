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

