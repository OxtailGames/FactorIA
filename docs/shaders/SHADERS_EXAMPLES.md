Part of [SHADERS.md](../SHADERS.md): nine worked examples of mesh materials (a pulsing gem, dissolve, water, wind, rim light, toon, a ramp, hatching, displacement). The material file, the snippet and the engine values are on that page.

# Worked examples

Each example is a material file plus a snippet; the test suite compiles them all, so they are known to work. Put the
snippet's path in the material's `shader` and the material's path on an entity as shown on [SHADERS.md](../SHADERS.md).

## 1. Pulsing emission (`fa_time`)

File `materials/pulse.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "A glow that breathes: emission scaled by a sine of the game time.",
  "shader": "shaders/pulse.surface.glsl",
  "params": {
    "glow": { "type": "color", "default": [1.0, 0.45, 0.1, 1.0], "doc": "Color of the glow." },
    "strength": { "type": "float", "default": 1.5, "min": 0.0, "max": 8.0, "doc": "Peak emission brightness." },
    "speed": { "type": "float", "default": 0.5, "min": 0.0, "max": 5.0, "doc": "Pulses per second." }
  }
}
```

File `shaders/pulse.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {
    float wave = 0.5 + 0.5 * sin(fa_time.x * speed * 6.2831853);
    s.emission += glow.rgb * (strength * wave);
}
```

## 2. Dissolve with `"clip"` (procedural noise)

`"clip"` discards fragments whose `s.alpha` is below `alphaCutoff` (0.5), in the shadow too, so the holes cast no
shadow. Animate `amount` from a script from 0 (whole) to 1 (gone). With a noise texture instead of the hash, declare it in
`textures` (name it `mask`, not `noise`: sokol-shdc cannot compile a texture called `noise`, and the material is refused) and
use `texture(sampler2D(mask, mask_smp), i.uv).r` as `n`.

File `materials/dissolve.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Burns away along a noise pattern; the edge of the hole glows.",
  "shader": "shaders/dissolve.surface.glsl",
  "alphaMode": "clip",
  "doubleSided": true,
  "params": {
    "amount": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "How much is gone: 0 whole, 1 nothing left." },
    "edgeColor": { "type": "color", "default": [1.0, 0.5, 0.1, 1.0], "doc": "Color of the glowing edge." },
    "edgeWidth": { "type": "float", "default": 0.08, "min": 0.0, "max": 0.5, "doc": "Width of the glowing edge, in noise units (0..1)." },
    "scale": { "type": "float", "default": 6.0, "min": 1.0, "max": 40.0, "doc": "Size of the noise: noise cells per UV unit." }
  }
}
```

File `shaders/dissolve.surface.glsl`:

```glsl
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float value_noise(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(c), hash(c + vec2(1.0, 0.0)), f.x),
               mix(hash(c + vec2(0.0, 1.0)), hash(c + vec2(1.0, 1.0)), f.x), f.y);
}

void surface(in SurfaceInput i, inout Surface s) {
    float n = value_noise(i.uv * scale);
    s.alpha = n < amount ? 0.0 : 1.0;                       // below alphaCutoff (0.5): discarded
    float edge = 1.0 - smoothstep(0.0, max(edgeWidth, 0.001), n - amount);
    s.emission += edgeColor.rgb * edge * 3.0;
}
```

## 3. Scrolling water (UV scroll)

A tileable tangent-space normal map scrolls with `fa_time`. Supply your own image at the default path (or override
`ripples` per entity). Use a `plane` mesh.

File `materials/water.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Translucent water: a normal map scrolls over a tinted, glossy surface.",
  "shader": "shaders/water.surface.glsl",
  "alphaMode": "blend",
  "params": {
    "tint": { "type": "color", "default": [0.05, 0.3, 0.45, 0.8], "doc": "Water color; alpha is its opacity." },
    "flow": { "type": "vec2", "default": [0.04, 0.02], "doc": "Scroll speed of the ripples, UV per second." },
    "tiling": { "type": "float", "default": 4.0, "min": 0.1, "max": 50.0, "doc": "How many times the ripples repeat across the mesh." }
  },
  "textures": {
    "ripples": { "default": "textures/water_ripples.png", "sampler": "linearRepeat", "doc": "Tileable tangent-space normal map (rgb)." }
  }
}
```

File `shaders/water.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {
    vec2 uv = i.uv * tiling + flow * fa_time.x;
    vec3 n = texture(sampler2D(ripples, ripples_smp), uv).xyz * 2.0 - 1.0;
    s.normal = fa_tangent_normal(i, n);
    s.albedo = tint.rgb;
    s.alpha = tint.a;
    s.metallic = 0.0;
    s.roughness = 0.08;
}
```

## 4. Wind on grass (`vertex()`)

`vertex()` moves the vertices in world space; the tip sways, the root stays. For a `quad` mesh (1 x 1 in XY, centered) the
root is at `object_pos.y = -0.5`, hence the `+ 0.5`. Scale the entity to a blade (`[0.3, 1, 1]`). The shadow follows the
sway. This `vertex()` reads params and `fa_time`; example 9 reads a texture.

File `materials/grass.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Grass blades that sway in the wind: the tips move, the roots stay.",
  "shader": "shaders/grass.surface.glsl",
  "doubleSided": true,
  "params": {
    "root": { "type": "color", "default": [0.08, 0.25, 0.05, 1.0], "doc": "Color at the root of the blade." },
    "tip": { "type": "color", "default": [0.45, 0.75, 0.2, 1.0], "doc": "Color at the tip of the blade." },
    "sway": { "type": "float", "default": 0.25, "min": 0.0, "max": 2.0, "doc": "How far the tips move, in meters." },
    "windSpeed": { "type": "float", "default": 1.6, "min": 0.0, "max": 10.0, "doc": "Radians per second of the sway." }
  }
}
```

File `shaders/grass.surface.glsl`:

```glsl
void vertex(inout VertexData v) {
    float h = clamp(v.object_pos.y + 0.5, 0.0, 1.0);              // 0 at the root of the blade, 1 at its tip
    float phase = v.world_pos.x * 0.7 + v.world_pos.z * 0.5;      // neighbours sway out of step
    v.world_pos.x += sin(fa_time.x * windSpeed + phase) * sway * h * h;
}

void surface(in SurfaceInput i, inout Surface s) {
    s.albedo = mix(root.rgb, tip.rgb, 1.0 - i.uv.y);
}
```

(On a `quad`, `uv.y` is 1 at the bottom edge and 0 at the top, hence `1.0 - i.uv.y`; `surface()` has no `object_pos`, so
with another mesh derive the blade height from its UVs.)

## 5. Rim light

Brightens the silhouette: the more a surface faces away from the camera, the more it glows.

File `materials/rim.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Adds a colored glow on the edges of the mesh, seen from the camera.",
  "shader": "shaders/rim.surface.glsl",
  "params": {
    "rimColor": { "type": "color", "default": [0.3, 0.7, 1.0, 1.0], "doc": "Color of the edge glow." },
    "rimPower": { "type": "float", "default": 3.0, "min": 0.5, "max": 8.0, "doc": "Sharpness: higher keeps the glow thinner." },
    "rimStrength": { "type": "float", "default": 1.2, "min": 0.0, "max": 5.0, "doc": "Brightness of the glow." }
  }
}
```

File `shaders/rim.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {
    float facing = clamp(dot(normalize(s.normal), i.view_dir), 0.0, 1.0);
    float rim = pow(1.0 - facing, rimPower);
    s.emission += rimColor.rgb * (rim * rimStrength);
}
```

## 6. Two-band toon (`"custom"` lighting)

`light()` is called once for each light; the engine has already put the light's color, attenuation and shadow into
`l.color`. Here a surface facing the light more than `threshold` gets the full light and the rest gets `shade` of it, so
the sphere shows exactly two tones, and a shadow falls as a flat dark band.

File `materials/toon.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Cel shading with two bands: lit and shaded, with a hard edge between them.",
  "shader": "shaders/toon.surface.glsl",
  "lighting": "custom",
  "params": {
    "threshold": { "type": "float", "default": 0.5, "min": 0.0, "max": 1.0, "doc": "Dot product of normal and light direction above which the surface is lit." },
    "shade": { "type": "float", "default": 0.35, "min": 0.0, "max": 1.0, "doc": "Brightness of the shaded band, as a fraction of the lit one." }
  }
}
```

File `shaders/toon.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    float band = dot(s.normal, l.direction) > threshold ? 1.0 : shade;
    return s.albedo * l.color * band;
}
```

## 7. Cel bands from a ramp texture (`ambient()`)

The band is a texel of a ramp image: paint the ramp (one row, left = facing away, right = facing the light, `nearest`
sampler for hard steps) and the lighting follows it. `ambient()` keeps the shaded side from going black. Read the ramp
with `textureLod`, because `light()` runs in a loop.

File `materials/ramp.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Cel shading whose bands come from a ramp image.",
  "shader": "shaders/ramp.surface.glsl",
  "lighting": "custom",
  "params": {
    "ambientAmount": { "type": "float", "default": 0.6, "min": 0.0, "max": 2.0, "doc": "How much of the scene's ambient light the surface keeps." }
  },
  "textures": {
    "ramp": { "default": "textures/ramp.png", "sampler": "nearest", "doc": "Light ramp: the red channel is the brightness, left = facing away from the light, right = facing it." }
  }
}
```

File `shaders/ramp.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    float ndl = dot(s.normal, l.direction) * 0.5 + 0.5;     // -1..1 -> 0..1
    float band = textureLod(sampler2D(ramp, ramp_smp), vec2(ndl, 0.5), 0.0).r;
    return s.albedo * l.color * band;
}

vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) {
    return ambientColor * s.albedo * (s.occlusion * ambientAmount);
}
```

## 8. Screen-space hatching

Strokes drawn on the picture, not on the mesh: the less a surface faces the light, the more strokes cross it (none
when it is lit, one set in the half shade, two crossing sets in the full shade). The strokes are 45 degrees in both directions, so a platform that puts the origin of `gl_FragCoord` at
the other corner draws the same picture mirrored.

File `materials/hatch.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Ink hatching: one set of strokes in the half shade, a crossing set in the full shade.",
  "shader": "shaders/hatch.surface.glsl",
  "lighting": "custom",
  "params": {
    "spacing": { "type": "float", "default": 8.0, "min": 2.0, "max": 40.0, "doc": "Distance between strokes, in pixels of the picture." }
  }
}
```

File `shaders/hatch.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    float ndl = clamp(dot(s.normal, l.direction), 0.0, 1.0);
    vec2 p = gl_FragCoord.xy / spacing;
    float paper = 1.0;
    if (ndl < 0.6) paper = min(paper, step(0.3, fract(p.x + p.y)));    // first set of strokes
    if (ndl < 0.3) paper = min(paper, step(0.3, fract(p.x - p.y)));    // crossing set
    return s.albedo * l.color * paper;
}
```

## 9. Height map displacement (a texture in `vertex()`)

A grayscale image lifts a mesh into relief. `vertex()` and `surface()` read the same texture; the shadow follows the
displaced shape. The mesh needs enough vertices to show the relief: a grid made with `mesh.create()` or an imported
model works, the built-in `plane` has only four vertices and just lifts its corners.

File `materials/relief.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Displaces the vertices upward by a height map and darkens the low ground.",
  "shader": "shaders/relief.surface.glsl",
  "params": {
    "height": { "type": "float", "default": 1.0, "min": 0.0, "max": 10.0, "doc": "Meters a white texel lifts a vertex." }
  },
  "textures": {
    "heightMap": { "default": "textures/height.png", "sampler": "linearRepeat", "doc": "Height map: the red channel, 0 = ground level, 1 = full height." }
  }
}
```

File `shaders/relief.surface.glsl`:

```glsl
void vertex(inout VertexData v) {
    float h = texture(sampler2D(heightMap, heightMap_smp), v.uv).r;      // always mip 0 in vertex()
    v.world_pos.y += h * height;
}

void surface(in SurfaceInput i, inout Surface s) {
    float h = texture(sampler2D(heightMap, heightMap_smp), i.uv).r;
    s.albedo *= mix(0.5, 1.0, h);
}
```

