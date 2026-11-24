// Private types shared by the renderer's translation units.
#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "sokol_gfx.h"

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/video.h"
#include "fa/render/lightmap_geometry.h"
#include "fa/render/probe.h"
#include "fa/render/renderer.h"
#include "fa/scene/light_probes.h"
#include "fa/scene/lightmap_manifest.h"
#include "fa/scene/camera_geometry.h"
#include "fa/scene/material_layers.h"
#include "fa/scene/rich_text.h"
#include "fa/scene/screen_fx.h"
#include "fa/scene/world.h"
#include "gpu_types.h"
#include "postprocess_resolve.h"

namespace fa::render {

// ---------------------------------------------------------------------------
// Vertex formats
// ---------------------------------------------------------------------------
// Everything 2D (sprites, tiles, glyphs, shapes, particles, debug lines) uses
// one 48-byte vertex (static_assert below); `mode` selects the fragment path (see shaders/quad.glsl).
// kModeLit (+1 for a left-handed normal-map frame) is a textured quad shaded by the 2D lights; `aux` is then the angle of
// the picture's right axis in the world (radians). See set_lit() and shaders/quad.glsl.
enum QuadMode : int {
    kModeTextured = 0,
    kModeCircle = 1,
    kModeRing = 2,
    kModeSoft = 3,
    kModeGlyph = 4,
    kModeLit = 5,
    kModeShape = 7
};

// kModeShape (Shape2D rounded rectangle / circle with a soft edge or a gradient) uses the fields after `aux`; every other
// mode leaves them zero. The `aux` encoding is documented in shaders/quad.glsl.
struct Vertex2D {
    float x, y, z;
    float u, v;
    std::uint32_t color;  // 0xAABBGGRR
    float mode, aux;
    std::uint32_t color2 = 0;    // kModeShape: gradient end colour
    float halfW = 0, halfH = 0;  // kModeShape: half size of the shape's box in local units
    std::uint16_t radius = 0,
                  softness = 0;  // kModeShape: corner radius and soft edge width in local units, as IEEE half floats
};
static_assert(sizeof(Vertex2D) == 48, "Vertex2D must be 48 bytes");

// float -> IEEE binary16 bits (round to nearest, saturating, no NaN/denormal care: shape sizes are finite and >= 0).
inline std::uint16_t float_to_half_bits(float f) {
    if (!(f > 0.0f)) return 0;
    if (f >= 65504.0f) return 0x7BFF;
    if (f < 6.1035e-5f) return std::uint16_t(f / 5.9604645e-8f + 0.5f);  // subnormal: units of 2^-24
    int e = 0;
    const float m = std::frexp(f, &e);  // f = m * 2^e, m in [0.5, 1)
    const int mant = int(std::lround((m * 2.0f - 1.0f) * 1024.0f));
    return std::uint16_t(((e + 14) << 10) + mant);  // a mantissa of 1024 carries into the exponent, as it should
}

// Vertex buffer 0 of every mesh pipeline. Per-instance data (the model matrix) is vertex buffer 1; skinning will add
// joint indices and weights as a second per-vertex buffer (see Gpu::mesh_pipeline), leaving this struct alone.
struct MeshVertex {
    float px, py, pz;
    float nx, ny, nz;
    float u, v;
    float tx = 0, ty = 0, tz = 0,
          tw = 1;  // tangent (xyz) and handedness (w = +1 / -1): bitangent = cross(normal, tangent) * w
    std::uint32_t color =
        0xFFFFFFFFu;  // vertex color, rgba as four normalized bytes (r in the lowest byte): white = no tint
};
static_assert(sizeof(MeshVertex) == 52, "MeshVertex must be 52 bytes");

// The four bytes of MeshVertex::color for a color (each channel clamped to 0..1 and rounded).
inline std::uint32_t pack_vertex_color(float r, float g, float b, float a) {
    auto q = [](float x) { return std::uint32_t(std::lround(std::fmin(std::fmax(x, 0.0f), 1.0f) * 255.0f)); };
    return q(r) | (q(g) << 8) | (q(b) << 16) | (q(a) << 24);
}

constexpr int kMaxQuadsPerDraw = 16384;  // 16-bit indices
// The lights of a view in the light table of the data texture (src/light_clusters.h, shaders/light_data.glsl): the most relevant
// ones when the scene has more (RenderStats.lightsDropped counts the rest). 4 texels of 16 bytes each (8 when a light has an area, a cookie or
// a profile): 64 KB (128 KB) at the limit.
constexpr int kMaxLights = 1024;
constexpr int kMeshInstanceBytes = 64;  // one Mat4 per instance
// The vertex buffers beyond the mesh (0), the model matrices (1) and the skin (2) that a custom material's programs may
// read (docs/design/CUSTOM_SHADERS.md, "Per-instance params and vertex channels"): the packed per-instance params (up
// to 3 vec4 per instance, one value per instance), then the declared mesh channels uv1 (2 floats) and color1 (4
// normalized bytes), per vertex.
constexpr int kInstanceDataBuffer = 3, kUv1Buffer = 4, kColor1Buffer = 5;
constexpr int kMaxInstanceVec4 = 3;  // fa/tooling/shaders.h kMaterialMaxInstanceVec4
// The first attribute location of those extras in a program that has them: after the matrix (9), or after the joints
// and weights of a skinned program (11), in mesh_common.glsl FA_X_BASE. Up to kMaxInstanceVec4 + 2 attributes: 16 =
// SG_MAX_VERTEX_ATTRIBUTES.
constexpr int kExtraAttrBase = 9, kExtraAttrBaseSkinned = 11;
// M76 motion vectors: vertex buffer 6 holds the previous model matrix of every instance of a prepass draw as the three rows of an affine
// matrix (48 bytes, the instance matrix without its constant last row), per instance, read by attributes 3 after the extras
// (mesh_common.glsl, fa_prev_r0..2). The prepass programs that have them: the engine's and every material's, unless the material draws
// from storage buffers or declares so many extras that 3 more would pass the 16 attributes of SG_MAX_VERTEX_ATTRIBUTES (prepass_prev_attr).
constexpr int kPrevModelBuffer = 6;
constexpr int kPrevModelBytes = 48;
struct PrevModelRows {
    float rows[12];
};
static_assert(sizeof(PrevModelRows) == kPrevModelBytes, "a previous model is three vec4");
// The extra vertex attributes of a custom material's main, prepass and (with vertex() or alphaMode "clip") shadow
// programs; a material without per-instance params and declared channels has none, and its pipelines are the built-in
// layout.
struct MeshExtras {
    int instanceVec4 = 0;  // vec4 of per-instance data (vertex buffer 3), 0..kMaxInstanceVec4
    bool uv1 = false;      // vertex buffer 4: TEXCOORD_1 as two floats
    bool color1 = false;   // vertex buffer 5: COLOR_1 as four normalized bytes
    // The material has "buffers": its instances read storage buffers and its model matrix is a uniform. Its pipelines
    // therefore point the instance attributes fa_inst_m0..3 at the mesh's own vertex buffer instead of at vertex buffer
    // 1, which holds one matrix only (Gpu: set_instance_layout).
    bool bufferInst = false;
    bool any() const { return instanceVec4 > 0 || uv1 || color1; }
    // The vertex attributes the extras take (instance params, uv1, color1).
    int count() const { return instanceVec4 + (uv1 ? 1 : 0) + (color1 ? 1 : 0); }
};
// The location of the previous model's first attribute in a prepass program (vertex buffer kPrevModelBuffer), or -1 when the program has
// none: one drawn from storage buffers, or one with so many extra attributes that 3 more would pass the 16 attributes of
// SG_MAX_VERTEX_ATTRIBUTES (more than 4 extras, a skinned program: more than 2). The same rule as `FA_PREV_BASE` in mesh_common.glsl
// prepass_vs and prepass_vs_skin; `custom` is false for the engine's own programs (no extras).
inline int prepass_prev_attr(bool skinned, bool custom, const MeshExtras& e) {
    if (custom && e.bufferInst) return -1;
    const int first = (skinned ? kExtraAttrBaseSkinned : kExtraAttrBase) + (custom ? e.count() : 0);
    return first + 3 <= 16 ? first : -1;
}
// The previous joint palette of a skinned draw of the prepass with motion vectors (M76-P1c) is read from an RGBA32F image by the vertex stage
// (shaders/mesh_common.glsl, block fa_prev_palette: view 29, sampler 11, texelFetch), so a skin of any joint count up to kMaxSkinJoints has
// vectors and no uniform is used. The image is a stream of texels in rows of kPrevPaletteWidth: a joint is 3 texels, a palette is
// kPrevPaletteTexels (the 64 joints, the unused ones the identity, so a joint index the weights ignore still reads a matrix) and each
// skinned draw of the frame has its own. At most kPrevPaletteMaxRows rows (16 MiB): 5461 skinned draws a camera and frame; the rest write the
// sentinel (a warning, once). The image is uploaded before the first pass of the frame (Impl::upload_prev_palettes, Gpu::write_palette_image).
// Slot table: vertex view 29 and vertex sampler 11 belong to fa_prev_palette (a vertex-stage slot, so none of the fragment-stage rows of
// kMeshFragmentViews below uses it), and sampler 11 was the last free one of the 12 sokol has: the next vertex-stage image must share a sampler.
constexpr int kPrevPaletteWidth = 1024, kPrevPaletteMaxRows = 1024;
// Skinning: a skinned part has a third vertex buffer (vertex buffer 2) of SkinVertex, and the draw uploads the joint
// palette as kMaxSkinJoints 3x4 matrices (three vec4 rows each = 192 vec4, which fits the 256 vec4 of vertex uniforms
// that GLES3 / WebGL2 guarantee next to the other uniforms). A model with more joints is drawn in bind pose.
constexpr int kMaxSkinJoints = 64;
constexpr int kPrevPaletteTexels = 3 * kMaxSkinJoints;  // one previous palette in the image of the motion vectors
struct SkinVertex {
    std::uint8_t joints[4];
    float weights[4];
};
static_assert(sizeof(SkinVertex) == 20, "SkinVertex must be 20 bytes");

// Light2D budget of one frame (docs/PERFORMANCE.md): the point lights are added up in a light buffer, one quad each, so the
// count is bounded by what the vertex stream and the fill rate can take, not by uniforms.
constexpr int kMaxLights2D = 256;
// Lit visuals with a normal map still shade per pixel in the fragment shader (the direction of every light matters there),
// with the first kDirectLights2D lights: the size of the light arrays in quad.glsl (quad_fs_params is about 100 vec4s with the
// cookies and the scene copy, under the WebGL2 / GLES3 minimum of 224 vec4s of a fragment uniform block). The same loop shades every lit visual when the light buffer cannot be used (a perspective camera, or a
// GPU that can render to neither a half-float nor an 8-bit target).
constexpr int kDirectLights2D = 16;
// Point lights with castShadows that get a shadow row (one row of kShadowAngles distances in a data texture): every light a
// frame holds (a frame shades at most kMaxLights2D).
constexpr int kMaxShadowLights2D = kMaxLights2D;
constexpr int kShadowAngles = 1024;

// One Light2D as the quad shader reads it. pos: xyz + w = radius (point, xyz = position with z the height) or -1
// (directional, xyz = unit vector towards the light); color: rgb * intensity, w = falloff exponent; extra: x = the row of
// the light's shadows in the shadow texture (-1 = none), y = 1 when the Light2D asked for shadows.
//
// M74: `layers` is Light2D.lightLayers (a visual receives the light when its own mask shares a bit); `cookieTex` is Light2D.cookie
// (null = none) with its turn in radians and its size as a multiple of the light's diameter; `cookieCell` is the cell of the cookie
// atlas the renderer gave it this frame (-1 = none; Renderer::Impl::plan_cookies).
struct TextureAsset;
struct Light2DData {
    float pos[4];
    float color[4];
    float extra[4] = {-1.0f, 0.0f, 0.0f, 0.0f};
    // Soft shadows (M74.1): Light2D.size in world units (0 = hard edges). `layers` (Light2D.lightLayers) also picks the casters
    // and tiles that block the light.
    float shadowSize = 0.0f;
    std::int32_t layers = -1;
    TextureAsset* cookieTex = nullptr;
    float cookieRot = 0.0f;
    float cookieScale = 1.0f;
    int cookieCell = -1;
};
// The cookie atlas (M74): kCookieGrid x kCookieGrid cells of kCookieCell texels, one per distinct cookie texture of the frame.
constexpr int kCookieGrid = 4, kCookieCell = 256;
constexpr int kMaxCookies2D = kCookieGrid * kCookieGrid;
// Distinct light buffers of one frame (M74 light layers): visuals whose layer masks reach different sets of lights read different
// buffers. The default scene (every light on every layer) has one.
constexpr int kMaxLightBuffers2D = 4;

// One corner of a point light's quad in the light buffer pass (light.glsl): the same values at the four corners.
struct LightVertex {
    float corner[2];  // -1 or 1: where the corner lies from the light, in radii
    float pos[4];     // xy position, z height, w radius
    float color[4];   // rgb * intensity, w falloff
    float shadow[4];  // x = shadow row or -1, y = Light2D.size (world units, 0 = hard shadow edges)
    // M74: x, y, z = the cookie's cell in the atlas (u origin, v origin, v step: negative on OpenGL), w = u step; 0 = none
    float cookie[4];
    float cookieXf[4];  // M74: x, y = cos and sin of the cookie's turn, z = 1 / the cookie's width in world units
};
static_assert(sizeof(LightVertex) == 88, "LightVertex is 22 floats");

// ---------------------------------------------------------------------------
// GPU resources
// ---------------------------------------------------------------------------
// Shader programs of the PostProcess bloom (bloom.glsl).
enum class BloomStage : std::uint8_t { Bright, Down, Blur, Composite, Count };
// The two programs of the automatic exposure (exposure.glsl): the log-luminance of the frame, and the adaptation of the stored EV.
enum class ExposureStage : std::uint8_t { Luma, Adapt, Count };
// The programs of the ambient occlusion (ssao.glsl): the horizon search, the bilateral blur, and the darkening of the picture (Apply
// multiplies it into the scene; View, the same program, writes the occlusion as a grey instead: Renderer::set_debug_view ao).
enum class SsaoStage : std::uint8_t { Ao, Blur, Apply, View, Count };

// LinearClamp: bilinear, clamp to edge, no mipmaps (post-processing).
enum class SamplerKind : std::uint8_t { Nearest, Linear, LinearRepeat, NearestRepeat, LinearClamp, Count };

// What the texels of a texture mean (SceneSettings.colorSpace "linear", M71).
//   Raw    : 8-bit values as the file or the game wrote them (authored sRGB-encoded colours, or data), sampled as they are.
//   Srgb   : the GPU decodes the texels (an SRGB8A8, BC7/ASTC/ETC2 sRGB image) when it samples: a linear scene reads colours as
//            linear light for free, and filters them in linear light. Made so only while the scene is linear.
//   Scene  : holds what the scene target holds (a CameraView or render-target image): linear in a linear scene, gamma in a gamma
//            scene, and never converted.
enum class TexEncoding : std::uint8_t { Raw, Srgb, Scene };

struct TextureAsset {
    std::string path;
    TexEncoding enc = TexEncoding::Raw;
    sg_image image{};
    sg_view view{};
    int width = 0, height = 0;  // pixels of the original file: what regions, sprite sizes and scripts work with
    bool placeholder = false;   // magenta/black checker standing in for a missing/broken file
    // A picture something draws into every frame (a camera's render target or view, a compute image): its contents change
    // under the same view id, so a copy of it made once is stale (the 2D light cookie atlas copies it every frame).
    // (Probes and GI faces are marked too, though a cookie cannot reach them today.)
    bool live = false;
    sg_pixel_format format = SG_PIXELFORMAT_RGBA8;  // what the GPU holds (compressed when the file is a KTX2 twin)
    std::size_t bytes = 0;                          // GPU memory of all mip levels
    // Packed into an atlas by an export: the atlas holds this texture at (atlasX, atlasY) and image/view stay empty.
    TextureAsset* atlas = nullptr;
    int atlasX = 0, atlasY = 0;
    // Loaded in the background (Assets::adopt_texture): the project files it read, reported to the load trace on its first
    // use (LoadTrace::file_used), so the load order lists them where a load on first use would have read them.
    std::vector<std::string> untraced;

    sg_view gpu_view() const { return atlas ? atlas->view : view; }
    // The fix the shader applies to a sample of this texture (fa_tex_fix: 0 none, 1 sRGB -> linear, 2 linear -> sRGB) so that a
    // colour use sees linear light in a linear scene and the file's own values otherwise, and a data use (normal map, masks)
    // always sees the file's values: one texture asset serves both uses, whichever format it was made in (the first user that
    // loads it decides the format; a use the format does not suit is corrected here, at the cost of filtering such a texture in
    // linear light, a small difference). `colour`: the sample is a colour (sprite, albedo, emissive), not data.
    // `displayOverLinear`: the pass writes display values over a linear scene (Frame::displayOverLinear).
    int tex_fix(bool linearScene, bool colour, bool displayOverLinear = false) const {
        const TexEncoding e = (atlas ? atlas->enc : enc);
        if (e == TexEncoding::Scene) return displayOverLinear && colour ? 2 : 0;
        const bool decoded = e == TexEncoding::Srgb;
        return linearScene && colour ? (decoded ? 0 : 1) : (decoded ? 2 : 0);
    }
    // UV of pixel (x, y) of the original file (top-left origin): inside the atlas when the texture is packed.
    Vec2 uv(float x, float y) const {
        const TextureAsset& s = atlas ? *atlas : *this;
        return {((atlas ? float(atlasX) : 0.0f) + x) / float(std::max(1, s.width)),
                ((atlas ? float(atlasY) : 0.0f) + y) / float(std::max(1, s.height))};
    }
};

// The uv of a normal map for a uv of its diffuse texture: normal_uv = uv * out[0..1] + out[2..3]. Both textures show the
// same picture (any resolution); either may be packed in an atlas (an export), where the picture sits at (atlasX, atlasY).
inline void normal_uv_transform(const TextureAsset& diffuse, const TextureAsset& normal, float out[4]) {
    const TextureAsset& ds = diffuse.atlas ? *diffuse.atlas : diffuse;
    const TextureAsset& ns = normal.atlas ? *normal.atlas : normal;
    const float dW = float(std::max(1, diffuse.width)), dH = float(std::max(1, diffuse.height));
    const float nW = float(std::max(1, normal.width)), nH = float(std::max(1, normal.height));
    const float dOx = diffuse.atlas ? float(diffuse.atlasX) : 0.0f, dOy = diffuse.atlas ? float(diffuse.atlasY) : 0.0f;
    const float nOx = normal.atlas ? float(normal.atlasX) : 0.0f, nOy = normal.atlas ? float(normal.atlasY) : 0.0f;
    const float dSw = float(std::max(1, ds.width)), dSh = float(std::max(1, ds.height));
    const float nSw = float(std::max(1, ns.width)), nSh = float(std::max(1, ns.height));
    // picture fraction p = (uv * dSrc - dOrigin) / dSize;  normal_uv = (p * nSize + nOrigin) / nSrc
    out[0] = dSw / dW * nW / nSw;
    out[1] = dSh / dH * nH / nSh;
    out[2] = (nOx - dOx * nW / dW) / nSw;
    out[3] = (nOy - dOy * nH / dH) / nSh;
}

// A KTX2 file (Basis Universal, UASTC or ETC1S) transcoded for the GPU (ktx2.cpp).
struct TranscodedTexture {
    int width = 0, height = 0;
    sg_pixel_format format = SG_PIXELFORMAT_RGBA8;
    std::vector<std::vector<std::uint8_t>> levels;  // every mip level, largest first
};
// Picks the best format this GPU samples: ASTC 4x4 (mobile GPUs), BC7 (desktop), ETC2 RGBA8 (every GLES3 device), else
// RGBA8. `allowCompressed` false goes straight to RGBA8. The environment variable FA_TEXTURE_FORMAT (astc, bc7, etc2 or
// rgba8) narrows the choice to that one format, to test a path on a GPU that would pick another.
Result<TranscodedTexture> transcode_ktx2(const std::uint8_t* data, std::size_t size, bool allowCompressed);
// The format transcode_ktx2 picks with compression allowed (asks the GPU: main thread), and the transcode to a format
// chosen before (any thread: what a background decode job runs). A format that is not a block format, or a size that
// is not a multiple of 4, gives RGBA8.
sg_pixel_format ktx2_target_format();
Result<TranscodedTexture> transcode_ktx2_as(const std::uint8_t* data, std::size_t size, sg_pixel_format format);
const char* pixel_format_name(
    sg_pixel_format
        format);  // "RGBA8", "BC7", "ASTC_4x4", "ETC2_RGBA8", the sRGB twins ("SRGB8A8", "BC7_SRGB", ...), "RGBA16F", "R11G11B10"

struct SubMesh {
    sg_buffer vb{};
    sg_buffer skinVb{};  // SkinVertex per vertex when the part belongs to a skinned glTF node; else id 0
    sg_buffer
        uv1Vb{};  // TEXCOORD_1 (two floats per vertex) when the glTF primitive has it, else id 0 (a material's "uv1")
    sg_buffer
        color1Vb{};  // COLOR_1 (four normalized bytes per vertex, like MeshVertex::color) when it has it, else id 0
    int skin = -1;   // index of the glTF skin that deforms it (-1 = not skinned)
    sg_buffer ib{};
    int ibOffset = 0;  // byte offset of this part's first index in `ib` (a procedural mesh's submeshes share one pair)
    int vertexCount = 0;
    int indexCount = 0;
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};
    std::string materialName;  // glTF material name ("" = none): the key of MeshRenderer.materialColors
    Color baseColor{1, 1, 1, 1};
    TextureAsset* texture = nullptr;       // glTF base color texture (owned by Assets)
    TextureAsset* normalTex = nullptr;     // glTF normalTexture
    TextureAsset* mrTex = nullptr;         // glTF metallicRoughnessTexture (g = roughness, b = metallic)
    TextureAsset* occlusionTex = nullptr;  // glTF occlusionTexture (r)
    TextureAsset* emissiveTex = nullptr;   // glTF emissiveTexture
    float normalScale = 1.0f;
    float occlusionStrength = 1.0f;
    // The glTF material layers (KHR_materials_clearcoat, _sheen, _anisotropy, _specular, _ior; M73.6). `layersPacked`: what the
    // importer packed into the maps the part binds (pack_layer_textures): 1 = the occlusion map also holds the clear coat (g),
    // its roughness (b) and the sheen roughness (a), 2 = the metallic-roughness map also holds the anisotropy strength (r) and the
    // specular (a); 3 = both. 0 = those maps are the model's own.
    MaterialLayers layers;
    int layersPacked = 0;
    // glTF pbrMetallicRoughness factors, used instead of MeshRenderer.metallic / roughness when `hasPbr`.
    bool hasPbr = false;
    float metallic = 0.0f, roughness = 0.6f;
    Color emissiveFactor{0, 0, 0, 1};
    bool doubleSided = false;
    bool blended = false;
};

// What a mesh is drawn with when it is lit by a lightmap (made on first use by Assets::lightmap_use, M73.4a): its parts with the lightmap
// UV as `uv1Vb` (the attribute a material's "uv1" channel reads). A mesh whose glTF has TEXCOORD_1 on every part is drawn with its own
// buffers (`parts` are copies of MeshAsset::parts); any other is drawn with split vertices (lightmap_geometry.h) in buffers of its own,
// which every part shares (`ibOffset`).
struct MeshLightmap {
    bool ok = false;     // false: the geometry could not be built (reported once); the mesh is drawn without a lightmap
    std::string uvKind;  // "gltf" or "generated"
    std::string hashHex;         // lightmap_hash_hex of the geometry: compared with the manifest entry's meshHash
    std::vector<SubMesh> parts;  // one per part of the mesh, in the same order
    sg_buffer vb{}, ib{}, uv{}, color1{};  // owned buffers of a generated unwrap (id 0 for a mesh drawn with its own)
};

struct MeshAsset {
    std::string key;
    std::vector<SubMesh> parts;
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};
    bool placeholder = false;
    std::vector<std::string> untraced;  // as TextureAsset::untraced (its parts' textures are reported after it)
    std::unique_ptr<MeshLightmap>
        lightmap;  // built by Assets::lightmap_use for a mesh a manifest lists; dropped when the mesh reloads
};

// One page of the scene's baked lightmap on the GPU: an RGBA16F image of the .hdr (row 0 = v 0 = the file's first row).
struct LightmapPageGpu {
    std::string file;
    int width = 0, height = 0;
    sg_image image{};
    sg_view view{};
    std::size_t bytes = 0;
    bool ok =
        false;  // false: the file could not be read (reported once); entities on this page are drawn without a lightmap
};
// The scene's lightmap manifest and its pages (SceneSettings.lightmaps), loaded by Assets::lightmaps.
struct LightmapSetAsset {
    std::string path;
    LightmapManifest manifest;
    std::vector<LightmapPageGpu> pages;
    ProbeSet probes;  // M73.4d: the light probes of the bake (CPU only); probes.baked() false = none
    bool ok = false;  // false: the manifest did not load (reported once); nothing is lightmapped
    std::size_t bytes = 0;
};
// What one drawn entity needs of the lightmap: its geometry, the page it reads and the rectangle of it (page uv = lightmap uv * (sx, sy)
// + (ox, oy)). `mesh` null = the entity is not lightmapped.
struct LightmapUse {
    const MeshLightmap* mesh = nullptr;
    const LightmapPageGpu* page = nullptr;
    float scaleOffset[4] = {1, 1, 0, 0};
};

// A texture or a glTF model decoded off the main thread for background loading (Renderer::background_work): everything
// but the GPU upload, which Assets::adopt_texture / adopt_mesh do on the main thread. Made by the same code a load on first
// use runs, so both give the same asset.
struct PreparedTexture {
    std::string key;   // the cache key it is for: the texture's path, or the atlas an export packed it into
    std::string file;  // the file read (a KTX2 twin when the export made one)
    bool ktx2 = false;
    Image image;                   // !ktx2: the picture
    std::vector<Image> chain;      // !ktx2: its mip chain (chain[0] unused, as mip_chain gives it)
    bool srgbMips = false;         // !ktx2: the chain was averaged in linear light (see decode_texture_file's srgbMips)
    TranscodedTexture transcoded;  // ktx2
};
struct PreparedTextureRef {  // one texture slot of a glTF material
    enum class Kind { None, Path, Image, Missing } kind = Kind::None;
    std::string path;  // Path: the project path of the image file
    std::string name;  // Image: the embedded image's name; Missing: the failure's key ("" = no failure recorded)
    std::shared_ptr<const Image>
        image;                // Image (shared: every part of a material holds the same composite, not a copy)
    std::string error, hint;  // Missing
};
// The textures of the layer extensions of one glTF material, as the file names them (None = the material has none).
struct LayerTextureRefs {
    PreparedTextureRef clearcoat, clearcoatRoughness, clearcoatNormal, sheenColor, sheenRoughness, anisotropy, specular,
        specularColor;
    bool any() const;
};
// Packs the extension textures of a material into the maps a mesh part already binds, because no texture unit is free
// (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The material layers"): the occlusion map becomes R occlusion (255 when the
// material has none), G clearcoatTexture.R, B clearcoatRoughnessTexture.G, A sheenRoughnessTexture.A; the metallic-roughness
// map becomes R anisotropyTexture.B, G and B of metallicRoughnessTexture, A specularTexture.A; a channel with no texture is 255.
// All the sources of a map are resampled (bilinear, fixed point: the same bytes on every machine) to the largest width and
// height among them. `occlusion` and `metalRough` are replaced by the composites (kind Image) and the returned bits tell which
// (1, 2). Nothing is dropped silently: a texture that is not packed (the clear coat's normal map, the sheen colour, the specular
// colour and the direction of the anisotropy texture: there is no channel for them), one that cannot be read, and a set that is
// larger than kMaxLayerPackPixels, are named in `warnings` with `what` (file and material) and what is used instead.
int pack_layer_textures(LayerTextureRefs& refs, const std::string& what, const std::string& compositeName,
                        PreparedTextureRef& occlusion, PreparedTextureRef& metalRough,
                        std::vector<std::string>& warnings);
inline constexpr std::uint64_t kMaxLayerPackPixels = std::uint64_t(4096) * 4096;  // pixels of one packed map

struct PreparedPart {
    std::vector<MeshVertex> verts;
    std::vector<std::uint32_t> idx;
    SubMesh material;  // the material and bounds fields (no GPU handles, no texture pointers yet)
    PreparedTextureRef base, metalRough, normal, occlusion, emissive;
    std::vector<SkinVertex> skin;       // empty: not skinned
    std::vector<float> uv1;             // TEXCOORD_1, two floats per vertex; empty: the primitive has none
    std::vector<std::uint32_t> color1;  // COLOR_1 packed as MeshVertex::color; empty: the primitive has none
    int skinIndex = -1;
};
struct PreparedMesh {
    std::vector<PreparedPart> parts;
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};
    std::vector<std::string> warnings;  // logged when it is uploaded, on the main thread
};
// glTF bytes -> a prepared mesh (any thread; reads the model's buffers through fa::fs). False + `error` when unusable.
bool decode_gltf(const std::string& path, const std::uint8_t* data, std::size_t size, PreparedMesh& out,
                 std::string& error);
// A texture file's bytes -> a prepared texture (any thread). `ktx2Format`: ktx2_target_format() of the main thread. `srgbMips`: the
// texture will be made as an sRGB image (a linear scene, Gpu::texture_format of the main thread): its mips average in linear light.
Result<PreparedTexture> decode_texture_file(const std::string& key, const std::string& file, const std::uint8_t* data,
                                            std::size_t size, sg_pixel_format ktx2Format, bool srgbMips = false);

// Fonts ---------------------------------------------------------------------
struct GlyphInfo {
    float u0 = 0, v0 = 0, u1 = 0, v1 = 0;
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;  // pixel offsets from the pen position on the baseline, y DOWN
    bool empty = false;                    // whitespace or a missing character: no bitmap
};

struct TextQuad {
    float x0, y0, x1, y1;  // local units, y UP, relative to the entity origin after pivot
    float u0, v0, u1, v1;
    std::uint16_t color = 0;  // rich text: 0 = the Text's colour, k = palette[k - 1] of the layout
    std::int32_t grapheme =
        0;  // the grapheme cluster of the text (markup tags not counted) this glyph belongs to: Text.visibleCharacters
};

// A picture of a rich text ([icon:name]): the rectangle it fills, in the units of TextQuad.
struct IconQuad {
    float x0, y0, x1, y1;
    int def;                    // index into TextLayout::iconDefs
    std::int32_t grapheme = 0;  // as TextQuad::grapheme
};

struct TextLayout {
    std::vector<TextQuad> quads;
    Vec2 size{0, 0};  // width/height of the laid out box in local units
    // Rich text only (Text.markup): the colours the quads name and the pictures between the glyphs.
    std::vector<Color> palette;
    std::vector<IconQuad> icons;
    std::vector<RichIcon> iconDefs;
};

// ---------------------------------------------------------------------------
// Pipelines
// ---------------------------------------------------------------------------
// A pipeline is valid only for passes with the colour and depth formats and the sample count it was made for, so those
// are part of its key (`format`, the TargetFormat of gpu_types.h): the same program drawn into an RGBA8 and an RGBA16F
// target, or with 1 and 4 samples, is two entries that live side by side in Gpu's cache. Nothing is flushed when a
// target's format changes.
struct PipelineKey {
    std::uint32_t bits = 0;    // which pipeline (the getter and its flags)
    std::uint32_t shader = 0;  // sg_shader id of a custom material program (0 = the built-in one)
    TargetFormat format{};     // what the pass the pipeline draws in writes into
    bool operator<(const PipelineKey& o) const {
        if (bits != o.bits) return bits < o.bits;
        if (shader != o.shader) return shader < o.shader;
        if (format.color != o.format.color) return format.color < o.format.color;
        if (format.depth != o.format.depth) return format.depth < o.format.depth;
        return format.samples < o.format.samples;
    }
    bool operator==(const PipelineKey& o) const { return bits == o.bits && shader == o.shader && format == o.format; }
};

// ---------------------------------------------------------------------------
// Custom materials (MeshRenderer.material, docs/design/CUSTOM_SHADERS.md)
// ---------------------------------------------------------------------------
class Assets;
constexpr int kMaxMaterialParams = 16,
              kMaxMaterialTextures =
                  4;  // each a vec4 of the fa_material block (fa/tooling/shaders.h kMaterialMaxParams)
// Where a material's uniform blocks and textures sit. The engine's own programs use the slots below the first one; the
// twin's reflection says what a program declares, and a draw binds only that. The uniform block slots are the same for
// both kinds (fa_material_vs in the vertex stage, fa_material in the fragment stage); the generator writes these
// numbers into the top file (tools/common/src/shaders_generate.cpp, generate_material_shader).
//   mesh   (mesh_common.glsl): views 0-5 and samplers 0-1 are the engine's (albedo, normal, shadow, IBL...), uniform
//   blocks 0-3. post   (post_common.glsl): see kMaterialPost* below.
//   sprite (quad_common.glsl): uniform blocks vertex 0 quad_vs_params and fragment 1 quad_fs_params; views 0-3 (tex,
//   normal_tex,
//          light_tex, shadow_tex) and samplers 0-2 (smp, light_smp, shadow_smp) are the engine's, so a material's
//          textures are views 4..7 and samplers 3..6 (kMaterialSprite*): none collides with the 2D slots, and 4 + 4
//          views stay far below the 16 texture units GLES3 and WebGL2 guarantee.
//   sky    (sky_common.glsl): uniform blocks vertex 0 sky_vs_params, fragment 1 sky_fs_params; the engine binds no
//   texture, so a
//          material's textures are views 0..3 and samplers 0..3 (kMaterialSky*), all in the fragment stage (no
//          vertex()).
constexpr int kMaterialFirstView = 6, kMaterialFirstSampler = 2, kMaterialUbVertex = 4, kMaterialUbFragment = 5;
constexpr int kMaterialSpriteFirstView = 4, kMaterialSpriteFirstSampler = 3;
// The quad program's own emissive map, cookie atlas (M74) and GI irradiance image (M74-P3b) sit after the material's textures,
// vertex copies included (views 12, 13 and 14; the scene colour of fa_scene_color is 15, below): the sprite materials' views
// 4..11 stay where they were. They use the samplers the engine's views use (smp, light_smp).
constexpr int kQuadEmissiveView = 12, kQuadCookieView = 13, kQuadGiView = 14;
// The 2D vertex stream is vertex buffer 0; the instanced params of a sprite material are buffer 1 at the attributes
// from 7.
constexpr int kQuadInstBuffer = 1, kQuadInstAttr = 7;
// The per-vertex motion of the quads (shaders/quad_motion.glsl, M76-P1d): vertex buffer 1 of the motion programs, 4 floats a vertex
// (the world motion of the quad's item since the frame before, xyz, and its reactive value, w), one per vertex of the quad stream.
constexpr int kQuadMotionBuffer = 1;
constexpr std::size_t kQuadMotionStride = 4 * sizeof(float);
constexpr int kMaterialSkyFirstView = 0, kMaterialSkyFirstSampler = 0;
// post (post_common.glsl): uniform blocks vertex 0 fa_post_vs_params, fragment 1 fa_post_params; views 0 (fa_scene) and
// 1 (fa_prepass), samplers 0 (linear clamp) and 1 (nearest) are the engine's, so a material's textures are views and
// samplers 2..5; view 6 is the history.
constexpr int kMaterialPostFirstView = 2, kMaterialPostFirstSampler = 2;
// The history of a post pass (fa_history(), the pass's own output of the frame before) is the view after the material's
// textures, read through sampler 0; the program declares it only when the snippet calls fa_history
// (tools/common/include/fa/tooling/shaders.h).
constexpr int kMaterialPostHistoryView = kMaterialPostFirstView + kMaxMaterialTextures;
// A mesh material texture is bound twice: the fragment stage reads it at kMaterialFirstView + i, the vertex stage
// (vertex() may sample it) at kMaterialVsFirstView + i, with the samplers likewise (fa/tooling/shaders.h
// kMaterialVsFirstView, the generator's top file). Each program declares only the slots its stages use, and a draw
// binds only those.
constexpr int kMaterialVsFirstView = kMaterialFirstView + kMaxMaterialTextures,
              kMaterialVsFirstSampler = kMaterialFirstSampler + kMaxMaterialTextures;
// The probe atlas (renderer_probes.h, mesh_common.glsl fa_fs_head, M73-P3c): one 2D image, fragment view 14 (entry 0 is the baked sky of a sky
// material, the others the reflection probes and the GI grid; octahedral levels and a row of nine SH coefficients per tile), and its sampler
// sampler 10 (bilinear, clamp), after the vertex-stage copies. A draw binds it (a white image while no atlas exists). The names keep
// "Env" from when this slot was the sky's cube. View 15 (the irradiance cube until M73.3a) is free.
constexpr int kMaterialEnvView = kMaterialVsFirstView + kMaxMaterialTextures,
              kMaterialEnvSampler = kMaterialVsFirstSampler + kMaxMaterialTextures;
// The read-only storage buffers of a mesh material (fa/tooling/shaders.h kMeshBufferFirstView; M72.4): the vertex stage
// reads buffer i at view kMeshBufferFirstView + i, the fragment stage at kMeshBufferFirstView + <buffer count> + i.
// Such a material takes the model matrix of its entity from the vertex uniform block kMeshInstanceBaseUniform (one
// entity draws many GPU instances).
constexpr int kMaxMeshBuffers = 4, kMeshBufferFirstView = 16, kMeshInstanceBaseUniform = 6;

// ---- The texture slots of the mesh fragment shader: the plan for all of M73 (docs/design/ARCHITECTURE_RENDERING_LIGHTING.md) ----
// GLES3 and WebGL2 guarantee 16 texture units per stage (32 combined) and sokol has kMeshSamplerSlots = 12 sampler slots, so the
// lighting of M73 cannot give every feature its own texture: the packages pack their data into the few slots below, and none
// renumbers another's. A package that needs a slot takes the row of this table (it already has its number), a package that needs
// one more than the table has packs its data into a row or changes the table together with the static_asserts below.
//   - The material keeps its four views (6..9) and samplers (2..5); its vertex-stage copies (views 10..13, samplers 6..9) are in the
//     VERTEX stage and do not count against the fragment units.
//   - Views 16..23 are the read-only storage buffers of a mesh material (kMeshBufferFirstView, M72.4; GL 4.3 / Metal / D3D11 only,
//     they are not texture units). The new views of M73 therefore start at 24.
//   - Data read with texelFetch needs no sampler (sampler -1). Every linear, clamped atlas shares sampler 10 (today's env sampler).
//   - Phases: 0 = before M73 (12 units), 1 = M73.1, M73.2, M73.4, M73.5 and M73.3a landed (15 units bound + the reserved screen slot = 16): the irradiance cube is retired,
//     the sky's nine spherical-harmonics coefficients live in mip 5 of the sky cube (view 14, renderer_env.h) and the unit it freed is
//     the screen slot (view 28), the prepass the contact shadows march through (M73.2c, nearest sampler 1) and later the opaque colour
//     of transmission (M73.6b); 2 = M73.3b/c landed: the prefiltered
//     cube is replaced by the probe atlas (same view 14).
// Reused today's slots: view 1 (the shadow map becomes the shadow atlas, same nearest sampler 1), view 14 (the sky cube becomes the
// reflection-probe atlas) and sampler 10. Freed: view 15 (the irradiance cube), for fa_screen_tex.
inline constexpr int kMeshSamplerSlots = 12, kMeshMaxFragmentUnits = 16;
inline constexpr int kMeshNewViewFirst = kMeshBufferFirstView + 2 * kMaxMeshBuffers;  // 24: after the storage buffers
inline constexpr int kMeshLinearClampSampler = 10;
struct MeshFragmentView {
    const char* name;           // the name in the shader (or the planned one)
    int view;                   // sokol view slot
    int sampler;                // sokol sampler slot, -1 when the data is read with texelFetch
    int firstPhase, lastPhase;  // the phases (see above) in which the slot is bound
    const char* what;           // what it holds and which package brings it
};
inline constexpr MeshFragmentView kMeshFragmentViews[] = {
    {"fa_tex", 0, 0, 0, 2, "base color (today)"},
    {"fa_shadow_tex", 1, 1, 0, 2,
     "today the single directional shadow map; from M73.2 the shadow atlas (cascades, spot and point faces), same "
     "slot"},
    {"fa_normal_tex", 2, 0, 0, 2, "normal map (today)"},
    {"fa_mr_tex", 3, 0, 0, 2, "metallic-roughness map (today)"},
    {"fa_occlusion_tex", 4, 0, 0, 2, "occlusion map (today)"},
    {"fa_emissive_tex", 5, 0, 0, 2, "emissive map (today)"},
    {"material texture 0", 6, 2, 0, 2, "a custom material's textures (today): views 6..9, samplers 2..5"},
    {"material texture 1", 7, 3, 0, 2, "(see above)"},
    {"material texture 2", 8, 4, 0, 2, "(see above)"},
    {"material texture 3", 9, 5, 0, 2, "(see above)"},
    {"fa_env_tex", 14, 10, 0, 1,
     "the baked sky of a sky material: a cube, mips 0..4 the sky prefiltered by roughness, mip 5 its spherical "
     "harmonics (the diffuse ambient; M73.3a); M73.3b/c replaces it by the probe atlas"},
    {"fa_irr_tex", 15, 10, 0, 0, "the irradiance cube, retired by M73.3a (spherical harmonics in mip 5 of fa_env_tex)"},
    {"fa_probe_atlas", 14, 10, 2, 2,
     "M73.3b/c: reflection probes and the sky, octahedral 2D, prefiltered by roughness (replaces fa_env_tex)"},
    {"fa_light_data", 24, 1, 1, 2,
     "M73.1a (today): RGBA32F, texelFetch with the nearest sampler 1: the lights, the clusters' light lists; later the "
     "decals, the sky's SH"},
    {"fa_light_atlas", 25, 10, 1, 2,
     "M73.1b (today): one RGBA16F atlas (src/light_atlas.h) with the LTC tables of the area lights in a reserved block "
     "at its top "
     "left (they take no unit of their own), then the light cookies and IES profiles; bilinear, clamped"},
    {"fa_lightmap", 26, 10, 1, 2,
     "M73.4a: the page of the baked lightmap of the entity drawn (RGBA16F, one page per draw; a white texel when it "
     "has none), read at its lightmap UV"},
    {"fa_decal_atlas", 27, 10, 1, 2,
     "M73.5b (today): the albedo and normal textures of the projected decals, RGBA8 with mips (their boxes and tiles "
     "are in "
     "fa_light_data)"},
    {"fa_screen_tex", 28, 1, 1, 2,
     "the screen slot, read with texelFetch through the nearest sampler 1 (sampler 10 filters, which an unfilterable "
     "image "
     "cannot pair with): M73.2c (today) the prepass of the opaque phase (r = linear view depth, a = 1 on a mesh) for "
     "the "
     "contact shadows, a white image while none is drawn; in the blended phase of a frame with a transmissive mesh "
     "(M73.6b) the "
     "refraction atlas (renderer_xmit.h): the opaque picture and its halves, read with texelFetch too, bilinear and "
     "trilinear by hand"},
};
inline constexpr int kMeshFragmentViewCount = int(sizeof(kMeshFragmentViews) / sizeof(kMeshFragmentViews[0]));

// How many fragment texture units a mesh program binds in a phase (0, 1 or 2).
constexpr int mesh_fragment_units(int phase) {
    int n = 0;
    for (const MeshFragmentView& v : kMeshFragmentViews)
        if (v.firstPhase <= phase && phase <= v.lastPhase) ++n;
    return n;
}
// True when no two slots bound in the same phase share a view, every view is below sokol's 32 and outside the storage buffers'
// range (16..23), every sampler is below 12, and a slot M73 adds takes a view from 24 up (the one exception: the probe atlas takes
// over view 14 of the sky cube).
constexpr bool mesh_fragment_views_valid() {
    for (int i = 0; i < kMeshFragmentViewCount; ++i) {
        const MeshFragmentView& a = kMeshFragmentViews[i];
        if (a.view < 0 || a.view >= SG_MAX_VIEW_BINDSLOTS || a.sampler >= kMeshSamplerSlots ||
            a.firstPhase > a.lastPhase)
            return false;
        const bool storageRange = a.view >= kMeshBufferFirstView && a.view < kMeshNewViewFirst;
        if (storageRange) return false;
        // The views of M73 (not today's) start after the storage buffers.
        if (a.firstPhase > 0 && a.view < kMeshNewViewFirst && !(a.view == 14 && a.firstPhase == 2)) return false;
        for (int j = i + 1; j < kMeshFragmentViewCount; ++j) {
            const MeshFragmentView& b = kMeshFragmentViews[j];
            const bool overlap = a.firstPhase <= b.lastPhase && b.firstPhase <= a.lastPhase;
            if (overlap && a.view == b.view) return false;
        }
    }
    return true;
}
static_assert(mesh_fragment_views_valid(), "kMeshFragmentViews: two slots share a view, or a slot is out of range");
static_assert(mesh_fragment_units(0) <= kMeshMaxFragmentUnits && mesh_fragment_units(1) <= kMeshMaxFragmentUnits &&
                  mesh_fragment_units(2) <= kMeshMaxFragmentUnits,
              "the mesh fragment shader would bind more than the 16 texture units GLES3 and WebGL2 guarantee: pack "
              "data into a slot");
// The slots of today are the ones the shaders and the material tooling already use.
static_assert(kMeshFragmentViews[0].view == 0 && kMeshFragmentViews[1].view == 1 && kMeshFragmentViews[5].view == 5 &&
                  kMeshFragmentViews[6].view == kMaterialFirstView &&
                  kMeshFragmentViews[9].view == kMaterialFirstView + kMaxMaterialTextures - 1 &&
                  kMeshFragmentViews[6].sampler == kMaterialFirstSampler &&
                  kMeshFragmentViews[10].view == kMaterialEnvView &&
                  kMeshFragmentViews[10].sampler == kMaterialEnvSampler &&
                  kMeshFragmentViews[10].sampler == kMeshLinearClampSampler,
              "kMeshFragmentViews no longer matches today's slots (mesh_common.glsl, fa/tooling/shaders.h)");
// A sprite material's textures are bound twice as well: the fragment stage reads texture i at kMaterialSpriteFirstView
// + i, the vertex stage (vertex() may sample it, as fa_vs_<name>) at kMaterialSpriteVsFirstView + i, the samplers
// likewise.
constexpr int kMaterialSpriteVsFirstView = kMaterialSpriteFirstView + kMaxMaterialTextures,
              kMaterialSpriteVsFirstSampler = kMaterialSpriteFirstSampler + kMaxMaterialTextures;
// The picture drawn so far, for a sprite material whose snippet calls fa_scene_color() (M74.4): the program declares this view
// (and the engine's light_smp sampler) only then, so only the draws of such a material bind it (renderer_draw.cpp, water2d.h).
constexpr int kMaterialSpriteSceneView = kQuadGiView + 1;
static_assert(kMaterialSpriteSceneView == 15 &&
                  kMaterialSpriteSceneView == kMaterialSpriteVsFirstView + kMaxMaterialTextures + 3,
              "fa_scene_tex is binding 15 of shaders/quad_common.glsl, after the emissive map (12), the cookie atlas "
              "(13) and the GI image (14)");

// One program of a twin (mesh, mesh_skin, shadow, shadow_skin, prepass, prepass_skin) and what its reflection declares: a draw binds and applies
// only those slots (sokol rejects a binding the shader does not declare, and a declared uniform block left unapplied).
struct MaterialProgram {
    sg_shader shader{};                                       // id 0 = the material has no such program
    std::uint32_t ubMask = 0, viewMask = 0, samplerMask = 0;  // bit n = slot n is declared
    std::uint32_t ubSize[SG_MAX_UNIFORMBLOCK_BINDSLOTS]{};    // bytes of each declared uniform block
    bool has_ub(int slot) const { return (ubMask >> slot) & 1u; }
};
enum MaterialProgramId : int {
    kProgMesh,
    kProgMeshSkin,
    kProgShadow,
    kProgShadowSkin,
    kProgPrepass,  // the depth and normal prepass (mesh_common.glsl prepass_vs / prepass_fs)
    kProgPrepassSkin,
    kProgCount  // the programs of a mesh material; the other kinds name theirs in material_program_names()
};
// A full-shader mesh material (mode "full") keeps the programs of pass p >= 1 after kProgCount: pass p is
// kProgCount + 2 * (p - 1), and + 1 for the skinned one. Pass 0 is kProgMesh / kProgMeshSkin.
constexpr int kMaxMaterialPasses = 4;
inline int pass_program_slot(int pass, bool skinned) {
    return pass == 0 ? (skinned ? kProgMeshSkin : kProgMesh) : kProgCount + 2 * (pass - 1) + (skinned ? 1 : 0);
}
constexpr int kProgCompute = 0;  // the one program of a compute material (MaterialAsset::programs[0])
// Room for the programs of every kind of material (a mesh material has kProgCount of them).
constexpr int kMaxMaterialPrograms = kProgCount + 2 * (kMaxMaterialPasses - 1);
static_assert(kProgCount <= kMaxMaterialPrograms);
// The programs a twin of `kind` carries, in MaterialAsset::programs order (the "programs" keys of the twin).
const std::vector<const char*>& material_program_names(MaterialKind kind);

// The fixed state of one pass of a full-shader material (the twin's "passes"; the tooling validated the words).
struct MaterialPassState {
    std::string name;
    int cull = 1;  // 0 none, 1 back, 2 front
    bool depthTest = true, depthWrite = true;
    int blend = 0;  // 0 none, 1 alpha, 2 additive, 3 multiply
};
// Where a full-shader material's shadow caster comes from (the twin's "shadow").
enum class FullShadow : int { Depth, Custom, None };

struct MaterialParamDef {
    std::string name;
    int components = 1;  // 1..4
    float def[4]{0, 0, 0, 0};
    int vec4 = 0,
        offset = 0;  // an instanced param: where it sits in the per-instance data (vec4 index, first float in it)
};
struct MaterialTextureDef {
    std::string name;
    TextureAsset* defaultTex = nullptr;
    SamplerKind sampler = SamplerKind::Linear;
};

// One field of the element of a compute material's storage buffer, as the twin lists it (std430 offsets made by the
// tooling).
struct MaterialBufferFieldDef {
    std::string name;
    std::string type;          // float, vec2, vec3, vec4, int, uint
    std::uint32_t offset = 0;  // bytes from the start of the element
    int components = 1;        // 1..4 (4 bytes each)
    bool isInt = false, isUint = false;
};
// One storage buffer of a compute material (the twin's "buffers": sorted by name, `binding` = its view slot).
struct MaterialBufferDef {
    std::string name;
    int binding = 0;
    std::uint32_t stride = 0;  // bytes of one element
    bool readOnly = false;
    std::vector<MaterialBufferFieldDef> fields;
};
// One storage image of a compute material (the twin's "images": sorted by name, `binding` = its view slot).
struct MaterialImageDef {
    std::string name;
    int binding = 0;
    sg_pixel_format format = SG_PIXELFORMAT_RGBA8;
    bool readWrite = false;         // the shader may imageLoad it too
    int width = 256, height = 256;  // the size compute.create_image uses when it gets none
};

// What one sprite-kind material draws with in a batch: the packed params and the textures of a 2D item, found once per
// distinct set of values (Assets::sprite_material) so that two items with the same values share one pointer: QuadList
// merges batches on that pointer and the draw reads the block from it, so nothing of `materialParams` is copied or
// compared per item. `error`: the material did not build (or is not a sprite material): the item is drawn with the
// built-in program, tinted magenta. Owned by the MaterialAsset, kept for two frames after the last item that asked for
// it.
struct MaterialAsset;
struct MaterialUse {
    MaterialAsset* material = nullptr;
    bool error = false;
    float params[kMaxMaterialParams][4]{};
    TextureAsset* textures[kMaxMaterialTextures]{};
    int instVec4 =
        0;  // vec4 of per-instance data per quad the material's instanced params take (0 = none; 0 when `error`)
    // A material with "buffers" (M72.4): the compute buffer id of each, read from materialParams (-1 = not an integer
    // id: the Sprite is refused, scene2d.cpp). Part of the key, so two Sprites that read other buffers never share a
    // use or a batch.
    std::int64_t bufferIds[kMaxMeshBuffers]{-1, -1, -1, -1};
    std::uint64_t tick = 0;  // the frame (Assets::begin_material_frame) that last asked for it
};
// What a 2D emitter gets from Assets::sprite_material and hands to QuadList::set_material: nothing (`use` null) for an
// item without a material. `use` holds the values batches split on (the params that are not instanced and the
// textures); the values of the instanced params are `inst` (use->instVec4 * 4 floats), which travel with the quads and
// never split a batch.
struct MaterialRef {
    const MaterialUse* use = nullptr;
    float inst[kMaxInstanceVec4 * 4]{};
};

struct MaterialAsset {
    std::string path;     // the .material.json
    std::string snippet;  // its `shader` file (a change of it reloads the material)
    MaterialKind kind =
        MaterialKind::Mesh;  // its "kind": Mesh, Sprite, Sky and Post (drawn) or Compute (Compute::dispatch)
    std::vector<MaterialBufferDef> buffers;  // Compute: the storage buffers, in binding order
    std::vector<MaterialImageDef> images;    // Compute: the storage images, in binding order (after the buffers)
    int workgroup[3]{64, 1, 1};              // Compute: the threads of one workgroup
    std::string lighting = "pbr", alphaMode = "opaque";
    bool doubleSided = false;
    bool full = false;    // mode "full": the file is the whole shader; `passes` say how it is drawn
    bool prepass = true;  // full: the engine's prepass program draws it (SSAO, fog, depth effects see it)
    bool usesSun =
        false;  // sky: the snippet reads the sun direction (the twin's "usesSun"): only then is the sun part of the environment's key
    bool animated =
        false;  // sky: the snippet reads the time (the twin's "animated"): the environment it lights the meshes with is re-baked as time passes
    FullShadow shadow = FullShadow::Depth;    // full: the shadow caster
    std::vector<MaterialPassState> passes;    // full: in drawing order; a plain material has none
    std::vector<MaterialParamDef> params;     // in the order of the twin's "params" (the packing order)
    std::vector<MaterialParamDef> instanced;  // the "instanced" params of the twin: they travel in the instance buffer
    int instanceVec4 = 0;                     // vec4 of per-instance data they take (0 = none)
    bool uv1 = false, color1 = false;         // the "vertexAttributes" the twin declares
    std::vector<std::string>
        instancedNames;  // their names, sorted: what the hash of MeshRenderer.materialParams leaves out
    std::size_t instancedKey =
        0;  // changes when the set of instanced names does (a cached hash of the overrides is then stale)
    MeshExtras extras() const { return {instanceVec4, uv1, color1, !buffers.empty()}; }
    std::vector<MaterialTextureDef> textures;  // in the order of the twin's "textures" (views 6+i, samplers 2+i)
    MaterialProgram programs
        [kMaxMaterialPrograms];  // by MaterialProgramId for a mesh material; a sprite one: quad, quad_plain; a sky one: sky; a post one: post
    bool ok = false;                         // false = drawn with the error material
    std::string error;                       // the last build error (kept while an older good build still draws)
    int generation = 0;                      // counts successful builds
    std::unordered_set<std::string> warned;  // params already complained about
    // (mesh, part, channel) triples already logged as lacking a declared vertex channel: checked before the message is
    // built, as the draw asks once per part, batch and pass of every frame. Cleared when the material builds again.
    std::unordered_set<std::uint64_t> missingNoted;
    // The sets of values 2D items use (MaterialUse), by a hash of the values and the generation.
    std::unordered_multimap<std::uint64_t, std::unique_ptr<MaterialUse>> uses;
};

// The first channel `m` declares in "vertexAttributes" that `part` has no buffer for ("uv1", "color1"; a glTF primitive
// without TEXCOORD_1 / COLOR_1, or a procedural mesh); nullptr when it has them all.
inline const char* missing_channel(const MaterialAsset& m, const SubMesh& part) {
    if (m.uv1 && !part.uv1Vb.id) return "uv1";
    if (m.color1 && !part.color1Vb.id) return "color1";
    return nullptr;
}

// The dialect name of a sokol backend ("hlsl5", "glsl430"...); "" for an unsupported one.
std::string backend_dialect(sg_backend backend);

// The sg_shader_desc of a twin program (`programs.<name>` of factoria.shader/1) and the slots it declares in `slots` (its
// shader is not made). The desc points into `program`, which must outlive it.
// A compute program ("cs" instead of "vs" and "fs") also needs `workgroup`, the threads of a group (Metal takes them
// with the shader).
// `materialTextures` names the material's textures, so the too-many-texture-pairs error tells them from the engine's.
Result<sg_shader_desc> material_shader_desc(const std::string& label, const Json& program, MaterialProgram& slots,
                                            const int* workgroup = nullptr,
                                            const std::vector<std::string>* materialTextures = nullptr);
// Builds the shader of a twin program; on failure the Error says what the twin/driver rejected.
Result<MaterialProgram> make_material_program(const std::string& label, const Json& program,
                                              const int* workgroup = nullptr,
                                              const std::vector<std::string>* materialTextures = nullptr);

// Packs the params of `m` (defaults overlaid by `overrides`, a MeshRenderer.materialParams object) into one vec4 each.
// A value of the wrong shape or an unknown name is warned about once per material and keeps the default.
// `field` and `holder` say where `overrides` came from, for the warnings ("materialParams.speed of a component using
// ..."; the sky passes "skyMaterialParams" and "SceneSettings").
void pack_material_params(MaterialAsset& m, const Json& overrides, float out[kMaxMaterialParams][4],
                          const char* field = "materialParams", const char* holder = "a component");
// Packs the instanced params of `m` for one instance: `m.instanceVec4` * 4 floats at `out` (defaults overlaid by
// `overrides`; the unused floats of a vec4 are 0). Warns once per material about a value of the wrong shape, like
// pack_material_params.
void pack_instance_params(MaterialAsset& m, const Json& overrides, float* out);
// The texture bound as texture `i` of `m`: the override path in `overrides` (loaded by `assets`), else the default.
TextureAsset* material_texture(MaterialAsset& m, int i, const Json& overrides, Assets& assets,
                               const char* field = "materialParams", const char* holder = "a component");

// ---------------------------------------------------------------------------
// Batches (CPU side, before upload)
// ---------------------------------------------------------------------------
// What a 2D item adds to the plain picture (M74, docs/rendering/RENDERING_2D_EMISSION.md): emission, the light layers that reach it, rim
// light. Batches only merge with an equal one, so a scene that sets none of it keeps the batches it always had. Colours are in the scene's
// colour space already (sRGB picks converted) and multiplied by their intensity.
struct QuadFx {
    float emissive[3] = {0, 0, 0};  // HDR light added after the lighting; all 0 = none
    std::int32_t layers = 1;        // lit items: the Light2D.lightLayers bits that reach the item (Sprite.lightLayers)
    TextureAsset* emissiveMap =
        nullptr;               // multiplies `emissive` per pixel, laid out like the item's texture; null = none
    float rim[3] = {0, 0, 0};  // rim light colour * intensity; all 0 = none (lit sprites)
    float rimUv[2] = {0, 0};   // the rim's width in the texture's uv units along u and v
    bool has_emissive() const { return emissive[0] > 0.0f || emissive[1] > 0.0f || emissive[2] > 0.0f; }
    bool has_rim() const { return rim[0] > 0.0f || rim[1] > 0.0f || rim[2] > 0.0f; }
    // True when the batch needs the full quad program (it adds emission or a rim): never the lean plain one.
    bool needs_full_program() const { return has_emissive() || has_rim(); }
    bool operator==(const QuadFx& o) const {
        return std::memcmp(emissive, o.emissive, sizeof emissive) == 0 && layers == o.layers &&
               emissiveMap == o.emissiveMap && std::memcmp(rim, o.rim, sizeof rim) == 0 &&
               std::memcmp(rimUv, o.rimUv, sizeof rimUv) == 0;
    }
    bool operator!=(const QuadFx& o) const { return !(*this == o); }
};

// One 2D effect that reads the picture drawn so far (M74.4: Water2D, DistortionZone2D with the built-in look), made by
// gather_water_fx (water2d.h) and drawn by WaterFx. Lives in QuadList::effects; QuadItem::effect is its index + 1. Everything is in
// world units and in the colour space of the scene (the tint is already converted).
struct Fx2D {
    bool water = true;  // false: the DistortionZone2D ripple
    float origin[2]{};  // water: the middle of the surface (the top edge) in the world; zone: its centre
    float up[2]{0, 1};  // the unit vector of the entity's up axis in the world (away from the water)
    float size[2]{};    // the area's width (across `up`) and height (along it) after the entity's scale
    float tint[4]{};    // water: scene colour, a = opacity of the body
    float reflection = 0, refraction = 0, amplitude = 0, length = 1, speed = 0;  // water
    float strength = 0;                                                          // zone
};

struct QuadItem {
    int layer = 0;
    float secondary = 0;  // larger = drawn earlier
    std::uint32_t seq = 0;
    std::uint32_t firstVert = 0;
    std::uint32_t quadCount = 0;
    TextureAsset* tex = nullptr;
    SamplerKind smp = SamplerKind::Nearest;
    BlendMode blend = BlendMode::Alpha;
    Rect clip{};       // screen-space scissor rectangle in target pixels; w <= 0 = none (ScrollList content)
    bool lit = false;  // shaded by the 2D lights (kModeLit quads)
    TextureAsset* normal = nullptr;  // lit: the normal map laid out like `tex`; null = a flat surface
    bool plain = true;               // every quad is kModeTextured (QuadList::quad clears it)
    bool opaque = false;             // QuadList::set_opaque(): the quads hide what is under them
    std::uint32_t flash =
        0;  // QuadList::set_flash(): packed colour whose alpha is how much of it replaces the picture; 0 = none
    const MaterialUse* use = nullptr;  // QuadList::set_material(): the item's material (null = the built-in programs)
    std::uint32_t instFirst = 0;       // use->instVec4 > 0: where the item's instanced values start in QuadList::inst
    int instances = 0;                 // QuadList::set_buffer_draw(): > 0 draws the item's one quad this many times
    QuadFx fx;                         // QuadList::set_fx(): emission, light layers, rim light
    std::uint32_t effect =
        0;  // QuadList::set_effect(): 1 + the index in QuadList::effects of the built-in 2D effect; 0 = none
    // M76-P1d, the motion of the item for the velocity image. QuadList::set_motion_source(): the owner's Entity::bits() (0 = the item is
    // still in the world: a Tilemap, Text) and where the item's origin is in the world now; Renderer::Impl::fill_quad_motion turns them,
    // with the history of the owners, into `motion` (the origin now minus the origin on the frame before; 0 without history).
    std::uint64_t motionKey = 0;
    Vec3 origin{};
    Vec3 motion{};
    // QuadList::set_reactive(): 0..1, how much the temporal resolve trusts these quads over its history (a blended particle); -1 = not set:
    // an Additive item is then reactive 1 (a glow has no velocity and leaves a trail), any other 0. An explicit 0 opts out, additive or not.
    float reactive = -1.0f;
    float reactive_value() const { return reactive >= 0.0f ? reactive : blend == BlendMode::Additive ? 1.0f : 0.0f; }
};

struct QuadBatch {
    std::uint32_t firstQuad = 0;  // in the final, sorted vertex stream
    std::uint32_t quadCount = 0;
    TextureAsset* tex = nullptr;
    SamplerKind smp = SamplerKind::Nearest;
    BlendMode blend = BlendMode::Alpha;
    Rect clip{};       // batches only merge with an equal clip
    bool lit = false;  // lit batches only merge with the same texture and normal map
    // > 0: the batch is ONE quad (an item of a material with buffers, QuadList::set_buffer_draw) drawn this many times
    // in one call, fa_instance_index running 0 .. instances - 1. Such a batch never merges with another. (Here, in the
    // padding after `lit`, so the struct does not grow.)
    int instances = 0;
    TextureAsset* normal = nullptr;
    // Only plain textured quads (kModeTextured, not lit, not BlendMode::Multiply): drawn with the lean quad_plain shader.
    // Merging never waits on it: a batch that takes in one other quad is drawn with the full shader.
    bool plain = true;
    // Only opaque BlendMode::Alpha items (QuadList::set_opaque): drawn without blending, the same pixels for less work on
    // software rasterizers. Batches only merge with an equal `opaque`.
    bool opaque = false;
    // 1 + the index in QuadList::effects of a built-in 2D effect (Fx2D; the batch is that one quad, drawn by WaterFx and never merged
    // with another); 0 = a plain batch. (Here, in the padding after `opaque`, so the struct does not grow.)
    std::uint32_t effect = 0;
    // The material of the items of the batch (null = the built-in programs). Batches only merge with an equal pointer;
    // an `error` use draws with the built-in programs but stays a batch of its own, so the draw can count it.
    const MaterialUse* use = nullptr;
    // use->instVec4 > 0: where the per-vertex instance data of the batch starts in the stream flatten() was given (in
    // floats): use->instVec4 * 4 floats for each of the batch's vertices, so the quads of one batch may all differ in
    // those values.
    std::size_t instFirst = 0;
    // M74: the emission, light layers and rim of the items of the batch; batches only merge with an equal QuadFx.
    QuadFx fx;
    // M76-P1d: at least one item of the batch is reactive (the reactive mask pass draws only those batches).
    bool reactive = false;
};

// `instances` sits in the padding after `lit`; the M74 QuadFx adds 48 bytes.
static_assert(sizeof(QuadBatch) <= 144, "QuadBatch grew: keep new 32-bit fields next to the other small ones");

// Collects quads for one render space, then sorts and flattens them.
class QuadList {
public:
    std::vector<Vertex2D> raw;
    std::vector<QuadItem> items;
    std::vector<float> inst;    // the instanced values of the items that have them (QuadItem::instFirst)
    std::vector<Fx2D> effects;  // the built-in 2D effects of the items that have one (QuadItem::effect)

    void begin_item(int layer, float secondary, TextureAsset* tex, SamplerKind smp, BlendMode blend = BlendMode::Alpha,
                    const Rect& clip = Rect{});
    void quad(const Vertex2D& a, const Vertex2D& b, const Vertex2D& c,
              const Vertex2D& d);  // a,b,c,d = TL,BL,BR,TR style loop
    // Marks the item opened by begin_item() as lit: its quads are kModeLit and `normal` (may be null) is the normal map.
    void set_lit(TextureAsset* normal) {
        cur_.lit = true;
        cur_.normal = normal;
    }
    // Marks the item opened by begin_item() as opaque: every pixel its quads cover is replaced, at full alpha (an opaque
    // picture with an opaque tint, such as a Video's). It is drawn without blending when its blend mode is Alpha.
    void set_opaque() { cur_.opaque = true; }
    // Gives the item opened by begin_item() an emission, a rim light and the light layers that reach it (QuadFx). An item with an
    // emission or a rim is never drawn by the lean plain program.
    void set_fx(const QuadFx& fx) {
        cur_.fx = fx;
        if (fx.needs_full_program()) cur_.plain = false;
    }
    // Marks the item opened by begin_item() as flashing (feel.h): flatten() turns its quads into the shader's "flash" variant
    // (mode + 32), which draws the picture's alpha in `packedColor`'s rgb by `packedColor`'s alpha. Not for the SDF shape mode
    // (it uses color2 for its gradient: Shape2D mixes the colour on the CPU) nor glyphs.
    void set_flash(std::uint32_t packedColor) {
        cur_.flash = packedColor;
        cur_.plain = false;
    }
    // Gives the item opened by begin_item() a material (Assets::sprite_material, asked on the thread that gathers): its
    // quads are drawn by the material's programs with its params, and batches split where the material or its values
    // differ. A material that did not build tints the quads magenta in flatten() (the error material). A null `ref`
    // changes nothing.
    void set_material(const MaterialRef& ref) {
        cur_.use = ref.use;
        if (ref.use && ref.use->instVec4 > 0) {
            cur_.instFirst = std::uint32_t(inst.size());
            inst.insert(inst.end(), ref.inst, ref.inst + ref.use->instVec4 * 4);
        }
    }
    // Makes the item opened by begin_item() a draw from buffers (M72.4): its (one) quad is the template the material's
    // vertex() moves, drawn `instances` times in one call. Call it after set_material, with the item's one quad still
    // to come or done.
    void set_buffer_draw(int instances) { cur_.instances = instances; }
    // M76-P1d: the item opened by begin_item() moves with `key` (an Entity::bits(); 0 = it does not) whose origin is at `origin` in the
    // world now. Renderer::Impl::fill_quad_motion reads both before flatten().
    void set_motion_source(std::uint64_t key, const Vec3& origin) {
        cur_.motionKey = key;
        cur_.origin = origin;
    }
    // M76-P1d: the quads of the item are reactive by `amount` (0..1, clamped): the temporal resolve uses the current frame there.
    void set_reactive(float amount) { cur_.reactive = std::clamp(amount, 0.0f, 1.0f); }
    // Makes the item opened by begin_item() the built-in 2D effect `fx` (Water2D, DistortionZone2D): its one quad is the area the
    // effect covers, drawn by WaterFx from the picture drawn so far. Such an item is a batch of its own.
    void set_effect(const Fx2D& e) {
        effects.push_back(e);
        cur_.effect = std::uint32_t(effects.size());
    }
    void end_item();
    bool empty() const { return items.empty(); }
    // Sorts items (layer asc, secondary desc, seq asc) and appends the vertices in
    // draw order to `out`; returns merged batches referencing `out` (quad indices
    // relative to out's start + `baseQuad`).
    // As jobs when the list is big (render_jobs.h): the sort, then the copy of the vertices; the same result either way.
    // `instOut` (when not null) receives, for every batch of a material with instanced params, the values of each of
    // its quads repeated for its four vertices (QuadBatch::instFirst says where); without it such a batch has no
    // instance data.
    // `motionOut` (when not null, M76-P1d) receives kQuadMotionStride bytes for every vertex appended to `out` (QuadItem::motion, then the
    // reactive value), so the two streams stay index for index; the caller passes it to every flatten() of the stream or to none.
    void flatten(std::vector<Vertex2D>& out, std::vector<QuadBatch>& batches, std::vector<float>* instOut = nullptr,
                 std::vector<float>* motionOut = nullptr);
    void clear() {
        raw.clear();
        items.clear();
        inst.clear();
        effects.clear();
        open_ = false;
    }
    // Moves the items of `part` (a list a job filled, with no item open) after the items of this one, in their order:
    // the result is what this list would hold had the same items been added to it directly. `part` is left empty.
    void append(QuadList& part);
    // Adds the quads of the item open in `part` (begun, not ended) to the item open here, after its own: how a job's
    // share of one big item (a band of rows of a Tilemap) joins it.
    void add_quads_of(const QuadList& part);
    // Appends a copy of items [firstItem, firstItem + itemCount) of `src` (a list with no item open, not this one)
    // after the items of this list: their vertices are copied, `seq` continues this list's, and `secondary` (when not
    // null) replaces the items' secondary sort key. Returns the index the first copy has here. How a camera's list
    // takes in what another camera's list already holds (Scene2D, scene2d.h): the result is what emitting the same
    // items again would have made.
    std::size_t append_items(const QuadList& src, std::size_t firstItem, std::size_t itemCount,
                             const float* secondary = nullptr);

private:
    bool open_ = false;
    QuadItem cur_;
    std::uint32_t seq_ = 0;
    std::vector<std::size_t> offsets_;  // flatten's scratch when it copies as jobs, kept from frame to frame
};

// ---------------------------------------------------------------------------
// Subsystems
// ---------------------------------------------------------------------------
class Gpu;
class Assets;
class Fonts;
class FontSet;

// The bloom of a PostProcess stack (PostProcess.bloom*), already clamped: see sanitize_bloom() in bloom.h. The defaults here are
// the fallbacks for NaN values and equal the PostProcess defaults.
struct BloomSettings {
    bool enabled = false;
    float threshold =
        0.7f;  // 0 .. 20 (above 1: HDR light of a linear scene): brightness (max of r, g, b) where the glow starts
    float intensity = 1.2f;   // 0 .. 10, multiplier of the glow added to the frame
    float radius = 20.0f;     // 1 .. 128 design pixels
    bool screenSpace = true;  // PostProcess.bloomScreenSpace: false = screen-space items are drawn after the bloom
    float knee =
        0.0f;  // 0 .. 1, PostProcess.bloomKnee: how softly the glow starts above the threshold (0 = a hard start)
    float dirtIntensity = 1.0f;  // 0 .. 10, PostProcess.bloomLensDirtIntensity
    std::string dirt;            // PostProcess.bloomLensDirt: the texture path ("" = none)
};

// A camera as the renderer draws it: the geometry the simulation shares (fa/scene/camera_geometry.h) plus what only drawing needs.
struct CameraInfo : CameraGeometry {
    Color clearColor{0.08f, 0.08f, 0.12f, 1};
    bool clear = true;
    bool studio =
        false;  // Camera.lighting == studio: the camera's own rig instead of the scene's lights, ambient, sky and fog
    float studioIntensity = 1.0f;  // Camera.studioIntensity after clamping
    bool areaCulling = true;  // Camera.areaCulling: the OcclusionArea / OcclusionPortal culling applies to this camera
    // A reflection probe capture with ReflectionProbe.clear = color: the picture's background is clearColor, no sky is drawn behind the
    // meshes (the meshes are still lit by the sky). Only the probe captures set it.
    bool noSky = false;
    // The PostProcess stack of this camera (its own component plus the volumes it is inside, postprocess_resolve.h). Resolved every time
    // the camera is built; Null when the world has no PostProcess: the usual case costs one pointer, not a copy.
    std::shared_ptr<const PostStack> postStack;
    // What the passes draw (postprocess.h, make_post_plan): the bloom and the colour filter of postStack after clamping to the supported ranges.
    BloomSettings bloom;
    int colorFilter = 0;  // 0 none, 1 greyscale, 2 highContrast, 3 protanopia, 4 deuteranopia, 5 tritanopia
    // The transient screen effects of this camera (fa/scene/screen_fx.h, copied from World::feel() when the camera is built): the live
    // ones that belong to it or to every camera, oldest first. Empty (no allocation) when none is alive: the usual case.
    std::vector<ScreenFx> screenFx;
};

// A .cube colour lookup table on the GPU (PostProcess.colorGradingLut): the slices of the table tiled in one RGBA8 image (cube_lut.h,
// cube_lut_strip). `view` is empty when the file could not be loaded (Assets::lut then answers null).
struct LutAsset {
    std::string path;
    sg_image image{};
    sg_view view{};
    int size = 0, cols = 0, rows = 0;  // colours per side, and how many slices sit across and down the image
    std::size_t bytes = 0;
    bool retryPending =
        false;  // the first read or parse failed: the next ask reads the file once more before it is an error
};

// An equirectangular .hdr on the GPU (SceneSettings.environmentMap): RGBA16F with its whole mip chain (include/fa/render/hdri.h says what
// the file goes through). `view` is empty when the file could not be loaded (Assets::hdri then answers null). `serial` is different for every
// successful load, so a file that is reloaded is a different environment even at the same path.
struct HdriAsset {
    std::string path;
    sg_image image{};
    sg_view view{};
    int width = 0, height = 0;  // what the GPU has (mip 0)
    std::size_t bytes = 0;
    std::uint64_t serial = 0;
    bool retryPending = false;  // as LutAsset: the first failure is tried once more on the next ask
};

// A baked reflection probe (ReflectionProbe.bakedMap, probe.h): the manifest and its page, read and checked on the CPU (the renderer
// uploads the page into its probe atlas). `ok` is false when the manifest or the page could not be read; `error` says why (what
// `render.probes` shows). `serial` is different for every successful load, so a rebaked file is a different probe at the same path.
struct ProbeBakeAsset {
    std::string path, pagePath;
    bool ok = false;
    std::string error;
    ProbeManifest manifest;
    std::shared_ptr<const ImageF>
        page;  // probe_page_width x probe_page_height, RGB linear light (fa/core/image_float.h)
    std::uint64_t serial = 0;
    bool retryPending = false;  // the first failure may be a pair being rewritten: the next ask reads once more
};

// Texture/mesh/font caches keyed by project-relative path.
class Assets {
public:
    explicit Assets(Gpu& gpu);
    ~Assets();
    // The LUT of a .cube file, loaded on first use and cached (a failed load too: one logged error, null from then on, until the file
    // changes on disk and reload() forgets it). Null for an empty path, a missing file or a malformed one.
    const LutAsset* lut(const std::string& path);
    // The HDRI of a .hdr file, loaded on first use and cached like a LUT (a failed load too: one logged error, null from then on, until the
    // file changes on disk and reload() forgets it). Null for an empty path, a missing or malformed file, or a GPU that cannot filter RGBA16F.
    const HdriAsset* hdri(const std::string& path);
    // The baked probe of a *.probe.json manifest, loaded on first use and cached (a failed one too, with `error`, until the file changes
    // on disk and reload() forgets it). Null for an empty path; never null otherwise (check `ok`). No GPU object: the renderer uploads it.
    const ProbeBakeAsset* probe_bake(const std::string& manifestPath);
    TextureAsset* texture(const std::string& path);  // never null (placeholder on failure)
    // M74 (Sprite.normalFrom): the normal map made from the picture of `path` (`fromHeight` false: its silhouette and brightness, see
    // normal_map_from_sprite) or from the grey image `path` read as a height field (normal_map_from_height_image), at `strength`.
    // Made once, when first asked, and cached per source and strength; made again in place when the source file is reloaded (the
    // pointer stays valid). Null (flat) for an empty path, a render target or runtime texture, or a file that cannot be read (one
    // logged failure with the reason).
    TextureAsset* generated_normal(const std::string& path, bool fromHeight, float strength);
    TextureAsset* white();                                         // 1x1 white
    TextureAsset* placeholder() { return placeholderTex_.get(); }  // the missing-texture checker
    // Answers the render-target ids ("target:<name>", Camera.renderTarget): the resolver returns the live texture of the target or
    // null when no camera renders into that name (texture() then answers the checker and logs why, once per name).
    using TargetResolver = std::function<TextureAsset*(const std::string& name)>;
    void set_target_resolver(TargetResolver r) { targetResolver_ = std::move(r); }
    // Answers the storage-image ids ("compute:<id>", Compute::create_image): the resolver returns the image's texture,
    // or null with `*why` saying what is wrong (the id was destroyed, or the GPU cannot sample the format). texture()
    // then answers the checker and, while drawing, logs `why` once. The texture object of an image lives until
    // compute.destroy_image, also when the image is resized, so a pointer taken in a frame stays valid for that frame.
    using ComputeImageResolver = std::function<TextureAsset*(const std::string& id, std::string* why)>;
    void set_compute_image_resolver(ComputeImageResolver r) { computeResolver_ = std::move(r); }
    // Whether this graphics backend reads storage buffers in a drawing program (the "buffers" of a mesh material;
    // Metal, D3D11 and OpenGL 4.3 do, GLES3, WebGL2 and macOS OpenGL 4.1 do not). Without a gate the real GPU answers;
    // Compute registers one so a test can answer as another backend. False: `*backend` is its name and `*reason` says
    // why not.
    using StorageBufferGate = std::function<bool(std::string* backend, std::string* reason)>;
    void set_storage_buffer_gate(StorageBufferGate g) { bufferGate_ = std::move(g); }
    bool storage_buffers_available(std::string* backend, std::string* reason) const;
    // How many storage buffer bindings one shader stage may use: OpenGL's GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS (GL 4.3
    // only guarantees 8, many drivers give 16), what sokol_gfx reports as
    // sg_limits.max_storage_buffer_bindings_per_stage. A test sets another number (>= 0) to reach the refusal; -1 = the
    // real one. Other backends number buffers by slot with no such limit.
    void set_storage_binding_limit_override(int limit) { storageBindingLimit_ = limit; }
    int storage_binding_limit(bool* limited) const;
    static bool is_compute_id(const std::string& path) { return path.rfind("compute:", 0) == 0; }
    // True while Renderer::render() runs: only then does a target id nobody renders into count as a failure (a query made
    // before the first frame, such as an entity's bounds, only gets the checker).
    void set_drawing(bool on) { drawing_ = on; }
    static bool is_target_id(const std::string& path) { return path.rfind("target:", 0) == 0; }
    // Whether a material's overrides (materialParams) hold a texture path that names a render target ("target:<name>").
    static bool params_name_target(const Json& params) {
        if (!params.is_object()) return false;
        for (auto& [k, v] : params.items())
            if (v.is_string() && is_target_id(v.get<std::string>())) return true;
        return false;
    }
    MeshAsset* mesh(const std::string& name);  // never null (cube placeholder on failure)
    // The procedural meshes ("mesh:N" ids of MeshRenderer.mesh, fa/scene/mesh_store.h) are looked up in `store`, the store of the
    // world being drawn: call this before mesh() once per frame. It frees the GPU copy of every mesh that left the store (destroyed,
    // or its scene unloaded) and all of them when `store` is another one than last time. mesh("mesh:N") uploads the mesh on first use
    // and again when its version changed (the buffers are reused when the new data fits); an id the store does not know gives the
    // placeholder cube and a failure that teaches (once per id).
    void set_mesh_store(const MeshStore* store);
    std::size_t procedural_mesh_count() const { return procedural_.size(); }
    // A custom material (a *.material.json), built on first use; never null. A material that failed to build has ok == false
    // (the failure is in report() and logged once) and is drawn with the error material.
    MaterialAsset* material(const std::string& path);
    // The material a 2D item (Sprite.material and the other components with `material`) draws with, for the params in
    // `overrides` (the component's materialParams): the use shared by every item with the same values, or an error use
    // when the material did not build or is not of kind "sprite" (one warning). An empty path gives an empty ref. Call
    // it on the thread that gathers (it may load the material and its textures), never from the jobs that emit quads:
    // hand the ref to them and let them call QuadList::set_material.
    // The answers are kept for the frame by path, kind and values: a second item with the same material and equal
    // `overrides` costs one hash-map find and a comparison, not the path normalization and the packing; no params at
    // all cost a path lookup only. Two sets of values that hold the same keys in another order are two sets (Json keeps
    // the order), each resolved once and, after interning, drawn as the same material. `overrides` must live (and keep
    // its values) until the next begin_material_frame()/drop_material_cache(): it is a component's own field, never a
    // temporary. A component whose params change after it was asked in the same frame (a script wrote them while
    // rendering) is answered for its current values and logged once, in every build.
    MaterialRef sprite_material(const std::string& path, const Json& overrides);
    // sprite_material for values made on the spot (Water2D hands its fields to its material as params): nothing is remembered by
    // the address of `overrides`, so a temporary is fine; the answer is interned like any other, so equal values share one use.
    // Same thread rule as sprite_material.
    MaterialRef sprite_material_once(const std::string& path, const Json& overrides);
    // The same for a custom post pass (PostProcess.customPasses, renderer_custom_post.h): a "post" material and the
    // entry's materialParams. `use->error` is set when the material did not build or is not of kind "post" (one
    // warning); the pass is then skipped, not drawn magenta. Call it on the render thread while the frame is planned.
    MaterialRef post_material(const std::string& path, const Json& overrides);
    // Once per drawn frame, before the first gather: uses no item asked for during the last two frames are dropped, and
    // the per-frame answers of sprite_material() are forgotten.
    void begin_material_frame();
    // Forgets the per-frame answers of sprite_material() (a gather outside a drawn frame, such as a capture, may see
    // components that changed since the last frame).
    void drop_material_cache() { materialVariants_.clear(); }
    // How many times sprite_material() did the whole lookup (not answered from the per-frame cache) since the last
    // begin_material_frame(): RenderStats::materialResolves.
    std::uint32_t material_resolves() const { return materialResolves_; }
    // Puts the count back (a capture of one entity's subtree must not change the numbers of the frame drawn before it).
    void set_material_resolves(std::uint32_t n) { materialResolves_ = n; }
    // How a material gets its twin (empty = read `<path>.<dialect>.shader` through fa::fs). Kept across clear().
    void set_shader_compiler(ShaderCompiler compiler) { shaderCompiler_ = std::move(compiler); }
    bool has_loaded(const std::string& path) const;
    void reload(const std::string& path);
    // Counts every reload(): the decal atlas (renderer_decals.cpp) holds copies of texture pixels and asks whether one of its own
    // textures was reloaded since a generation (`paths` are normalised keys). True too when the log of the last reloads no longer reaches
    // back to `since`, so a doubt rebuilds the atlas and never leaves a stale one.
    // Paths compare exactly, case-sensitive, as Assets already does for textures.
    std::uint64_t reload_generation() const { return reloadGeneration_; }
    bool reloaded_any_of(std::uint64_t since, const std::set<std::string>& paths) const;
    void clear();
    Json report() const;
    std::size_t texture_bytes() const;  // GPU memory of the loaded textures (packed ones are counted in their atlas)
    // Used by fonts for font-file failures.
    void note_failure(const std::string& kind, const std::string& path, const std::string& message,
                      const std::string& hint);
    bool failure_logged(const std::string& kind, const std::string& path) const;
    int texture_count() const { return int(textures_.size()); }

    // The scene's lightmap (SceneSettings.lightmaps, M73.4a): the manifest and its pages, loaded on first use and cached (a failed load too:
    // one logged error, null from then on, until a file of it changes on disk and reload() forgets it). Null for "" or a manifest that did
    // not load. Asking with another path drops the set of the old one.
    const LightmapSetAsset* lightmaps(const std::string& manifestPath);
    // Whether `entityId` (EntityInfo.id) is lit by a lightmap of `set` when drawn with `mesh` (MeshRenderer.mesh `meshName`): it has an
    // entry for that mesh, the mesh still has the geometry the bake saw (a changed model is reported once, the entity is drawn without a
    // lightmap) and its page loaded. Builds the mesh's lightmap vertices on the first ask.
    bool lightmap_use(const LightmapSetAsset& set, const std::string& entityId, MeshAsset& mesh,
                      const std::string& meshName, LightmapUse& out);
    // A buffer of at least `vertices` zero uv pairs: the uv1 attribute of the engine's own mesh program of a mesh that has no lightmap
    // (the program always declares it). Grows; the buffer of an earlier call may be destroyed by a later one, so ask again every draw.
    // `vertices` must be the part's own vertex count (SubMesh::vertexCount, the whole shared buffer for a lightmap mesh): the draw reads uv1
    // at every index of the part, so an index at or past `vertices` would read past the zeros.
    sg_buffer zero_uv1(std::size_t vertices);

    // Background loading (Renderer::adopt_background): puts a prepared asset in the cache with its GPU upload, unless it is
    // there already (loaded on first use meanwhile: the prepared one is dropped). `files`: the project files its read and
    // decode used, reported on first use. Returns the GPU bytes uploaded (0 when dropped).
    std::uint64_t adopt_texture(PreparedTexture& p, std::vector<std::string> files);
    std::uint64_t adopt_mesh(const std::string& key, PreparedMesh& p, std::vector<std::string> files);
    bool has_texture(const std::string& key) const { return textures_.count(key) > 0; }
    bool has_mesh(const std::string& key) const { return meshes_.count(key) > 0; }

    // Makes a texture from CPU pixels (RGBA8) with an optional mip chain.
    TextureAsset* make_texture(const std::string& name, const Image& img, bool mips);

    // A texture made at run time from CPU pixels (Renderer::create_texture), named "runtime:N" (N counts from 1 and is never
    // reused). texture("runtime:N") answers it. It lives until destroy_runtime_texture (or the Assets object): clear() keeps
    // it, because a script holds the id. destroy_runtime_texture returns false for an id that does not exist.
    std::string make_runtime_texture(const Image& img);
    bool destroy_runtime_texture(const std::string& id);
    static bool is_runtime_id(const std::string& path) { return path.rfind("runtime:", 0) == 0; }

    // The texture that shows the current picture of a Video's decoder: made on first use (one write-transient image, made
    // again only when the picture size changes; the TextureAsset pointer stays valid) and written with the decoder's
    // picture once per sokol frame that draws it. Never null. end_video_frame() frees the textures of decoders no
    // video_texture() asked for since the last call (call it once per drawn frame).
    TextureAsset* video_texture(const std::shared_ptr<VideoDecoder>& decoder);
    void end_video_frame();

private:
    friend class MeshLoader;
    struct Failure {
        std::string kind, path, message, hint;
    };
    TextureAsset* load_texture(const std::string& path);
    void destroy_texture(TextureAsset& t);
    void upload_texture(TextureAsset& t, const Image& img, bool mips);
    void upload_rgba(TextureAsset& t, const Image& img, const std::vector<Image>& chain);
    bool upload_ktx2(TextureAsset& t, const std::vector<std::uint8_t>& file, std::string& error);
    bool upload_transcoded(TextureAsset& t, const TranscodedTexture& tex);
    void report_first_use(TextureAsset& t);
    void report_first_use(MeshAsset& m);
    void use_placeholder(TextureAsset& t);
    MeshAsset* load_mesh(const std::string& name);
    void destroy_mesh(MeshAsset& m);
    void destroy_mesh_lightmap(MeshAsset& m);
    void destroy_lightmap_set();
    std::unique_ptr<LightmapSetAsset> lightmapSet_;
    std::string
        lightmapSetPath_;  // the path lightmapSet_ was asked for (kept when it failed, so a bad manifest is read once)
    sg_buffer zeroUv1_{};
    std::size_t zeroUv1Vertices_ = 0;
    struct ProceduralMesh {
        std::unique_ptr<MeshAsset> asset;
        std::uint64_t version = 0;  // MeshStore::Entry::version the GPU copy was made from
        sg_buffer vb{}, ib{};       // shared by every part
        sg_buffer vbStage{},
            ibStage{};  // write-transient staging buffers of an updatable pair (id 0 = immutable buffers)
        std::size_t vbCap = 0, ibCap = 0;  // bytes the buffers hold
        std::uint64_t stagedFrame = 0;     // Gpu::frame() + 1 of the last write into the staging buffers, 0 = never
        std::vector<std::string>
            partTextures;  // base color texture of each part ("" = none), resolved again on every use
    };
    MeshAsset* procedural_mesh(const std::string& id);
    void upload_procedural(ProceduralMesh& pm, const MeshStore::Entry& e);
    void destroy_procedural(ProceduralMesh& pm);
    void build_material(MaterialAsset& m);
    Result<void> build_material_checked(MaterialAsset& m);
    MaterialRef kind_material(const std::string& path, const Json& overrides,
                              MaterialKind want);  // sprite_material, post_material
    std::string missing_hint(const std::string& path, std::string_view ext) const;

    Gpu& gpu_;
    std::unordered_map<std::string, std::unique_ptr<TextureAsset>> textures_;
    std::unordered_map<std::string, std::unique_ptr<LutAsset>> luts_;
    void destroy_lut(LutAsset& l);
    std::unordered_map<std::string, std::unique_ptr<HdriAsset>> hdris_;
    std::uint64_t hdriSerial_ = 0;
    std::unordered_map<std::string, std::unique_ptr<ProbeBakeAsset>> probeBakes_;
    std::uint64_t probeBakeSerial_ = 0;
    void destroy_hdri(HdriAsset& h);
    std::unordered_map<std::string, std::unique_ptr<MeshAsset>> meshes_;
    std::vector<std::unique_ptr<TextureAsset>> anonymous_;  // glTF embedded images
    // generated_normal(): the maps made, by "sprite:" / "height:" + source path + "@" + strength in thousandths; `tex` is null for a source
    // that could not be read.
    struct GeneratedNormal {
        std::unique_ptr<TextureAsset> tex;
        std::string source;  // the normalised path of the picture it was made from
        bool fromHeight = false;
        float strength = 1.0f;
    };
    std::unordered_map<std::string, GeneratedNormal> generatedNormals_;
    void make_generated_normal(const std::string& key, GeneratedNormal& g);
    // generated_normal() answers from here without building a key: by the path as asked, then kind and strength (thousandths).
    struct GeneratedNormalMemo {
        bool fromHeight;
        long milli;
        const GeneratedNormal* entry;
    };
    std::unordered_map<std::string, std::vector<GeneratedNormalMemo>> generatedNormalMemo_;

public:
    // The most strengths (and kinds) of generated normal maps one picture path keeps; more are answered with the closest one made.
    static constexpr int kMaxNormalVariants = 8;
    std::size_t generated_normal_count() const { return generatedNormals_.size(); }

private:
    struct VideoTexture {
        std::weak_ptr<VideoDecoder> decoder;
        std::unique_ptr<TextureAsset> tex;
        std::uint64_t writtenFrame = 0;  // Gpu::frame() + 1 of the last write of the picture into the image, 0 = never
        bool seen = false;
    };
    std::unordered_map<const VideoDecoder*, VideoTexture> videoTextures_;
    std::unordered_map<std::string, std::unique_ptr<TextureAsset>> runtime_;  // make_runtime_texture
    int nextRuntime_ = 1;
    std::unique_ptr<TextureAsset> white_;
    std::unique_ptr<TextureAsset> placeholderTex_;
    TargetResolver targetResolver_;
    ComputeImageResolver computeResolver_;
    StorageBufferGate bufferGate_;
    int storageBindingLimit_ = -1;
    bool drawing_ = false;
    std::unique_ptr<MeshAsset> placeholderMesh_;
    std::vector<Failure> failures_;
    std::unordered_map<std::string, std::string> meshSources_;  // mesh key -> source file (for reload)
    std::uint64_t reloadGeneration_ = 0;
    // The paths of the latest reloads: entry i belongs to generation reloadLogBase_ + i + 1 (the file, and the texture a twin file belongs to).
    std::vector<std::array<std::string, 2>> reloadLog_;
    std::uint64_t reloadLogBase_ = 0;
    std::map<std::string, ProceduralMesh> procedural_;  // "mesh:N" -> its GPU copy
    const MeshStore* meshStore_ = nullptr;
    std::uint64_t meshStoreSerial_ = 0;
    std::unordered_map<std::string, std::unique_ptr<MaterialAsset>> materials_;
    std::uint64_t useTick_ = 0;  // drawn frames counted by begin_material_frame (MaterialUse::tick)
    // sprite_material()'s answers of this frame, by material path: by the component's params address (the usual repeat)
    // and by the hash of the values (a pointer to the first component's params with them: nothing is copied; equal
    // values are compared only on a hash match, so the number of distinct sets is not capped).
    struct MaterialVariant {
        const Json* params;
        std::uint64_t hash;  // of the values when it was resolved: tells a component written to since
        MaterialRef ref;
    };
    // One kind's answers (the "sprite" and the "post" lookups of one path never share them: the answer carries the
    // kind's check).
    struct KindVariants {
        std::unordered_map<const Json*, MaterialVariant>
            byPointer;  // only sets resolved this frame (a by-value hit adds none)
        std::unordered_multimap<std::uint64_t, MaterialVariant> byValue;
        MaterialRef empty;  // the answer for no params at all (null, {} or []): no hash, no entry
        bool hasEmpty = false;
    };
    struct PathVariants {
        KindVariants sprite, post;
    };
    std::unordered_map<std::string, PathVariants> materialVariants_;
    bool variantsChangedNoted_ =
        false;  // the "params changed during the frame" warning is given once (until clear() or a material reload)
    std::uint32_t materialResolves_ = 0;
    MaterialRef resolve_kind_material(const std::string& path, const Json& overrides, MaterialKind want);
    ShaderCompiler shaderCompiler_;
};

bool build_primitive(const std::string& name, std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx);

// The lightmap geometry of a mesh plus what drawing it needs (lightmap_geometry.cpp): `geo` as lightmap_mesh_geometry returns it, the
// vertices to draw (the file's vertices, split along the unwrap's seams when `geo.uvKind` is "generated") and COLOR_1 per drawn vertex when
// every part has it.
struct LightmapBuild {
    LightmapMeshGeometry geo;
    std::vector<MeshVertex> verts;
    std::vector<std::uint32_t> color1;
};
Result<LightmapBuild> build_lightmap_mesh(const std::string& mesh);

// Font loading, glyph atlas, text layout.
struct FontFace;
class Fonts {
public:
    Fonts(Gpu& gpu, Assets& assets);
    ~Fonts();
    // font: "" / "builtin" / "builtin:pixel" / project path to a .ttf. Never null: a font that cannot be loaded is the
    // built-in one (the failure is logged once).
    FontFace* face(const std::string& font);
    // THE text layout: Text drawing (world and screen), measure_text, UI labels and debug text all call it, so what is
    // measured is what is drawn. Lays out t.text in t.font (then the fallback fonts) at `fontSize` local units per em,
    // wrapping at t.maxWidth local units; glyphs are rasterized at fontSize * pixelsPerUnit pixels (4..400). Quads and
    // size are in local units, y up, with t.pivot and t.align applied. t.fontSize is NOT read: the caller scales it
    // (screen-space Text and UI labels multiply it by the text scale).
    // `tightBox`: the lines of a wrapped Text are aligned inside its widest line, not inside the maxWidth box (UI labels:
    // their size is the box they are placed by).
    // `t.markup` / `t.bold` make it rich text (fa/scene/rich_text.h): tags are not characters, a run colour is a palette entry
    // of the layout and an icon is a rectangle in TextLayout::icons. The glyphs of any mix of colours and weights are
    // quads of the one glyph atlas.
    TextLayout layout(const Text& t, float fontSize, float pixelsPerUnit, bool tightBox = false);
    // The project's "text" section: colours, icons and bold faces. Takes effect on the next layout.
    void set_rich_style(const RichTextStyle& style);
    // The fonts every Text falls back to after its own font; the built-in DejaVu Sans stays last. Project paths, or
    // "builtin:pixel". Takes effect on the next layout.
    void set_fallback_fonts(std::vector<std::string> fonts);
    // Background loading: a face loaded off the main thread (load_font_face) joins the cache, unless that font is there
    // already. `files`: the project files it read, reported to the load trace on first use.
    void adopt(std::unique_ptr<FontFace> face, std::vector<std::string> files);
    bool has_face(const std::string& font) const;
    // The fonts and the GPU-free text layout this places glyphs on (font_set.h): Renderer::measure_text asks it for sizes
    // without touching the atlas.
    FontSet& set() const;
    // Uploads the atlas if new glyphs were rasterized. Call after layout, before drawing.
    void sync();
    // Counts the times the glyph atlas was cleared or grown: quads laid out before a change hold UVs of the old atlas.
    unsigned atlas_epoch() const;
    int atlas_size() const;
    TextureAsset* atlas() { return &atlasTex_; }
    void clear();
    Json report() const;

private:
    GlyphInfo glyph(FontFace* face, int px, std::uint32_t gid, bool synthBold = false);

    struct Impl;
    std::unique_ptr<Impl> impl_;
    TextureAsset atlasTex_;
};

// The depth-stencil format of the game target and of every pass that draws the scene.
constexpr sg_pixel_format kSceneDepthFormat = SG_PIXELFORMAT_DEPTH_STENCIL;

// Pipelines, samplers, shaders, static buffers, transient buffer pool.
// The format of the images between the pieces of a cut final pass (Gpu::ldr_cut_format), from what the GPU can do:
// `display` is Gpu::display_format(); `half` and `full` say whether RGBA16F and RGBA32F can be rendered to and sampled
// with filtering. Without an HDR output, or with a display format that is already float, the display format; else the
// first float format the GPU can use, and the display format when it can use none.
sg_pixel_format pick_ldr_cut_format(sg_pixel_format display, bool hdrOutput, bool half, bool full);

class Gpu {
public:
    Gpu() = default;
    bool init(int sampleCount, std::string* error);
    void shutdown();

    sg_sampler sampler(SamplerKind k) const { return samplers_[int(k)]; }
    // `plain` = the lean shader of quad.glsl (quad_plain) for a batch of plain textured quads (QuadBatch::plain).
    // `opaque` = blending off (QuadBatch::opaque).
    //
    // Every pipeline getter has two forms. The one with a `const TargetFormat&` first makes (or finds) the pipeline for
    // a pass that writes into that format and sample count: pass the format of the target you really draw into
    // (PassDesc::format). The one without it is a wrapper for the usual target of that pipeline: the game/scene target
    // (scene_target_format()) for quads, meshes and the sky, the bloom/colour-filter/blit-keep/light/shadow target of
    // that stage for the others.
    // `shader` = a program of a sprite material (quad or quad_plain; the pipeline is keyed by it); default = the
    // built-in one.
    sg_pipeline quad_pipeline(const TargetFormat& format, bool depthTest, bool lines,
                              BlendMode blend = BlendMode::Alpha, bool plain = false, bool opaque = false,
                              sg_shader shader = {}, int instanceVec4 = 0);
    // `instanceVec4` = the vec4 of per-quad instanced params of that material (MaterialUse::instVec4): vertex buffer 1
    // (kQuadInstBuffer), attributes 7.. (the quad vertex shader's fa_inst_d0..2), one value per vertex.
    sg_pipeline quad_pipeline(bool depthTest, bool lines, BlendMode blend = BlendMode::Alpha, bool plain = false,
                              bool opaque = false, sg_shader shader = {}, int instanceVec4 = 0) {
        return quad_pipeline(scene_target_format(), depthTest, lines, blend, plain, opaque, shader, instanceVec4);
    }
    // Vertex buffer 0 = MeshVertex, buffer 1 = one model matrix per instance. A skinned variant adds a `skinned` argument,
    // a PipelineKey bit and a second per-vertex buffer for joints and weights.
    // `shader` = a program of a custom material (the pipeline is keyed by it); default = the built-in mesh program.
    // `extras` = the per-instance params and declared channels of that custom material (MaterialAsset::extras()):
    // vertex buffers 3, 4 and 5 at the attributes after the matrix (and the joints). The shader id decides the
    // pipeline: a material's programs and its extras change together, so the key does not name them.
    // `glass` = a blended mesh with transmission: it culls its back faces unless `doubleSided` (a blended mesh draws both faces otherwise).
    // `lod` = the built-in program (no `shader`) of a draw that cross-fades between two levels of detail: mesh_lod / mesh_skin_lod, the
    // programs with the dither's discard (mesh_common.glsl fa_lod_dither). A custom material dithers inside its own alphaMode "clip".
    sg_pipeline mesh_pipeline(const TargetFormat& format, bool blended, bool doubleSided, bool skinned = false,
                              sg_shader shader = {}, MeshExtras extras = {}, bool glass = false, bool lod = false);
    sg_pipeline mesh_pipeline(bool blended, bool doubleSided, bool skinned = false, sg_shader shader = {},
                              MeshExtras extras = {}, bool glass = false, bool lod = false) {
        return mesh_pipeline(scene_target_format(), blended, doubleSided, skinned, shader, extras, glass, lod);
    }
    // One pass of a full-shader material: the vertex layout of mesh_pipeline with the pass's own cull, depth and blend
    // state.
    sg_pipeline full_pipeline(const TargetFormat& format, const MaterialPassState& state, bool skinned,
                              sg_shader shader, MeshExtras extras);
    sg_pipeline full_pipeline(const MaterialPassState& state, bool skinned, sg_shader shader, MeshExtras extras) {
        return full_pipeline(scene_target_format(), state, skinned, shader, extras);
    }
    // `shader`: the program of a sky material (id 0 = the built-in gradient).
    sg_pipeline sky_pipeline(const TargetFormat& format, sg_shader shader = {});
    sg_pipeline sky_pipeline() { return sky_pipeline(scene_target_format()); }
    sg_pipeline sky_pipeline(sg_shader shader) { return sky_pipeline(scene_target_format(), shader); }

    // The format the game target (and the CameraView and render-target passes drawn with it) writes into:
    // scene_format(), the depth-stencil format and the game target's sample count. A change of scene_format() (the
    // RGBA16F fallback) or of the sample count only makes this return another key: the pipelines of the old one stay in
    // the cache until they go idle.
    TargetFormat scene_target_format() const { return {sceneFormat_, kSceneDepthFormat, sampleCount_}; }
    // The shadow map pass: an R32F colour attachment and a DEPTH one, never multisampled.
    static TargetFormat shadow_target_format() { return {SG_PIXELFORMAT_R32F, SG_PIXELFORMAT_DEPTH, 1}; }

    // The depth and normal prepass (M71, mesh_common.glsl prepass_vs / prepass_fs): one float colour attachment (r = linear view
    // depth, gb = octahedral view-space normal, a = coverage) and a depth buffer, never multisampled. prepass_color_format() is what
    // the GPU renders to and samples: RGBA32F (a depth that stays exact far away), else RGBA16F (about three digits), else NONE: no
    // prepass, and the `sampledDepth` row of render.supports is false. Its shaders (and the debug view's) are made on first use.
    static sg_pixel_format prepass_color_format();
    // `velocity`: the pass also writes the motion vectors into a second colour attachment (velocity_format(), M76).
    TargetFormat prepass_target_format(bool velocity = false) const {
        return {prepass_color_format(), SG_PIXELFORMAT_DEPTH, 1, velocity ? velocity_format() : SG_PIXELFORMAT_NONE};
    }
    // The motion vector image (VelocityRef): RG16F, uvPrev - uvCurr and the sentinel 1024, both exact in half float.
    static sg_pixel_format velocity_format() { return SG_PIXELFORMAT_RG16F; }
    // Can the prepass write it: the prepass works and the GPU renders to and samples an RG16F image. False means no velocity image is made.
    bool velocity_ready();
    bool prepass_ready();
    // The slots (uniform blocks, views, samplers) the built-in prepass program declares, for a draw that binds only those; after prepass_ready().
    const MaterialProgram& prepass_program(bool skinned) const { return prepassProgram_[skinned ? 1 : 0]; }
    // `shader` = a program of a custom material (its prepass or prepass_skin), default = the built-in one. The vertex layout is the
    // main program's (every attribute), the culling the main pass's: `doubleSided` as for mesh_pipeline. Invalid when the built-in
    // shader cannot be made.
    // `cullFront`: the BACK faces are drawn instead of the front ones, double-sided or not (the realtime GI's distance pictures: a probe
    // whose first hit is a back face is inside geometry).
    // `lod`: the built-in program (no `shader`) of a draw that cross-fades between two levels of detail (prepass_lod / prepass_skin_lod,
    // the prepass with the dither); it declares the slots of prepass_program().
    sg_pipeline prepass_pipeline(const TargetFormat& format, bool doubleSided, bool skinned = false,
                                 sg_shader shader = {}, MeshExtras extras = {}, bool cullFront = false,
                                 bool lod = false);
    sg_pipeline prepass_pipeline(bool doubleSided, bool skinned = false, sg_shader shader = {},
                                 MeshExtras extras = {}) {
        return prepass_pipeline(prepass_target_format(), doubleSided, skinned, shader, extras);
    }
    // The subsurface pass (M73.5, mesh_common.glsl fs_sss): the diffuse light of the meshes that scatter into colour 0 (rgb light, a = linear
    // depth) and their scatter radius and strength into colour 1, both RGBA16F with a depth buffer, never multisampled. The shaders are made
    // on first use; sss_ready() is false when they cannot be made (the effect is skipped).
    static TargetFormat sss_target_format() {
        return {SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_DEPTH, 1, SG_PIXELFORMAT_RGBA16F};
    }
    // A built-in 3D program (mesh, skinned mesh, shadow, sky), made the first time a pipeline asks for it.
    sg_shader builtin_shader(sg_shader& slot, const sg_shader_desc* (*desc)(sg_backend), const char* label);
    bool sss_ready();
    // The slots the built-in sss program declares, for a draw that binds only those; after sss_ready().
    const MaterialProgram& sss_program(bool skinned) const { return sssProgram_[skinned ? 1 : 0]; }
    // The main pass's vertex layout and culling, no blending, depth written: the draw of the prepass's depth plus the two colours.
    sg_pipeline sss_pipeline(bool doubleSided, bool skinned);
    // The debug view of the prepass (prepass_view.glsl): a full-screen triangle that draws it as a picture into `format` (the game target's).
    bool prepass_view_ready();
    sg_pipeline prepass_view_pipeline(const TargetFormat& format);
    // M76-P1d: the motion vectors and the reactive mask of the 2D quads of the world (shaders/quad_motion.glsl). The mask is an R8 image
    // (reactive_format(): renderable and sampleable on GLES3, WebGL2, D3D11 and Metal; the MAX blend is core on all of them), and
    // reactive_ready() says whether this GPU makes it. quad_motion_ready() builds the two programs (once; false with one log line when they
    // do not compile). quad_motion_pipeline() draws the quad vertices (Vertex2D in buffer 0 plus the per-vertex motion, buffer 1) into
    // `format` (velocity_format() without blending, or reactive_format() with the MAX blend); null when the shader is not ready.
    static sg_pixel_format reactive_format() { return SG_PIXELFORMAT_R8; }
    bool reactive_ready();
    bool quad_motion_ready();
    sg_pipeline quad_motion_pipeline(const TargetFormat& format, bool reactive);
    // The full-screen triangle of a post material's program (post_common.glsl) into `format`, no blending (the pass
    // writes every pixel of its rectangle) and no depth; keyed by the program, so a reload that destroys it
    // (destroy_shader) drops the pipeline too.
    sg_pipeline post_material_pipeline(const TargetFormat& format, sg_shader shader);

    // The pipeline cache. Entries are keyed by what they draw (PipelineKey: the getter's flags, a custom program, the
    // TargetFormat of the pass). It is bounded: begin_frame() counts a use-tick, and once the cache holds more than
    // pipeline_cache_cap() entries (kPipelineCacheCap, 192: the engine's own set is about 50) an entry that no draw has
    // asked for during the last pipeline_idle_frames() frames (kPipelineIdleFrames, 300: five seconds at 60 fps) is
    // destroyed (checked every 16 frames) and made again if it is ever asked for. Entries in use are never destroyed,
    // so a game never loses a pipeline it draws with; a cache under the cap keeps everything. The pipelines made while
    // or asked for while set_warming(true) (the start-up warm-up, a fixed set of about 20) are never destroyed either, so a rarely used one that the warm-up paid for
    // does not hitch (D3D11, Metal) when it comes back. The count is of frames, never of time, so what is kept does not
    // depend on the CPU speed.
    std::size_t pipeline_count() const { return pipelines_.size(); }  // pipelines in the cache now (start-up report)
    std::uint64_t pipeline_hits() const { return pipelineHits_; }     // asks answered from the cache, since the start
    // Pipelines made (sg_make_pipeline), since the start.
    std::uint64_t pipelines_made() const { return pipelinesMade_; }
    std::uint64_t pipelines_evicted() const { return pipelinesEvicted_; }  // pipelines destroyed for being idle
    // Tests: while on, a pipeline getter makes and caches nothing (it returns an empty pipeline) and keeps the vertex
    // layout it built, which probed_layout() returns. Used to check offsets and strides without a draw.
    void set_layout_probe(bool on) { layoutProbe_ = on; }
    const sg_vertex_layout_state& probed_layout() const { return probedLayout_; }
    // While on, every pipeline made or asked for is kept out of the eviction (Renderer::warm_step turns it on around a group).
    void set_warming(bool on) { warming_ = on; }
    static constexpr std::size_t kPipelineCacheCap = 192;
    static constexpr std::uint64_t kPipelineIdleFrames = 300;
    // Tests: lower the two limits above to see an eviction without drawing hundreds of frames.
    void set_pipeline_cache_limits(std::size_t cap, std::uint64_t idleFrames) {
        pipelineCap_ = cap;
        pipelineIdleFrames_ = idleFrames;
    }
    std::size_t pipeline_cache_cap() const { return pipelineCap_; }
    std::uint64_t pipeline_idle_frames() const { return pipelineIdleFrames_; }
    // `fullVertex` (custom shadow programs: vertex() or alphaMode "clip") also reads normal, texcoord0 and tangent from
    // vertex buffer 0, at locations 5, 6, 7 (skinned: 7, 8, 9) as shadow_vs of mesh_common.glsl declares them.
    // `extras` count only with `fullVertex` (the shadow programs without vertex() and clip do not read them).
    sg_pipeline shadow_pipeline(const TargetFormat& format, bool skinned = false, sg_shader shader = {},
                                bool fullVertex = false, MeshExtras extras = {});
    sg_pipeline shadow_pipeline(bool skinned = false, sg_shader shader = {}, bool fullVertex = false,
                                MeshExtras extras = {}) {
        return shadow_pipeline(shadow_target_format(), skinned, shader, fullVertex, extras);
    }
    // Destroys a custom material program together with the pipelines made from it.
    void destroy_shader(sg_shader shader);
    sg_pipeline blit_pipeline(const TargetFormat& format);
    sg_pipeline blit_pipeline(sg_pixel_format colorFormat, sg_pixel_format depthFormat, int sampleCount) {
        return blit_pipeline(TargetFormat{colorFormat, depthFormat, sampleCount});
    }
    // The same copy into an RGBA8 target without depth, keeping the source's alpha: how a frame in a float scene_format() is
    // read back as the 8-bit picture the screen shows (Renderer::Impl::read_rgba8).
    sg_pipeline blit_keep_pipeline(const TargetFormat& format);
    sg_pipeline blit_keep_pipeline() { return blit_keep_pipeline(blit_keep_target_format()); }
    static TargetFormat blit_keep_target_format() { return {SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_NONE, 1}; }
    // The format of the game target, the CameraView and render-target images and the bloom and colour-filter passes. Gamma scene:
    // RGBA16F where the GPU can render to it with blending, filtering and the requested multisampling, so a colour above white
    // (MeshRenderer.emissiveStrength) survives to bloom; RGBA8 otherwise (everything clamps at white). Linear scene
    // (SceneSettings.colorSpace): RGBA16F, else R11G11B10 (float, no alpha), else SRGB8A8, else RGBA8 (see Gpu::init).
    // FA_SCENE_FORMAT: rgba8 = the 8-bit end of the chain (gamma: RGBA8, linear: SRGB8A8), r11g11b10 = prefer the packed float one
    // (a linear scene; the gamma chain is as without it), read once at init to test a path on a GPU that would pick another.
    sg_pixel_format scene_format() const { return sceneFormat_; }
    // The format of the images that hold the DISPLAY picture (what the final pass writes: sRGB-ENCODED values, so the GPU must not
    // encode them again): RGBA16F where the scene is, else plain RGBA8. SRGB8A8 (a linear scene in 8 bits) would encode them twice;
    // R11G11B10 has a 6-bit mantissa, so encoded values near 1 step by 1/64 of the range and a gradient bands where an 8-bit image
    // does not (the linear scene needs the packed format for its dark values, the encoded picture does not). An 8-bit display image
    // cannot hold values above 1: such a window stays within paper white (Renderer::Impl::float_display).
    sg_pixel_format display_format() const {
        return sceneFormat_ == SG_PIXELFORMAT_SRGB8A8 || sceneFormat_ == SG_PIXELFORMAT_RG11B10F ? SG_PIXELFORMAT_RGBA8
                                                                                                 : sceneFormat_;
    }
    // The format of the images a final pass cut by display-referred custom passes goes through
    // (Renderer::Impl::ldrMid): they hold DISPLAY values like display_format(), so never the scene's own SRGB8A8 (the
    // GPU would encode them again) or R11G11B10 (no alpha, banding). With an HDR output (`hdrOutput`) and a display
    // format that cannot go above 1, a float format the GPU renders to and samples with filtering (RGBA16F, else
    // RGBA32F) when there is one, so a pass that writes above paper white keeps it between the pieces. The choice is
    // pick_ldr_cut_format.
    sg_pixel_format ldr_cut_format(bool hdrOutput) const;
    // The scene is held in linear light (SceneSettings.colorSpace "linear"). set_linear returns true when scene_format() changed:
    // the caller (Renderer::Impl::sync_color_space) then makes the game target again. The pipelines made so far stay in the
    // cache under their own format key; the ones for the new format are made on first use, and nothing is flushed.
    bool linear() const { return linear_; }
    bool set_linear(bool on);
    // Renderer::Impl::create_targets, when the GPU accepted a format but could not make the game target's images in it (GLES3/
    // WebGL2 with multisampling and no EXT_color_buffer_float, a framebuffer the driver finds incomplete): next_scene_format()
    // moves to the next format of the chain (false at its end) and scene_pick() / set_scene_pick() save and restore the position.
    // Only the game target falls back; the images of a CameraView, the bloom levels and the colour filter use the same format
    // and keep their own warnings. A chain position is per colour space: the one the game is not in is not touched.
    bool next_scene_format();
    int scene_pick() const { return sceneChain_[linear_ ? 1 : 0].at; }
    void set_scene_pick(int pick);
    // False for R11G11B10: a CameraView or a world capture drawn into it has no alpha (an opaque background).
    bool scene_has_alpha() const;
    // The scene holds values above 1 (RGBA16F, R11G11B10).
    bool scene_is_float() const;
    // The format a COLOUR texture of this format is made in now: in a linear scene the sRGB variant (SRGB8A8, BC7/ASTC/ETC2 sRGB)
    // where the GPU samples and filters it, so the GPU decodes the texels to linear light before filtering; the format itself in
    // a gamma scene or where there is no sRGB variant (the shader then decodes: TextureAsset::enc, tex_fix).
    sg_pixel_format texture_format(sg_pixel_format unorm) const;
    // The GPU decodes SRGB8A8 when it samples it (every backend but some old GLES).
    bool srgb_textures() const { return srgbTextures_; }

    // Bloom post-processing. The shaders are created on first use; returns false (and logs once) when they
    // cannot be created, in which case the bloom is skipped instead of failing the whole renderer.
    bool bloom_ready();
    // sampleCount > 1: the composite stage can also add its glow straight into the multisampled game target.
    sg_pipeline bloom_pipeline(BloomStage stage, const TargetFormat& format);
    sg_pipeline bloom_pipeline(BloomStage stage, int sampleCount = 1) {
        return bloom_pipeline(stage, TargetFormat{sceneFormat_, SG_PIXELFORMAT_NONE, sampleCount});
    }
    // PostProcess.colorFilterEnabled: one program (colorfilter.glsl), created on first use like the bloom ones; false + one logged
    // error when it cannot be created, and the game is then drawn unfiltered.
    bool colorfilter_ready();
    // Makes the shader first when nothing has yet (GL's render-target flip copy can be its first user); invalid when the
    // shader cannot be created.
    sg_pipeline colorfilter_pipeline(const TargetFormat& format);
    sg_pipeline colorfilter_pipeline() {
        return colorfilter_pipeline(TargetFormat{sceneFormat_, SG_PIXELFORMAT_NONE, 1});
    }

    // The final pass of the post-processing stack (post.glsl: exposure, tonemap, output encode, colour filter): one program, created on
    // first use like the others; false + one logged error when it cannot be created, and the frame is then drawn without it.
    bool post_ready();
    int post_ready_calls() const {
        return postReadyCalls_;
    }  // how often a frame asked for it: 0 for a world without a stack (tests)
    sg_pipeline post_pipeline(const TargetFormat& format);
    // The automatic exposure (exposure.glsl), the same way.
    bool exposure_ready();
    sg_pipeline exposure_pipeline(ExposureStage stage, const TargetFormat& format);
    // The ambient occlusion (ssao.glsl, renderer_ssao.cpp), the same way: false + one logged error when its shaders cannot be made.
    bool ssao_ready();
    sg_pipeline ssao_pipeline(SsaoStage stage, const TargetFormat& format);

    // The 2D light buffer (light.glsl). Its shader is created on first use, like the bloom ones; false + one logged error
    // when it cannot be created, and lit visuals then shade with the per-pixel path (the first kDirectLights2D lights).
    bool light_ready();
    // The format the light buffer is drawn in: RGBA16F where the GPU renders to it with blending and filtering, else RGBA8
    // (half the range, see light_range()), else NONE: no light buffer. The environment variable FA_LIGHT_FORMAT (rgba16f,
    // rgba8 or none) narrows the choice to that one, to test a path on a GPU that would pick another.
    sg_pixel_format light_format() const { return lightFormat_; }
    // How much light one texel of the light buffer holds: 1 in RGBA16F, 2 in RGBA8 (written as light / 2).
    float light_range() const { return lightFormat_ == SG_PIXELFORMAT_RGBA8 ? 2.0f : 1.0f; }
    sg_pipeline light_pipeline(const TargetFormat& format);
    sg_pipeline light_pipeline() { return light_pipeline(light_target_format()); }
    TargetFormat light_target_format() const { return {lightFormat_, SG_PIXELFORMAT_NONE, 1}; }

    // THE way to begin and end a render pass: every pass of the renderer (game, view, shadow, light buffer, colour
    // filter, flip copy, readback, present, bloom) goes through these two, never sg_begin_pass / sg_end_pass.
    // begin_pass records the pass's TargetFormat; in a debug build every pipeline getter then checks that the pipeline
    // it hands out was made for that format (a mismatch GL and D3D11 validation reject, Metal only draws wrong).
    // Outside a pass (warm-up, a getter called before the pass begins) nothing is checked.
    // Static: sokol has one context per process, so there is one pass open at a time, and Renderer::present_clear,
    // which runs before any Gpu exists, begins its pass the same way.
    static void begin_pass(const PassDesc& pass);
    static void end_pass();
    static bool in_pass() { return inPass_; }
    // A compute pass (Compute::dispatch): no attachments, so no PassDesc. Counts as a pass (in_pass()) until
    // end_compute_pass().
    static void begin_compute_pass();
    static void end_compute_pass();
    // The compute pipeline of a compute material's program (`shader`), made on first use and cached like the others
    // (destroy_shader drops it). Invalid, with one logged error, when the driver rejects it. Call it outside a pass.
    sg_pipeline compute_pipeline(sg_shader shader);
    static const TargetFormat& pass_format() {
        return passFormat_;
    }  // of the pass begun last; meaningful while in_pass()

    sg_buffer quad_index_buffer() const { return quadIndices_; }
    sg_buffer fullscreen_triangle() const { return fsTriangle_; }
    // Call before the first CPU write into a write-transient buffer or image of a sokol frame (every writer in the renderer does).
    // A write-transient resource has SG_NUM_INFLIGHT_FRAMES copies and the write of a frame goes into the copy the frame before
    // the last one read; sokol's Metal backend waits for that frame (the semaphore of its command buffers) only when the frame's
    // command buffer is made, at its first pass or copy, so a write before it overwrote data the GPU was still reading whenever
    // the GPU was a frame or two behind (a probe's second face drew with the instances of another face; only a loaded
    // GPU showed it). This makes the frame's command buffer, and so waits for the same frame sokol waits for anyway at the first
    // pass, with an empty copy: no extra synchronisation, only earlier (the CPU may wait a little before the writes of a frame
    // where it would have waited at its first pass). Its copy is GPU work outside a frame: committed() is false until the next
    // sg_commit, so a read-back commits first. Nothing on the other backends (OpenGL and Direct3D 11 order the write in the
    // driver, Vulkan makes the frame's command buffers in the write).
    // docs/design/ARCHITECTURE_THREADS.md, "GPU frames in flight and the CPU's writes".
    void begin_transient_writes();
    // A write-transient vertex buffer of at least `bytes`, valid for this frame.
    sg_buffer acquire_transient(std::size_t bytes);
    // The light data texture of one view (light_clusters.h): a write-transient RGBA32F image of kLightTextureWidth x `rows` texels
    // that holds `texels` (width * rows * 4 floats), written now and valid until the pool restarts like the buffers' (after a
    // commit). Call it once per view and frame, outside a pass, and bind the view this frame.
    struct LightImage {
        sg_image image{};
        sg_view view{};
    };
    LightImage write_light_image(int rows, const float* texels);
    // The image of the previous joint palettes of the motion vectors (M76-P1c, kPrevPaletteWidth wide, the same format and the same rules as
    // write_light_image). Its own image, not a slot of the light pool: the lights of a frame and the palettes have different row counts, and a
    // pooled image is made again whenever the slot it lands in changes its rows.
    LightImage write_palette_image(int rows, const float* texels);
    // Frees the pooled light images from index `keep` on (the pool is restarted, none is in use).
    void trim_light_images(std::size_t keep);
    // The pool restarts only after an sg_commit(): sokol forbids writing a buffer once it was bound in the same
    // frame, and a second draw before the commit (editor screenshots, render_now) must not reuse a bound buffer.
    // Many draws without a commit (game.step and tests in the editor, which commits once per UI frame; FB-0005) end
    // the sokol frame here, outside any pass, so the pool stays bounded without rewriting a bound buffer.
    void begin_frame() {
        if ((++pipelineTick_ & 15u) == 0 && pipelines_.size() > pipelineCap_) sweep_pipelines();
        const bool full = transientUsed_ >= 16 || lightImagesUsed_ >= 16;
        if (!committed_ && full) sg_commit();
        if (committed_ || full) {
            // The light images the views of the last 256 restarts did not need (a view that had 4K of lights once) are freed.
            lightImagesPeak_ = std::max(lightImagesPeak_, lightImagesUsed_);
            if (++lightImagesRestarts_ >= 256) {
                trim_light_images(lightImagesPeak_);
                lightImagesPeak_ = 0;
                lightImagesRestarts_ = 0;
            }
            transientUsed_ = lightImagesUsed_ = 0;
        }
        committed_ = false;
    }
    void note_commit() { committed_ = true; }
    // GPU work was recorded outside a frame (a compute dispatch or buffer write): a read back must commit it first.
    void note_work() { committed_ = false; }
    // False while the frame drawn last has not been submitted to the GPU by an sg_commit().
    // The pacer's copy (begin_transient_writes) counts too, until a commit moves frame_ on.
    bool committed() const { return committed_ && pacerCopyFrame_ != frame_ + 1; }
    // The sokol frame being recorded: the sg_commit() calls made so far by anyone, the editor's included (a commit
    // listener counts them). A write-transient image is written once in it, before it is bound (Assets::video_texture).
    std::uint64_t frame() const { return frame_; }

    bool depth_zero_to_one() const { return zeroToOne_; }
    bool is_gl() const { return isGl_; }
    int sample_count() const { return sampleCount_; }
    bool shadows_supported() const { return shadowsSupported_; }

    sg_shader quad_shader_{}, quadPlainShader_{}, mesh_shader_{}, sky_shader_{}, shadow_shader_{}, blit_shader_{},
        blitKeepShader_{};
    sg_shader meshSkinShader_{}, shadowSkinShader_{};
    sg_shader meshLodShader_{}, meshSkinLodShader_{}, prepassLodShader_{},
        prepassSkinLodShader_{};  // made on the first fade
    sg_shader bloom_shaders_[int(BloomStage::Count)]{};
    sg_shader colorfilter_shader_{};
    sg_shader post_shader_{};
    sg_shader exposure_shaders_[int(ExposureStage::Count)]{};
    sg_shader ssao_shaders_[3]{};  // ao, blur, apply (SsaoStage::View uses the last)
    sg_shader prepassShader_{}, prepassSkinShader_{}, prepassViewShader_{};
    sg_shader sssShader_{}, sssSkinShader_{};
    sg_shader light_shader_{};

private:
    // The cache lookup of every getter: `key.format` is set from `format`, and the pass formats of `desc` (colour 0,
    // depth, sample count) are filled from it, so a getter cannot make a pipeline for a format other than its key's.
    sg_pipeline find_or_make(PipelineKey key, const TargetFormat& format, const sg_pipeline_desc& desc);
    void sweep_pipelines();

    static inline bool inPass_ = false;
    static inline TargetFormat passFormat_{};
    int sampleCount_ = 1;
    bool zeroToOne_ = false, isGl_ = true, shadowsSupported_ = false;
    int postReadyCalls_ = 0;
    int bloomState_ = 0;        // 0 = shaders not created yet, 1 = ready, -1 = creation failed
    int colorfilterState_ = 0;  // same meaning as bloomState_
    int lightState_ = 0;        // same meaning as bloomState_
    int postState_ = 0;         // same meaning as bloomState_
    int exposureState_ = 0;     // same meaning as bloomState_
    int ssaoState_ = 0;         // same meaning as bloomState_
    MaterialProgram prepassProgram_[2];
    MaterialProgram sssProgram_[2];
    int sssState_ = 0;          // same meaning as bloomState_ (the built-in subsurface programs)
    int prepassState_ = 0;      // same meaning as bloomState_ (the built-in prepass programs)
    int prepassViewState_ = 0;  // same meaning as bloomState_ (the debug view)
    sg_shader quadVelShader_{}, quadReactShader_{};
    int quadMotionState_ = 0;  // same meaning as bloomState_ (the quad motion programs)
    sg_pixel_format lightFormat_ = SG_PIXELFORMAT_NONE;
    sg_pixel_format sceneFormat_ = SG_PIXELFORMAT_RGBA8;  // see scene_format()
    struct SceneChain {
        sg_pixel_format formats[4]{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_RGBA8,
                                   SG_PIXELFORMAT_RGBA8};
        int count = 0;
        int at = 0;
    };
    SceneChain sceneChain_[2];  // [0] gamma, [1] linear
    bool linear_ = false, srgbTextures_ = false;
    void refresh_scene_format();
    sg_sampler samplers_[int(SamplerKind::Count)]{};
    sg_buffer quadIndices_{}, fsTriangle_{};
    struct PipelineEntry {
        sg_pipeline pipeline{};
        std::uint64_t lastUsed = 0;  // pipelineTick_ of the last ask
        bool warmed = false;         // made or asked for by the warm-up: never evicted
    };
    std::map<PipelineKey, PipelineEntry> pipelines_;
    bool layoutProbe_ = false;
    sg_vertex_layout_state probedLayout_{};
    std::unordered_set<std::uint32_t>
        failedComputePipelines_;      // shader ids whose compute pipeline the driver refused (one log)
    std::uint64_t pipelineTick_ = 0;  // begin_frame() calls (see "The pipeline cache")
    std::uint64_t pipelineHits_ = 0, pipelinesMade_ = 0, pipelinesEvicted_ = 0;
    bool warming_ = false;
    std::size_t pipelineCap_ = kPipelineCacheCap;
    std::uint64_t pipelineIdleFrames_ = kPipelineIdleFrames;
    struct Transient {
        sg_buffer buf{};
        std::size_t capacity = 0;
    };
    std::vector<Transient> transient_;
    std::size_t transientUsed_ = 0;
    struct LightImg {
        sg_image image{};
        sg_view view{};
        int rows = 0;
    };
    std::vector<LightImg> lightImages_;  // the pool of write_light_image, restarted with transient_
    LightImg paletteImage_;              // write_palette_image's, written once a frame
    LightImage fill_light_image(LightImg& l, int rows, const float* texels);
    std::size_t lightImagesUsed_ = 0;
    std::size_t lightImagesPeak_ = 0;  // the most images one restart used since the last trim
    std::uint32_t lightImagesRestarts_ = 0;
    bool committed_ = true;
    sg_buffer pacerSrc_{}, pacerDst_{};  // begin_transient_writes' empty copy (Metal)
    std::uint64_t pacedFrame_ = 0;       // frame_ + 1 of the frame it last made the command buffer for
    // frame_ + 1 of the frame whose command buffer its copy opened (not committed yet).
    std::uint64_t pacerCopyFrame_ = 0;
    bool pacerFailed_ = false;  // the pacer buffers could not be made: said once, not tried again
    std::uint64_t frame_ = 0;
    bool listening_ = false;  // count_commit is registered as a commit listener
    static void count_commit(void* gpu) { ++static_cast<Gpu*>(gpu)->frame_; }
};

// sg_make_image plus per-backend fixes (see image_gl.cpp). Every 2D image of the renderer is created through it.
sg_image make_image(const sg_image_desc& desc);
// The same for a cube image (SG_IMAGETYPE_CUBE): the OpenGL ES fix goes through the cube target.
sg_image make_cube_image(const sg_image_desc& desc);
// The same for an array image (SG_IMAGETYPE_ARRAY: the layers of a Terrain), through the array target.
sg_image make_array_image(const sg_image_desc& desc);

// One render target as the renderer makes them (renderer_targets.cpp): the colour image, the single-sample image an
// MSAA colour image resolves into, an optional depth image, and the views a pass and a later sampler need. The game
// target, the CameraView and render-target images, the 2D light buffer, the colour-filter image, the RGBA8 readback
// image, the shadow map and the bloom levels are all made by make_target and freed by destroy_target, so there is one
// place that knows how.
struct TargetDesc {
    const char* label =
        "target";  // the base of the labels of its images and views ("<label>-color", "<label>-depth"...)
    int width = 1, height = 1;
    sg_pixel_format colorFormat = SG_PIXELFORMAT_NONE;  // NONE: no colour image (a depth-only target)
    int samples = 1;  // > 1: the colour and depth images are multisampled and a single-sample resolve image is made too
    // The resolve image can also be drawn into as a colour attachment (resolveColorAtt): the bloom adds its glow to
    // the finished, resolved game image.
    bool resolveAsColor = false;
    bool texture = true;  // make `texView`, a texture view of the image that holds the picture (resolve, else colour)
    sg_pixel_format depthFormat = SG_PIXELFORMAT_NONE;  // NONE: no depth image
};
struct Target {
    sg_image color{}, resolve{}, depth{};
    sg_view colorAtt{};         // colour attachment of `color` (the multisampled image when samples > 1)
    sg_view resolveAtt{};       // MSAA: the resolve attachment of `resolve`
    sg_view resolveColorAtt{};  // MSAA and resolveAsColor: `resolve` as a colour attachment
    sg_view depthAtt{};
    sg_view texView{};  // a texture view of texture_image()
    int w = 0, h = 0, samples = 1;
    TargetFormat format{};  // what a pass drawing into the whole target writes (PassDesc::format)
    bool expectTexture = false, expectDepth = false;  // what make_target was asked for (valid() checks it was made)

    // The image that holds the finished picture: the resolve image of an MSAA target, else the colour image.
    sg_image texture_image() const { return resolve.id ? resolve : color; }
    // True when it was made (a colour image exists) and the GPU accepted every image and view that was made.
    bool valid() const;
};
// Makes the target (nothing is checked: a GPU that cannot make an image leaves it FAILED, see Target::valid()).
Target make_target(const TargetDesc& desc);
// Destroys the views, then the images, and resets `t` to empty. Safe on an empty or half-made target.
void destroy_target(Target& t);
// A pass that draws into `t` (its colour, the resolve attachment of an MSAA target, its depth) with the target's
// format. The caller sets what the pass does with the old contents: PassDesc's load and store actions default to
// DONTCARE.
PassDesc pass_into(const Target& t, const char* label);

// GPU time of the drawing of a frame and of each of its frame-graph passes (profiler). One timer query in flight per frame in
// a small ring; results are read a few frames later and never waited for. D3D11 (timestamp queries inside a disjoint query:
// one pair per pass) and GLCORE (GL_TIME_ELAPSED for the frame, glQueryCounter(GL_TIMESTAMP) pairs for the passes, because
// GL_TIME_ELAPSED cannot nest) measure; the other backends say why not (reason()). Backend specific: gpu_timer.cpp.
class GpuTimer {
public:
    // Passes timed per frame; the ones after that are drawn but not measured (their gpuMs stays -1). A frame is not
    // measured at all when the ring of frames in flight is full.
    static constexpr int kMaxTimedPasses = 64;
    // One timed pass of a frame: the name it was begun with and its GPU milliseconds.
    struct PassTime {
        std::string name;
        double ms = 0.0;
    };
    GpuTimer();
    ~GpuTimer();
    GpuTimer(const GpuTimer&) = delete;
    GpuTimer& operator=(const GpuTimer&) = delete;
    bool supported() const;      // false once it is known that this backend/device cannot time
    std::string reason() const;  // why not, when !supported()
    void begin();                // before the first pass of the frame
    void end();                  // after the last pass (closes a pass left open)
    // The passes of the frame between begin() and end(): timestamps right before and right after the pass's GPU work.
    // begin_pass closes a pass still open; both do nothing outside a measured frame.
    void begin_pass(const std::string& name);
    void end_pass();
    void poll(std::vector<double>& out);  // appends the milliseconds of every frame whose result is ready
    // The passes of the newest frame that poll() has resolved, in the order they ran; empty until one is. They are some
    // frames older than the frame being drawn.
    const std::vector<PassTime>& last_passes() const;
    // Forgets the results of the frames already timed (last_passes() is empty again) and drops the ones still in flight when
    // they arrive: called while the profiler is off, so that switching it on again never shows numbers from before.
    void forget();

private:
    struct State;
    std::unique_ptr<State> s_;
};

// GPU->CPU readback of an RGBA8 image (top row first). Backend specific.
bool readback_rgba8(sg_image image, int width, int height, std::vector<std::uint8_t>& out, std::string* error);
// GPU->CPU readback of `bytes` bytes of a storage buffer from `offset` (Compute::read). Waits for the GPU: the work
// recorded so far must have been committed (sg_commit) by the caller. Backend specific; false + `error` where the
// backend has no storage buffers.
bool readback_buffer(sg_buffer buffer, std::size_t offset, std::size_t bytes, std::vector<std::uint8_t>& out,
                     std::string* error);
// GPU->CPU readback of the rectangle (x, y, width, height) of a storage image (Compute::read_image): the pixels as the
// GPU holds them, `width * height * bytes_per_pixel` bytes, the rectangle's first row first (rows count from the row an
// imageStore at y = 0 writes), tightly packed (RGBA16F as halves). Only the rectangle is copied (a blit, a staging copy
// or glReadPixels of its size), so a small read of a large image never holds the whole image. Waits for the GPU: the
// work recorded so far must have been committed (sg_commit) by the caller. `format` is the image's own (RGBA8, RGBA16F,
// R32F, RGBA32F). False + `error` on a backend without storage images, or when the rectangle is outside the image.
bool readback_storage_image(sg_image image, sg_pixel_format format, int x, int y, int width, int height,
                            std::vector<std::uint8_t>& out, std::string* error);
// Whether a compute shader can imageLoad (not only imageStore) a storage image of `format` (RGBA8, RGBA16F, R32F,
// RGBA32F) on this GPU, the question behind `"access": "readWrite"`. sokol's `read` flag does not answer it: on
// Direct3D 11 it means a typed UAV exists, not a typed load (D3D11.0 hardware loads only R32_FLOAT/UINT/SINT), and on
// Metal the read-write texture tier decides (Tier 1: the 32-bit single-channel formats only). OpenGL 4.3 loads every
// format its shader declares with a layout qualifier. False + `why` (a sentence about this GPU) when it cannot.
bool storage_image_loadable(sg_pixel_format format, std::string* why);
// The same for an RGBA16F image, as floats (4 per pixel, top row first): what the HDR tests read (Renderer::Impl::read_floats).
bool readback_rgba16f(sg_image image, int width, int height, std::vector<float>& out, std::string* error);

// GPU->CPU readback of the start of a storage buffer WITHOUT waiting (the Hi-Z culling, renderer_hiz.cpp): a small ring of staging
// buffers. request() queues a copy of the first `bytes` bytes of `buffer` behind the work submitted so far and returns the slot it
// uses; poll() hands the bytes over once the GPU has finished the copy, and never blocks unless `wait` is set (a headless frame
// waits so its result does not depend on the GPU's speed). The work that wrote the buffer must have been committed (sg_commit)
// before request(): on Metal the copy is a blit on the queue after sokol's command buffer. Needs the GPU's storage buffers (no
// GLES3): `supported()` says so. Not thread safe: the render thread only.
// What a request costs the frame: GL a glFlush (the fence must be submitted to be signalled), D3D11 a Flush of the immediate context
// (the staging copy and its event query must be submitted), Metal one more command buffer committed behind sokol's. They are per request,
// so a frame with several cameras that use the depth pyramid flushes once per camera: the price of reading each camera's cells without
// waiting, bounded by the 8 cameras per frame that keep a pyramid (hiz.h).
class AsyncBufferRead {
public:
    static constexpr int kSlots = 4;
    AsyncBufferRead();
    ~AsyncBufferRead();
    AsyncBufferRead(const AsyncBufferRead&) = delete;
    AsyncBufferRead& operator=(const AsyncBufferRead&) = delete;
    static bool supported();
    // The slot, or -1: every slot is still in flight (error stays empty: ask again later), or the copy failed (error says why).
    int request(sg_buffer buffer, std::size_t bytes, std::string* error);
    // True when the slot's copy has finished: `out` holds its bytes and the slot is free again. False: not done yet (or the slot is
    // unused); with `wait` it returns after the GPU finished (bounded: a GPU that does not answer in seconds gives up, false).
    bool poll(int slot, std::vector<std::uint8_t>& out, bool wait);
    // Frees a slot without reading it (the copy may still be running; its staging buffer is reused only when it is done).
    void release(int slot);

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

// Debug draw storage.
struct DebugLine {
    Vec3 a, b;
    Color c;
    float thickness;
};
struct DebugRect {
    Rect r;
    Color c;
    bool filled;
};
struct DebugCircle {
    Vec2 center;
    float radius;
    Color c;
    bool filled;
};
struct DebugText {
    Vec2 pos;
    std::string text;
    Color c;
    float size;
};
struct DebugDrawData {
    std::vector<DebugLine> lines;
    std::vector<DebugRect> rects;
    std::vector<DebugCircle> circles;
    std::vector<DebugText> texts;
    bool empty() const { return lines.empty() && rects.empty() && circles.empty() && texts.empty(); }
};

inline std::uint32_t pack_color(const Color& c) { return c.to_rgba8(); }

}  // namespace fa::render

namespace fa {
struct DebugDraw::Impl : render::DebugDrawData {};
}  // namespace fa
