#include "render_features.h"

#include <cstring>
#include <string_view>

#include "fa/core/log.h"
#include "fa/scene/postprocess.h"
#include "sokol_gfx.h"

namespace fa::render {

namespace {

constexpr unsigned bit(FeatureBackend b) { return 1u << unsigned(b); }
constexpr unsigned kEveryGpu = bit(FeatureBackend::Gl) | bit(FeatureBackend::Gles3) | bit(FeatureBackend::WebGl2) |
                               bit(FeatureBackend::D3d11) | bit(FeatureBackend::Metal);

struct EffectRow {
    std::string_view name;  // the effect's name in kPostEffectOrder: a row out of order fails the static_assert below
    const char* needs;
    const char* doc;
};

// One row per effect, in the order of kPostEffectOrder (checked below).
constexpr EffectRow kEffectRows[kPostEffectCount] = {
    {"ssao", "half+depth",
     "Screen-space ambient occlusion (GTAO) from the depth buffer: creases and contacts of 3D models darken (needs the "
     "depth prepass; drawn before the bloom, per camera)."},
    {"ssr", "half+depth",
     "Screen-space reflections: opaque 3D surfaces reflect what the camera shows (ray march in the depth prepass; "
     "the reflectivity is a fresnel term, there is no roughness image)."},
    {"fog", "depth", "Distance and height fog drawn from the depth of the opaque 3D meshes (the sky is not fogged)."},
    {"sunShafts", "half+depth",
     "Sun shafts: the bright sky scattered toward the sun (perspective cameras, half resolution)."},
    {"exposure", "", "Exposure, manual or automatic with an adaptation speed."},
    {"depthOfField", "half+depth", "Depth of field with near and far blur, bokeh and autofocus."},
    {"motionBlur", "depth", "Camera motion blur, from the depth buffer."},
    {"radialBlur", "",
     "Radial blur from a point of the picture (final pass; camera.radialBlur starts a pulse of it, drawn the same "
     "way)."},
    {"lensDistortion", "",
     "Barrel and pincushion lens distortion (drawn in the final pass, after the bloom; outside the picture is black)."},
    {"chromaticAberration", "", "Chromatic aberration: colour fringes toward the edges (drawn in the final pass)."},
    {"bloom", "", "Bloom with a soft knee and a lens dirt texture."},
    {"tonemap", "", "Tonemap: none, neutral, ACES, AgX or Reinhard."},
    {"colorGrading", "",
     "Colour grading on the display picture: white balance, lift/gamma/gain, contrast, saturation, hue shift and a "
     ".cube LUT."},
    {"vignette", "", "Vignette: the edges of the picture darken toward a colour."},
    {"sharpen", "", "Sharpening: contrast-adaptive, on the finished picture."},
    {"outline", "depth",
     "Outline (final pass): depth and normal edges of the opaque meshes (3D, one full-screen camera; needs "
     "the depth prepass) or "
     "the border outside 2D sprites (sprite mode: draws the 2D world once more into a coverage image; one "
     "full-screen camera)."},
    {"pixelate", "", "Pixelation (final pass): the picture drawn in big square pixels, block size in design pixels."},
    {"posterize", "", "Posterization (final pass): the display colours reduced to a few levels per channel."},
    {"filmGrain", "", "Film grain: noise over the picture, from the frame number (the same on every run)."},
    {"colorFilter", "", "The accessibility colour filter, the last pass of the frame."},
};
constexpr bool effect_rows_in_order() {
    for (int i = 0; i < kPostEffectCount; ++i)
        if (kEffectRows[i].name != kPostEffectOrder[std::size_t(i)]) return false;
    return true;
}
static_assert(effect_rows_in_order(),
              "kEffectRows: one row per effect, in the order (and with the name) of kPostEffectOrder");

// The effects the renderer draws (postprocess.cpp, bloom.cpp, post.glsl, renderer_ssao/ssr/fog/dof): every effect of kPostEffectOrder
// today. An effect added to the order without a drawing pass is left out here and is listed as planned until it is drawn.
constexpr bool effect_drawn(PostEffect e) {
    return e == PostEffect::Ssao || e == PostEffect::Exposure || e == PostEffect::Bloom || e == PostEffect::Tonemap ||
           e == PostEffect::ColorFilter || e == PostEffect::LensDistortion || e == PostEffect::ChromaticAberration ||
           e == PostEffect::ColorGrading || e == PostEffect::Vignette || e == PostEffect::Sharpen ||
           e == PostEffect::RadialBlur || e == PostEffect::Outline || e == PostEffect::Pixelate ||
           e == PostEffect::Posterize || e == PostEffect::FilmGrain || e == PostEffect::DepthOfField ||
           e == PostEffect::MotionBlur || e == PostEffect::Ssr || e == PostEffect::Fog || e == PostEffect::SunShafts;
}

}  // namespace

std::uint32_t post_drawn_mask() {
    std::uint32_t m = 0;
    for (int i = 0; i < kPostEffectCount; ++i)
        if (effect_drawn(PostEffect(i))) m |= 1u << i;
    return m;
}

namespace {

std::vector<FeatureDef> build_table() {
    std::vector<FeatureDef> t;
    // The capabilities: facts about the GPU, answered from what it reports.
    t.push_back(
        {"floatTargets", FeatureKind::Capability, kEveryGpu, "half", nullptr,
         "Render targets of 16-bit float colour (RGBA16F) that blend and filter: the frame keeps colours above white. "
         "Without them the frame is RGBA8 and clips at white."});
    t.push_back(
        {"r11g11b10", FeatureKind::Capability, kEveryGpu, "r11g11b10", nullptr,
         "The packed float render target R11G11B10 (half the memory of RGBA16F, no alpha), for HDR frames on phones."});
    t.push_back(
        {"sampledDepth", FeatureKind::Capability, kEveryGpu, "depth", nullptr,
         "The scene's depth and normals as images that a later pass can sample (the depth and normal prepass, drawn "
         "only "
         "for a frame with an effect that reads them): what ambient occlusion, depth of field, fog, reflections and "
         "motion blur read."});
    t.push_back({"computeShaders", FeatureKind::Capability,
                 bit(FeatureBackend::Gl) | bit(FeatureBackend::D3d11) | bit(FeatureBackend::Metal), "compute", nullptr,
                 "Compute shaders and storage buffers (D3D11, Metal, OpenGL 4.3; never GLES3 or WebGL2)."});
    t.push_back(
        {"float32Targets", FeatureKind::Capability, kEveryGpu, "float32", nullptr,
         "Render targets of 32-bit float (R32F and RGBA32F) that can be sampled: what the shadow atlas of the "
         "lighting of M73 is drawn into (one depth value per texel): without them there is no cascaded shadow."});
    // The engine features built on them.
    t.push_back(
        {"linearColor", FeatureKind::Engine, kEveryGpu, "", nullptr,
         "Lighting and blending in linear light (SceneSettings.colorSpace linear). The frame is RGBA16F where the GPU "
         "has it, else R11G11B10 (no alpha), else 8 bits that hold linear light (SRGB8A8), else plain RGBA8 with "
         "banding in the darks, so every GPU can."});
    t.push_back(
        {"hdrOutput", FeatureKind::Engine, bit(FeatureBackend::D3d11) | bit(FeatureBackend::Metal), "", nullptr,
         "Showing the picture on a high dynamic range display (SceneSettings.hdrOutput auto): EDR on macOS and iOS, "
         "scRGB or HDR10 on Windows; the display and the OS must allow it. Values above paper white come from the "
         "tonemap of a PostProcess. render.output says what the window shows."});
    t.push_back(
        {"postMaterials", FeatureKind::Engine, kEveryGpu, "", nullptr,
         "Custom post-process passes: kind \"post\" materials drawn as full-screen passes of the stack, before the "
         "tonemap and between the display effects after it (PostProcess.customPasses, docs/shaders/SHADERS_POST.md). "
         "The feature needs nothing of the GPU (it is on wherever the engine draws); only a pass whose material reads "
         "the depth or the normals (fa_depth, fa_normal) needs the sampledDepth feature, and that pass alone is "
         "skipped without it."});
    t.push_back(
        {"lightmaps", FeatureKind::Engine, kEveryGpu, "", nullptr,
         "Baked lightmaps (M73.4a): the bake's light of a scene (SceneSettings.lightmaps, the lightmap.bake command) "
         "is read from "
         "the lightmap UV of each entity with MeshRenderer.receiveGI and replaces the ambient light on its diffuse "
         "surface; "
         "lights with mode baked are left out of those entities. The feature needs nothing of the GPU. A custom "
         "material "
         "gets the lightmap only when it declares \"uv1\" in vertexAttributes "
         "(docs/rendering/RENDERING_LIGHTMAPS.md)."});
    t.push_back(
        {"physicalSky", FeatureKind::Engine, kEveryGpu, "half", nullptr,
         "A physically based sky (SceneSettings.skyModel \"physical\"): a sun with a disc, an atmosphere (Rayleigh, "
         "Mie, ozone) and procedural clouds, drawn as the background and baked into the image-based lighting, so "
         "the reflections and the ambient light follow the sun. It needs RGBA16F render targets that filter (its "
         "look-up tables); without them the gradient sky is drawn."});
    t.push_back(
        {"environmentMap", FeatureKind::Engine, kEveryGpu, "half", nullptr,
         "An HDR environment image (SceneSettings.environmentMap, an equirectangular .hdr file) as the background and "
         "the "
         "image-based lighting of the scene, with intensity and rotation (docs/rendering/RENDERING_LIGHTING.md, "
         "\"The environment map\"). It needs RGBA16F render targets that filter (the environment bake) and RGBA16F "
         "textures that filter; without them the sky material, the physical sky or the gradient is used."});
    // The material layers of M73.6: drawn by the standard mesh shading on every backend (docs/rendering/RENDERING_LIGHTING.md).
    t.push_back({"clearCoat", FeatureKind::Engine, kEveryGpu, "", nullptr,
                 "The clear coat layer of a material: car paint, lacquer (MeshRenderer.clearcoat, glTF "
                 "KHR_materials_clearcoat): a second specular lobe over the surface that also dims what is under it."});
    t.push_back({"sheen", FeatureKind::Engine, kEveryGpu, "", nullptr,
                 "The sheen layer of a material: cloth and velvet (MeshRenderer.sheenColor, glTF "
                 "KHR_materials_sheen): a soft lobe at grazing angles on a Charlie distribution."});
    t.push_back({"anisotropy", FeatureKind::Engine, kEveryGpu, "", nullptr,
                 "Anisotropic highlights: brushed metal, hair (MeshRenderer.anisotropy, glTF "
                 "KHR_materials_anisotropy), stretched along the mesh's tangent."});
    t.push_back({"transmission", FeatureKind::Engine, kEveryGpu, "", nullptr,
                 "Transmission and volume: glass and liquids that refract what is behind them "
                 "(MeshRenderer.transmission, thickness, "
                 "attenuationColor, attenuationDistance, glTF KHR_materials_transmission and KHR_materials_volume). A "
                 "frame with a "
                 "visible transmissive mesh copies the opaque picture (with a chain of blurred halves for rough glass) "
                 "and the mesh "
                 "looks through it; a frame with none copies nothing. When the copy cannot be made (its shader or an "
                 "image fails), "
                 "the mesh is a plain blend that darkens and tints what is behind it, with no refraction "
                 "(docs/rendering/RENDERING_TRANSMISSION.md)."});
    // The lighting of M73 (docs/rendering/RENDERING_LIGHTING.md): every row of the table below answers false with "planned (M73)" until
    // its package lands, then moves up to a row of its own. `needs` is what its pass asks of the GPU once built.
    t.push_back(
        {"clusteredLights", FeatureKind::Engine, kEveryGpu, "", nullptr,
         "Clustered forward lighting: up to 1024 lights in view at once (32 of them directional), each fragment "
         "reading only the lights of its cluster (docs/rendering/RENDERING_LIGHTING.md, \"Many lights\")."});
    // The light atlas of M73.1b (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The light atlas"): one RGBA16F image that filters holds the
    // LTC tables, the cookies and the IES profiles. Without such images the lights are drawn as point and spot lights, without them.
    t.push_back({"areaLights", FeatureKind::Engine, kEveryGpu, "half", nullptr,
                 "Rectangle, disc and tube area lights (Light.type area) with soft highlights, shaded with linearly "
                 "transformed cosines; a rectangle and a disc emit from their front, a tube from all around. Without "
                 "RGBA16F images that filter, an area light is drawn as a point light of the same energy."});
    t.push_back({"lightCookies", FeatureKind::Engine, kEveryGpu, "half", nullptr,
                 "Light cookies (Light.cookie): a texture projected by a spot light (perspective), along a "
                 "directional light (orthographic, tiled over Light.size metres) or all around a point light (an "
                 "equirectangular panorama, baked into a cube of six faces). An area light ignores its cookie."});
    t.push_back({"iesProfiles", FeatureKind::Engine, kEveryGpu, "half", nullptr,
                 "IES profiles (Light.ies, an .ies file of the project): the measured light distribution of a real "
                 "lamp on a point or spot light, normalised to its peak so Light.intensity stays the brightness."});
    t.push_back(
        {"lightProbes", FeatureKind::Engine, kEveryGpu, "", nullptr,
         "Light probes (M73.4d): the LightProbeGroup components baked by lightmap.bake hold spherical-harmonics "
         "lighting that a mesh without a lightmap (a moving object, lightmapScale 0, a skinned mesh) receives "
         "in place of the sky's ambient, interpolated on the CPU at the centre of its bounds (or at "
         "MeshRenderer.probeAnchor); lights with mode baked light those meshes only through the probes. The "
         "feature needs nothing of the GPU (docs/rendering/RENDERING_LIGHT_PROBES.md)."});
    struct Planned {
        const char* name;
        const char* needs;
        const char* doc;
        const char* planned = "M73";  // nullptr once the package that draws it has landed
    };
    static const Planned kLighting[] = {
        {"cascadedShadows", "float32",
         "Cascaded shadow maps for the directional light (1 to 4 cascades fitted to the camera, stable, blended at the "
         "seams, with PCF or PCSS soft edges), drawn into one shadow atlas of 32-bit float (M73.2a).",
         nullptr},
        {"pointShadows", "float32",
         "Shadows of point lights: six face tiles in the shadow atlas, ranked by importance with a budget per frame, "
         "PCF, PCSS or hard, faded out by distance (M73.2b).",
         nullptr},
        {"spotShadows", "float32",
         "Shadows of spot lights: one perspective tile in the shadow atlas, with the same budget and filters "
         "(M73.2b).",
         nullptr},
        {"contactShadows", "depth",
         "Contact shadows: a short screen-space ray toward the light, marched against the depth prepass, adds fine "
         "shadows "
         "where objects touch (Light.contactShadowLength, SceneSettings.contactShadows; M73.2c).",
         nullptr},
        {"reflectionProbes", "",
         "Reflection probes: local environment captures, baked or realtime, that the lit meshes reflect (M73.3, "
         "M73-P3c): every ReflectionProbe holds an octahedral map with a roughness chain and spherical-harmonics "
         "diffuse in the probe atlas, a mesh inside its box reflects it (box projection, blended with the next "
         "probe and the sky), a mesh outside every box reflects the sky. Every GPU draws it: the atlas is RGBA16F, "
         "or RGBA8 (coarser, no values above 4) where the GPU cannot render to half floats; render.probes says "
         "which.",
         nullptr},
        {"volumetricFog", "half+depth",
         "Volumetric fog and light shafts: a medium the sun and the point and spot lights (Light.volumetric) shine "
         "through, raymarched at half or quarter resolution and joined to the picture with a depth-aware upsample "
         "(SceneSettings.volumetricFog; M73.5).",
         nullptr},
        {"decals", "",
         "Projected decals: a Decal box paints albedo, tint and normal relief on the meshes it touches, found through "
         "the light "
         "clusters and applied in the mesh shader (M73.5b).",
         nullptr},
        {"subsurface", "half+depth",
         "Screen-space subsurface scattering for skin and wax: the diffuse light of a mesh with "
         "MeshRenderer.subsurface "
         "is blurred across the surface with a depth-aware separable profile (radius in metres, per colour channel), "
         "never the specular light (M73.5).",
         nullptr},
        {"realtimeGI", "half",
         "Realtime global illumination from a probe grid updated over a few frames, no ray tracing: a RealtimeGI "
         "component is captured into the probe atlas a few probes a frame and the lit meshes inside its box are "
         "shaded with it (the light of the eight probes around each pixel, with a visibility test so light does not "
         "leak through walls), bouncing between captures; it fills the diffuse light where no lightmap and no baked "
         "light probe reaches. It needs RGBA16F render targets that blend; render.gi_grid says which grids the "
         "meshes read (docs/rendering/RENDERING_LIGHT_PROBES.md, \"Realtime global illumination\").",
         nullptr},
        // The 2D lighting and effects of M74: planned "M74" until each package draws its row.
        {"2dSoftShadows", "",
         "Soft 2D shadows: the shadows of Light2D with castShadows get a penumbra that widens with the distance from "
         "the occluder, set by Light2D.size (0 = hard edges), and every shadow-casting light in view (up to the 256 a "
         "frame shades) gets a row of the shadow atlas, an RGBA8 image that every backend has "
         "(docs/rendering/RENDERING_2D_SHADOWS.md; M74.1).",
         nullptr},
        {"2dShadowCasters", "",
         "ShadowCaster2D: sprites (the contour of their alpha), polygons and boxes block the light of Light2D with "
         "castShadows like the solid tiles of a Tilemap with occludesLight, with self-shadowing on or off and "
         "light layers; the CPU makes the rows, so every backend draws it (docs/rendering/RENDERING_2D_SHADOWS.md; "
         "M74.1).",
         nullptr},
        {"2dEmission", "",
         "Emission of 2D visuals: Sprite.emissive, emissiveMap and Tilemap.emissive glow after the lighting and feed "
         "the HDR bloom, on lit and unlit visuals alike. Every backend; the bloom needs RGBA16F targets as usual.",
         nullptr},
        {"2dLightLayers", "",
         "Light layers of 2D lighting: a Light2D lights only the Sprite, Shape2D and Tilemap whose lightLayers share a "
         "bit with its own, in the light buffer and in the per-pixel path (one light buffer per distinct set of lights "
         "in "
         "view, at most 4). Every backend.",
         nullptr},
        {"2dLightCookies", "",
         "Light2D.cookie: a texture the light shines through, turned by cookieRotationDeg and sized by cookieScale; "
         "several lights have one at once, up to 16 distinct textures per frame. Every backend.",
         nullptr},
        {"2dRimLight", "",
         "Sprite rim light (rimColor, rimIntensity, rimWidth): a bright edge on the side of a lit sprite that faces a "
         "light. Every backend.",
         nullptr},
        {"2dGeneratedNormals", "",
         "Normal maps generated for lit sprites: Sprite.normalFrom sprite (from the sprite's alpha and luminance) or "
         "height (from Sprite.heightMap), with normalStrength, made once when the sprite loads. Every backend.",
         nullptr},
        {"2dGlobalIllumination", "half",
         "2D global illumination by radiance cascades (GlobalIllumination2D): light bounces off coloured surfaces and "
         "emissive visuals light the scene (M74). It needs RGBA16F render targets that blend and filter: GL, GLES3 "
         "and WebGL2 without them draw the scene without it and log a message that says how to turn it off. The "
         "quality "
         "high needs more cascade passes than a phone or a browser budgets (4), and the field's memory has a smaller "
         "budget there too (96 MiB): the defaults (range 512, resolutionScale 0.5) need about 103 MiB on a view of "
         "1920 x 1080 pixels, so a landscape phone with them draws the scene without it, with a warning in the log. "
         "On a phone or a browser set range 128 (or resolutionScale 0.25) and use quality medium or low.",
         nullptr},
        {"2dWater", "",
         "Water2D and DistortionZone2D: a reflective, refractive water area with waves and a rectangle that distorts "
         "what is behind it, drawn from the picture drawn so far in the camera (a copy of it, made only when one of "
         "them is in view). Every backend.",
         nullptr},
        {"spriteSceneColor", "",
         "fa_scene_color(uv) in a sprite material: the colour of the picture drawn so far in the camera (the "
         "renderer copies the camera's rectangle before the first such draw and again only where needed, at most 8 "
         "times per camera). Every backend.",
         nullptr},
        // The big worlds of M75 (docs/BIG_WORLDS.md): planned "M75" until each package draws its row.
        {"lodCrossFade", "",
         "Dithered cross-fade between two levels of detail (MeshRenderer.lodCrossFade, LodGroup.crossFade): both "
         "levels "
         "are drawn for the fade's duration, each with a screen-door mask, so a change of level does not pop. Every "
         "backend (M75.1).",
         "M75"},
        {"impostors", "",
         "Impostors: a mesh far away is drawn as one camera-facing quad that shows a baked picture of the model from "
         "the nearest of a ring of angles (MeshRenderer.impostor, the model.bake_impostor command). Every backend "
         "(M75.1).",
         "M75"},
        {"occlusionCpu", "",
         "Occlusion culling on the CPU: the Occluder entities are rasterised into a small depth buffer "
         "(256 cells across) and the meshes it proves hidden are not drawn in the camera's pictures (they still cast "
         "shadows). Needs no GPU feature, so every backend draws it (M75.2). OcclusionArea and OcclusionPortal come "
         "with a later package.",
         nullptr},
        {"occlusionGpu", "compute",
         "Occlusion culling on the GPU: a hierarchical depth image of the last frame culls the objects of a scene "
         "with many thousands of meshes in a compute pass. Needs compute shaders (computeShaders: D3D11, Metal, "
         "OpenGL 4.3; never GLES3 or WebGL2), where the CPU culling is used instead (M75.2).",
         "M75"},
        {"terrain", "",
         "Terrain: a heightmap drawn as tiles that coarsen with distance, with splat-mapped material "
         "layers, holes and an automatic collider (the Terrain component, M75.5). Every backend.",
         "M75"},
        {"foliage", "",
         "Foliage: thousands of instances of a mesh drawn with GPU instancing from a data file, with wind, LODs and a "
         "fade-out distance (the Foliage component, M75.6). Every backend.",
         "M75"}};
    for (const Planned& p : kLighting) t.push_back({p.name, FeatureKind::Engine, kEveryGpu, p.needs, p.planned, p.doc});
    for (int i = 0; i < kPostEffectCount; ++i)
        t.push_back({kPostEffectOrder[std::size_t(i)].data(), FeatureKind::Effect, kEveryGpu, kEffectRows[i].needs,
                     effect_drawn(PostEffect(i)) ? nullptr : "M71", kEffectRows[i].doc});
    return t;
}

bool needs_met(const FeatureEnv& env, const char* needs, std::string* missing) {
    auto need = [&](const char* word, bool have, const char* what) {
        if (std::strstr(needs, word) && !have) {
            if (missing && missing->empty()) *missing = what;
            return false;
        }
        return true;
    };
    bool ok = true;
    ok &= need("half", env.halfTargets, "RGBA16F render targets that blend and filter");
    ok &= need("r11g11b10", env.r11g11b10, "the R11G11B10 float render target");
    ok &= need("depth", env.sampledDepth,
               "sampling the depth of the scene in a shader (a float render target for the depth prepass)");
    ok &= need("compute", env.compute, "compute shaders");
    ok &= need("float32", env.float32, "R32F and RGBA32F render targets that can be sampled");
    return ok;
}

}  // namespace

const char* feature_backend_label(FeatureBackend b) {
    switch (b) {
        case FeatureBackend::Gl: return "GL";
        case FeatureBackend::Gles3: return "GLES3";
        case FeatureBackend::WebGl2: return "WebGL2";
        case FeatureBackend::D3d11: return "D3D11";
        case FeatureBackend::Metal: return "Metal";
        case FeatureBackend::Headless: return "Headless";
    }
    return "?";
}

const std::vector<FeatureDef>& feature_table() {
    static const std::vector<FeatureDef> table = build_table();
    return table;
}

std::vector<std::string> feature_names() {
    std::vector<std::string> out;
    for (const FeatureDef& f : feature_table()) out.push_back(f.name);
    return out;
}

int find_feature(std::string_view name) {
    const std::vector<FeatureDef>& t = feature_table();
    for (std::size_t i = 0; i < t.size(); ++i)
        if (name == t[i].name) return int(i);
    return -1;
}

bool feature_supported(const FeatureEnv& env, int index, std::string* why) {
    const std::vector<FeatureDef>& t = feature_table();
    if (index < 0 || std::size_t(index) >= t.size()) {
        if (why) *why = "unknown feature";
        return false;
    }
    const FeatureDef& f = t[std::size_t(index)];
    if (env.backend == FeatureBackend::Headless) {
        if (why) *why = "there is no GPU (the headless backend draws nothing)";
        return false;
    }
    if (!(f.backends & bit(env.backend))) {
        if (why)
            *why = std::string("the ") + feature_backend_label(env.backend) + " backend cannot do this (" +
                   (std::strcmp(f.name, "hdrOutput") == 0        ? "it has no HDR output here"
                    : std::strcmp(f.name, "computeShaders") == 0 ? "it has no compute shaders"
                                                                 : "it is not available there") +
                   ")";
        return false;
    }
    std::string missing;
    if (!needs_met(env, f.needs, &missing)) {
        if (why) *why = std::string("this GPU lacks ") + missing;
        return false;
    }
    if (f.planned) {
        if (why) *why = std::string("planned (") + f.planned + ")";
        return false;
    }
    if (std::strcmp(f.name, "hdrOutput") == 0 && !env.hdrOutput) {
        if (why)
            *why = env.hdrWhy.empty() ? "the display has not been asked yet (no frame shown in a window)" : env.hdrWhy;
        return false;
    }
    return true;
}

unsigned hdr_encodable(FeatureBackend b) {
    if (b == FeatureBackend::Metal) return hdr_encoding_bit(HdrEncoding::Edr);
    if (b == FeatureBackend::D3d11) return hdr_encoding_bit(HdrEncoding::ScRgb) | hdr_encoding_bit(HdrEncoding::Hdr10);
    return 0u;
}

HdrRequest hdr_request(FeatureBackend b, bool want, float paperWhiteNits) {
    HdrRequest r;
    r.want = want;
    r.paperWhiteNits = paperWhiteNits;
    r.encodable = hdr_encodable(b);
    r.edrLinear = true;  // the present pass writes linear light for EDR (blit.glsl): extended linear sRGB
    return r;
}

void set_hdr_env(FeatureEnv& env, const HdrDisplay& display) {
    const HdrRequest request = hdr_request(env.backend, true, 200.0f);
    const HdrDecision d = decide_hdr_output(request, display);
    env.hdrOutput = d.encoding != HdrEncoding::Sdr;
    env.hdrWhy = d.why;
}

FeatureEnv feature_env_from_sokol() {
    FeatureEnv env;
    switch (sg_query_backend()) {
        case SG_BACKEND_GLCORE: env.backend = FeatureBackend::Gl; break;
        case SG_BACKEND_GLES3:
#if defined(__EMSCRIPTEN__)
            env.backend = FeatureBackend::WebGl2;
#else
            env.backend = FeatureBackend::Gles3;
#endif
            break;
        case SG_BACKEND_D3D11: env.backend = FeatureBackend::D3d11; break;
        case SG_BACKEND_METAL_IOS:
        case SG_BACKEND_METAL_MACOS:
        case SG_BACKEND_METAL_SIMULATOR: env.backend = FeatureBackend::Metal; break;
        default:
            env.backend = FeatureBackend::Headless;
            break;  // the dummy backend (and any sokol backend the engine never builds)
    }
    const sg_pixelformat_info half = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
    env.halfTargets = half.render && half.blend && half.filter;
    const sg_pixelformat_info packed = sg_query_pixelformat(SG_PIXELFORMAT_RG11B10F);
    // The rule of Gpu::init: sokol-gfx reports no blend flag for RG11B10F on GL, where the format blends when it renders at all.
    env.r11g11b10 = packed.render && packed.filter && (packed.blend || env.backend == FeatureBackend::Gl);
    // sampledDepth: the renderer's prepass (Gpu::prepass_color_format) writes the depth into a float colour image, because a depth buffer
    // cannot be sampled when it is multisampled and its range differs per backend; so the answer follows that image's format.
    const sg_pixelformat_info depth = sg_query_pixelformat(SG_PIXELFORMAT_DEPTH);
    const sg_pixelformat_info f32 = sg_query_pixelformat(SG_PIXELFORMAT_RGBA32F);
    const sg_pixelformat_info f16 = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
    env.sampledDepth = depth.render && ((f32.render && f32.sample) || (f16.render && f16.sample));
    const sg_pixelformat_info r32 = sg_query_pixelformat(SG_PIXELFORMAT_R32F);
    env.float32 = r32.render && r32.sample && f32.render && f32.sample;
    env.compute = sg_query_features().compute;
    return env;
}

Json feature_report(const FeatureEnv& env, const char* backendName) {
    Json out = Json::object();
    out["backend"] = backendName;
    out["backendLabel"] = feature_backend_label(env.backend);
    Json list = Json::array();
    const std::vector<FeatureDef>& t = feature_table();
    for (std::size_t i = 0; i < t.size(); ++i) {
        const FeatureDef& f = t[i];
        std::string why;
        const bool ok = feature_supported(env, int(i), &why);
        Json row = Json::object();
        row["name"] = f.name;
        row["kind"] = f.kind == FeatureKind::Capability ? "capability"
                      : f.kind == FeatureKind::Engine   ? "engine"
                                                        : "effect";
        row["supported"] = ok;
        row["status"] = ok ? std::string("supported") : why;
        row["doc"] = f.doc;
        Json backends = Json::object();
        for (int b = 0; b < kFeatureBackendCount; ++b)
            backends[feature_backend_label(FeatureBackend(b))] = (f.backends & bit(FeatureBackend(b))) != 0;
        row["backends"] = backends;
        list.push_back(row);
    }
    out["features"] = list;
    return out;
}

}  // namespace fa::render
