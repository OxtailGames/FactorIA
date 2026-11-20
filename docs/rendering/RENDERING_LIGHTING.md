Part of [RENDERING.md](../RENDERING.md): the lighting of 3D scenes, what a Light, the scene settings and a MeshRenderer say about it, and
what the renderer draws of it today.

# Rendering: lighting (M73)

M73 brings the lighting of a leading engine to FactorIA in six steps: many lights at once with area lights, cookies and IES profiles
(M73.1); shadows for every kind of light, in cascades for the sun (M73.2); an HDR environment, reflection probes and a physical sky
(M73.3); baked lightmaps and light probes (M73.4); volumetric fog, decals, subsurface scattering and realtime global illumination
(M73.5); and the material layers clear coat, sheen, anisotropy, specular / IOR and transmission (M73.6; the first four are drawn).

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
| `clearcoat`, `clearcoatRoughness` | 0..1 | 0, 0.03 | drawn (M73.6a), see "The material layers" |
| `sheenColor`, `sheenRoughness` | colour; 0..1 | black, 0.5 | drawn (M73.6a) |
| `anisotropy`, `anisotropyRotation` | -1..1; degrees | 0, 0 | drawn (M73.6a) |
| `specular`, `ior` | 0..1; 1..3 | 1, 1.5 | drawn (M73.6a) |
| `transmission`, `thickness` | 0..1; metres | 0, 0 | M73.6 |
| `attenuationColor`, `attenuationDistance` | colour; metres | white, 0 | M73.6 |
| `subsurface` | 0..1 | 0 | M73.5 |

A value outside its range, or a name that is not one of the listed words, is refused where it is written (the scene file on load, the commands that set a component field, a script property write) with the field, the allowed range or words and a "did you mean" for a misspelt word.

## The material layers (M73.6a)

The standard mesh shading (every MeshRenderer without a custom material, and a custom material's `Surface`) has four layers on top of
the base metal / roughness model. They are drawn on every backend (OpenGL, GLES3 and WebGL2, D3D11, Metal) with the same GGX model as the
base; a material that leaves them at their defaults draws exactly the picture it drew before (the golden images did not change), and
costs at most one uniform branch.

| Layer | Fields | What it does |
|---|---|---|
| Clear coat | `clearcoat`, `clearcoatRoughness` | A second, glossy dielectric layer over the surface (car paint, lacquer, wet clay): its own GGX highlight on the geometric normal (a normal map does not bend it), and the base underneath is dimmed by what the coat reflects (Fresnel of F0 0.04), so the paint is a little darker where the coat shines. |
| Sheen | `sheenColor`, `sheenRoughness` | A soft glow at grazing angles (velvet, satin, cloth): a Charlie distribution lobe tinted by `sheenColor`; the base underneath is scaled by `1 - max(sheenColor) * E`, the energy the sheen takes, so the surface never gains light. Black (the default) is off. |
| Anisotropy | `anisotropy`, `anisotropyRotation` | The highlight stretches along the tangent (brushed metal, hair, vinyl records): a negative value stretches it across. `anisotropyRotation` turns the direction, in degrees, around the normal. Needs tangents (a model without a TANGENT attribute gets them generated from its UVs). |
| Specular | `specular`, `ior` | The reflectance at normal incidence of a non-metal, `F0 = ((ior - 1) / (ior + 1))^2 * specular`: the default ior 1.5 and specular 1 give 0.04 exactly, so nothing changes; water is 1.33 (0.02), diamond 2.4 (0.17), `specular` 0 switches the dielectric reflection off. A metal's reflectance is its colour; the specular does not change it. |

Image-based light (the sky or the `environmentMap`) gets the layers too, by approximation: the coat reflects the environment along the
geometric normal with F0 0.04 (the pre-filtered mip of `clearcoatRoughness`); the sheen adds the environment along the normal at
`sheenRoughness`, tinted by `sheenColor` and by a table of the sheen's directional albedo (a 7 x 9 table, worst error 0.06, mean 0.003;
`tools/shaders/sheen_albedo.py` makes it); the anisotropic reflection bends the reflected direction toward the stretch (the bent normal
of Filament). They are not the path-traced truth; they are right in the sense that matters, a layer reflects its sky and never adds energy.

### Layers from a glTF model

A model's `KHR_materials_clearcoat`, `KHR_materials_sheen`, `KHR_materials_anisotropy`, `KHR_materials_specular` and `KHR_materials_ior`
become the layers of its parts: the factors always (`clearcoatFactor`, `clearcoatRoughnessFactor`, `sheenColorFactor`,
`sheenRoughnessFactor`, `anisotropyStrength`, `anisotropyRotation`, `specularFactor`, `specularColorFactor`, `ior`), clamped to the ranges of
the table (a value outside is clamped and named). A `MeshRenderer` field that is not at its default replaces the model's value of
that layer for the whole renderer, field by field (`materialColors` and the rest work as before); the packed textures below still
modulate it.

The mesh shader has no texture unit free for more maps, so the textures of the extensions are packed at import into the free channels of
the maps the part already binds. The packing is deterministic (bilinear resampling in fixed point, to the largest size among the sources of a map, at most
4096 x 4096), and a channel with no texture is 255 so the factor alone decides:

| Map the part binds | R | G | B | A |
|---|---|---|---|---|
| occlusion | the occlusion (255 if none) | `clearcoatTexture` R | `clearcoatRoughnessTexture` G | `sheenRoughnessTexture` A |
| metallic-roughness | `anisotropyTexture` B (strength) | roughness (`metallicRoughnessTexture` G) | metallic (B) | `specularTexture` A |

What does not fit is never dropped silently: the import writes a warning with the file, the material name and what is used instead.
Not packed: `clearcoatNormalTexture` (the coat follows the geometric normal), `sheenColorTexture` (`sheenColorFactor` is used),
`specularColorTexture` (`specularColorFactor` is used) and the direction (red and green) of `anisotropyTexture` (the direction is the
tangent turned by `anisotropyRotation`); a texture file that cannot be read (`its factor alone is used`), and a set whose packed size would pass
4096 x 4096. An editable mesh (`mesh.*` commands, a model converted to a mesh) keeps only the factors: its textures are not carried.

## Asking what the renderer draws: render.supports

`render.supports` (C++ `Renderer::supports(name)`) answers for each lighting feature below with `false` and the status `planned (M73)`
until its step lands; then it follows the GPU. A game that wants a feature checks it first and falls back, so it never relies on
what is not drawn.

`clusteredLights`, `areaLights`, `lightCookies`, `iesProfiles` (M73.1); `cascadedShadows`, `pointShadows`, `spotShadows`,
`contactShadows` (M73.2); `environmentMap`, `reflectionProbes`, `physicalSky` (M73.3); `lightmaps`, `lightProbes` (M73.4);
`volumetricFog`, `decals`, `subsurface`, `realtimeGI` (M73.5); `clearCoat`, `sheen`, `anisotropy` (M73.6a, drawn: they follow the
backend, which every one supports) and `transmission` (M73.6b).

A new capability row, `float32Targets`, says whether the GPU can render to and sample R32F and RGBA32F images: the shadow atlas of
M73.2 is one. It is `true` where the GPU reports both formats as renderable and sampleable.
