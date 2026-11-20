Part of [RENDERING.md](../RENDERING.md): the lighting of 3D scenes, what a Light, the scene settings and a MeshRenderer say about it, and
what the renderer draws of it today.

# Rendering: lighting (M73)

M73 brings the lighting of a leading engine to FactorIA in six steps: many lights at once with area lights, cookies and IES profiles
(M73.1); shadows for every kind of light, in cascades for the sun (M73.2); an HDR environment, reflection probes and a physical sky
(M73.3); baked lightmaps and light probes (M73.4); volumetric fog, decals, subsurface scattering and realtime global illumination
(M73.5); and the material layers clear coat, sheen, anisotropy and transmission (M73.6).

**What is there today (M73-P0): the fields, and nothing that draws them.** Every field below is reflected, validated, saved in the scene
and read back, and shows up in `docs.components` and in the typings, so a scene, a prefab or a tool can already set it. The renderer
does not read any of them yet: a scene with every field set looks exactly as it does without them, except that a Light of
`type: "area"` shines like a point light of the same `range` until M73.1. The doc string of each field says which step brings it.
The defaults are what the engine did before, so a scene made before M73 loads, looks and saves as it did (a default is never written
to the file).

## Light

| Field | Values | Default | Brought by |
|---|---|---|---|
| `type` | `directional`, `point`, `spot`, `area` | `directional` | `area`: M73.1 (a point light until then) |
| `innerAngle` | 0..89 degrees | 0 | M73.1: a spot's full-strength cone; 0 = the cone fades as it does today |
| `shape`, `size` | `rectangle`, `disc`, `tube`; metres | `rectangle`, [1, 1] | M73.1, area lights only |
| `cookie` | a texture | none | M73.1 |
| `ies` | an `.ies` file | none | M73.1 |
| `castShadows` | bool | false | directional lights only today; point and spot lights: M73.2 |
| `shadowResolution` | 0..4096 | 0 (the engine picks) | M73.2 |
| `shadowBias`, `shadowNormalBias` | 0..1 | 0 (the engine's own) | M73.2 |
| `shadowFilter`, `shadowSoftness` | `pcf`, `hard`, `pcss`; 0..10 | `pcf`, 1 | M73.2 |
| `shadowDistance` | metres, 0..100000 | 0 (the scene's) | M73.2 |
| `mode` | `realtime`, `baked`, `mixed` | `realtime` | M73.4 |
| `volumetric` | 0..10 | 0 | M73.5 |

## Scene settings

| Field | Values | Default | Brought by |
|---|---|---|---|
| `shadowCascades` | 1..4 | 1 | M73.2 |
| `shadowCascadeSplit`, `shadowCascadeBlend` | 0..1; 0..0.5 | 0.5, 0.1 | M73.2 |
| `shadowDistance` | metres, 0..100000 | 0 (the engine's own fit) | M73.2 |
| `shadowAtlasSize` | 512..8192 texels per side | 4096 | M73.2 |
| `contactShadows` | bool | false | M73.2 (needs a GPU that can sample the depth) |
| `environmentMap`, `environmentIntensity`, `environmentRotation` | an HDR image; 0..100; degrees | none, 1, 0 | M73.3 |
| `skyModel` | `gradient`, `physical` | `gradient` | M73.3 |

## MeshRenderer

| Field | Values | Default | Brought by |
|---|---|---|---|
| `lightmapScale` | 0..100 | 1 | M73.4 |
| `contributeGI`, `receiveGI` | bool | true, true | M73.4 (bake), M73.5 (realtime GI) |
| `clearcoat`, `clearcoatRoughness` | 0..1 | 0, 0.03 | M73.6 |
| `sheenColor`, `sheenRoughness` | colour; 0..1 | black, 0.5 | M73.6 |
| `anisotropy`, `anisotropyRotation` | -1..1; degrees | 0, 0 | M73.6 |
| `specular`, `ior` | 0..1; 1..3 | 1, 1.5 | M73.6 |
| `transmission`, `thickness` | 0..1; metres | 0, 0 | M73.6 |
| `attenuationColor`, `attenuationDistance` | colour; metres | white, 0 | M73.6 |
| `subsurface` | 0..1 | 0 | M73.5 |

A value outside its range, or a name that is not one of the listed words, is refused where it is written (the scene file on load, the commands that set a component field, a script property write) with the field, the allowed range or words and a "did you mean" for a misspelt word.

## Asking what the renderer draws: render.supports

`render.supports` (C++ `Renderer::supports(name)`) answers for each lighting feature below with `false` and the status `planned (M73)`
until its step lands; then it follows the GPU. A game that wants a feature checks it first and falls back, so it never relies on
what is not drawn.

`clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles` (M73.1); `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows` (M73.2); `environmentMap`, `reflectionProbes`, `physicalSky` (M73.3); `lightmaps`, `lightProbes` (M73.4);
`volumetricFog`, `decals`, `subsurface`, `realtimeGI` (M73.5); `clearCoat`, `sheen`, `anisotropy`, `transmission` (M73.6).

A new capability row, `float32Targets`, says whether the GPU can render to and sample R32F and RGBA32F images: the shadow atlas of
M73.2 is one. It is `true` where the GPU reports both formats as renderable and sampleable.
