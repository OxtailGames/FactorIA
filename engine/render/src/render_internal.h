// Private types shared by the renderer's translation units.
#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "sokol_gfx.h"

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/video.h"
#include "fa/render/renderer.h"
#include "fa/scene/camera_geometry.h"
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
constexpr int kMaxLights =
    32;  // also the size of the light arrays in mesh.glsl (96 vec4s: within the WebGL2 minimum of 224)
constexpr int kMeshInstanceBytes = 64;  // one Mat4 per instance
// Skinning: a skinned part has a third vertex buffer (vertex buffer 2) of SkinVertex, and the draw uploads the joint
// palette as kMaxSkinJoints 3x4 matrices (three vec4 rows each = 192 vec4, which fits the 256 vec4 of vertex uniforms
// that GLES3 / WebGL2 guarantee next to the other uniforms). A model with more joints is drawn in bind pose.
constexpr int kMaxSkinJoints = 64;
struct SkinVertex {
    std::uint8_t joints[4];
    float weights[4];
};
static_assert(sizeof(SkinVertex) == 20, "SkinVertex must be 20 bytes");

// Light2D budget of one frame (docs/PERFORMANCE.md): the point lights are added up in a light buffer, one quad each, so the
// count is bounded by what the vertex stream and the fill rate can take, not by uniforms.
constexpr int kMaxLights2D = 256;
// Lit visuals with a normal map still shade per pixel in the fragment shader (the direction of every light matters there),
// with the first kDirectLights2D lights: the size of the light arrays in quad.glsl (51 vec4s, far below the WebGL2 / GLES3
// minimum of 224). The same loop shades every lit visual when the light buffer cannot be used (a perspective camera, or a
// GPU that can render to neither a half-float nor an 8-bit target).
constexpr int kDirectLights2D = 16;
// Point lights with castShadows that get a shadow row (one row of kShadowAngles distances in a data texture); the rest shine
// through walls.
constexpr int kMaxShadowLights2D = 32;
constexpr int kShadowAngles = 1024;

// One Light2D as the quad shader reads it. pos: xyz + w = radius (point, xyz = position with z the height) or -1
// (directional, xyz = unit vector towards the light); color: rgb * intensity, w = falloff exponent; extra: x = the row of
// the light's shadows in the shadow texture (-1 = none), y = 1 when the Light2D asked for shadows.
struct Light2DData {
    float pos[4];
    float color[4];
    float extra[4] = {-1.0f, 0.0f, 0.0f, 0.0f};
};

// One corner of a point light's quad in the light buffer pass (light.glsl): the same values at the four corners.
struct LightVertex {
    float corner[2];  // -1 or 1: where the corner lies from the light, in radii
    float pos[4];     // xy position, z height, w radius
    float color[4];   // rgb * intensity, w falloff
    float shadow[4];  // x = shadow row or -1
};
static_assert(sizeof(LightVertex) == 56, "LightVertex is 14 floats");

// ---------------------------------------------------------------------------
// GPU resources
// ---------------------------------------------------------------------------
// Shader programs of the Camera.bloom post-process (bloom.glsl).
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
    int skin = -1;       // index of the glTF skin that deforms it (-1 = not skinned)
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
    // glTF pbrMetallicRoughness factors, used instead of MeshRenderer.metallic / roughness when `hasPbr`.
    bool hasPbr = false;
    float metallic = 0.0f, roughness = 0.6f;
    Color emissiveFactor{0, 0, 0, 1};
    bool doubleSided = false;
    bool blended = false;
};

struct MeshAsset {
    std::string key;
    std::vector<SubMesh> parts;
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};
    bool placeholder = false;
    std::vector<std::string> untraced;  // as TextureAsset::untraced (its parts' textures are reported after it)
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
    TranscodedTexture transcoded;  // ktx2
};
struct PreparedTextureRef {  // one texture slot of a glTF material
    enum class Kind { None, Path, Image, Missing } kind = Kind::None;
    std::string path;         // Path: the project path of the image file
    std::string name;         // Image: the embedded image's name; Missing: the failure's key ("" = no failure recorded)
    Image image;              // Image
    std::string error, hint;  // Missing
};
struct PreparedPart {
    std::vector<MeshVertex> verts;
    std::vector<std::uint32_t> idx;
    SubMesh material;  // the material and bounds fields (no GPU handles, no texture pointers yet)
    PreparedTextureRef base, metalRough, normal, occlusion, emissive;
    std::vector<SkinVertex> skin;  // empty: not skinned
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
constexpr int kMaterialFirstView = 6, kMaterialFirstSampler = 2, kMaterialUbVertex = 4, kMaterialUbFragment = 5;

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
    kProgCount
};

struct MaterialParamDef {
    std::string name;
    int components = 1;  // 1..4
    float def[4]{0, 0, 0, 0};
};
struct MaterialTextureDef {
    std::string name;
    TextureAsset* defaultTex = nullptr;
    SamplerKind sampler = SamplerKind::Linear;
};

struct MaterialAsset {
    std::string path;     // the .material.json
    std::string snippet;  // its `shader` file (a change of it reloads the material)
    std::string lighting = "pbr", alphaMode = "opaque";
    bool doubleSided = false;
    std::vector<MaterialParamDef> params;      // in the order of the twin's "params" (the packing order)
    std::vector<MaterialTextureDef> textures;  // in the order of the twin's "textures" (views 6+i, samplers 2+i)
    MaterialProgram programs[kProgCount];
    bool ok = false;                         // false = drawn with the error material
    std::string error;                       // the last build error (kept while an older good build still draws)
    int generation = 0;                      // counts successful builds
    std::unordered_set<std::string> warned;  // params already complained about
};

// The dialect name of a sokol backend ("hlsl5", "glsl430"...); "" for an unsupported one.
std::string backend_dialect(sg_backend backend);

// The sg_shader_desc of a twin program (`programs.<name>` of factoria.shader/1) and the slots it declares in `slots` (its
// shader is not made). The desc points into `program`, which must outlive it.
Result<sg_shader_desc> material_shader_desc(const std::string& label, const Json& program, MaterialProgram& slots);
// Builds the shader of a twin program; on failure the Error says what the twin/driver rejected.
Result<MaterialProgram> make_material_program(const std::string& label, const Json& program);

// Packs the params of `m` (defaults overlaid by `overrides`, a MeshRenderer.materialParams object) into one vec4 each.
// A value of the wrong shape or an unknown name is warned about once per material and keeps the default.
void pack_material_params(MaterialAsset& m, const Json& overrides, float out[kMaxMaterialParams][4]);
// The texture bound as texture `i` of `m`: the override path in `overrides` (loaded by `assets`), else the default.
TextureAsset* material_texture(MaterialAsset& m, int i, const Json& overrides, Assets& assets);

// ---------------------------------------------------------------------------
// Batches (CPU side, before upload)
// ---------------------------------------------------------------------------
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
};

struct QuadBatch {
    std::uint32_t firstQuad = 0;  // in the final, sorted vertex stream
    std::uint32_t quadCount = 0;
    TextureAsset* tex = nullptr;
    SamplerKind smp = SamplerKind::Nearest;
    BlendMode blend = BlendMode::Alpha;
    Rect clip{};       // batches only merge with an equal clip
    bool lit = false;  // lit batches only merge with the same texture and normal map
    TextureAsset* normal = nullptr;
    // Only plain textured quads (kModeTextured, not lit, not BlendMode::Multiply): drawn with the lean quad_plain shader.
    // Merging never waits on it: a batch that takes in one other quad is drawn with the full shader.
    bool plain = true;
    // Only opaque BlendMode::Alpha items (QuadList::set_opaque): drawn without blending, the same pixels for less work on
    // software rasterizers. Batches only merge with an equal `opaque`.
    bool opaque = false;
};

// Collects quads for one render space, then sorts and flattens them.
class QuadList {
public:
    std::vector<Vertex2D> raw;
    std::vector<QuadItem> items;

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
    // Marks the item opened by begin_item() as flashing (feel.h): flatten() turns its quads into the shader's "flash" variant
    // (mode + 32), which draws the picture's alpha in `packedColor`'s rgb by `packedColor`'s alpha. Not for the SDF shape mode
    // (it uses color2 for its gradient: Shape2D mixes the colour on the CPU) nor glyphs.
    void set_flash(std::uint32_t packedColor) {
        cur_.flash = packedColor;
        cur_.plain = false;
    }
    void end_item();
    bool empty() const { return items.empty(); }
    // Sorts items (layer asc, secondary desc, seq asc) and appends the vertices in
    // draw order to `out`; returns merged batches referencing `out` (quad indices
    // relative to out's start + `baseQuad`).
    // As jobs when the list is big (render_jobs.h): the sort, then the copy of the vertices; the same result either way.
    void flatten(std::vector<Vertex2D>& out, std::vector<QuadBatch>& batches);
    void clear() {
        raw.clear();
        items.clear();
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

// Camera.bloom* (flat fields on Camera), already clamped: see sanitize_bloom() in bloom.h. The defaults here are
// the fallbacks for NaN values and equal the Camera component defaults.
struct BloomSettings {
    bool enabled = false;
    float threshold =
        0.7f;  // 0 .. 0.99 (Camera.bloom), 0 .. 20 (PostProcess): brightness (max of r, g, b) where the glow starts
    float intensity = 1.2f;   // 0 .. 10, multiplier of the glow added to the frame
    float radius = 20.0f;     // 1 .. 128 design pixels
    bool screenSpace = true;  // Camera.bloomScreenSpace: false = screen-space items are drawn after the bloom
    float knee =
        0.0f;  // 0 .. 1, PostProcess.bloomKnee: how softly the glow starts above the threshold (0 = the hard start of Camera.bloom)
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
    // The PostProcess stack of this camera (its own component plus the volumes it is inside, postprocess_resolve.h). Resolved every time
    // the camera is built; a camera without a PostProcess of its own gets one made of its Camera.bloom* and Camera.colorFilter fields.
    // Null when the world has no PostProcess and the camera no legacy bloom or filter field: the usual case costs one pointer, not a copy.
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
};

// Texture/mesh/font caches keyed by project-relative path.
class Assets {
public:
    explicit Assets(Gpu& gpu);
    ~Assets();
    // The LUT of a .cube file, loaded on first use and cached (a failed load too: one logged error, null from then on, until the file
    // changes on disk and reload() forgets it). Null for an empty path, a missing file or a malformed one.
    const LutAsset* lut(const std::string& path);
    TextureAsset* texture(const std::string& path);                // never null (placeholder on failure)
    TextureAsset* white();                                         // 1x1 white
    TextureAsset* placeholder() { return placeholderTex_.get(); }  // the missing-texture checker
    // Answers the render-target ids ("target:<name>", Camera.renderTarget): the resolver returns the live texture of the target or
    // null when no camera renders into that name (texture() then answers the checker and logs why, once per name).
    using TargetResolver = std::function<TextureAsset*(const std::string& name)>;
    void set_target_resolver(TargetResolver r) { targetResolver_ = std::move(r); }
    // True while Renderer::render() runs: only then does a target id nobody renders into count as a failure (a query made
    // before the first frame, such as an entity's bounds, only gets the checker).
    void set_drawing(bool on) { drawing_ = on; }
    static bool is_target_id(const std::string& path) { return path.rfind("target:", 0) == 0; }
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
    // How a material gets its twin (empty = read `<path>.<dialect>.shader` through fa::fs). Kept across clear().
    void set_shader_compiler(ShaderCompiler compiler) { shaderCompiler_ = std::move(compiler); }
    bool has_loaded(const std::string& path) const;
    void reload(const std::string& path);
    void clear();
    Json report() const;
    std::size_t texture_bytes() const;  // GPU memory of the loaded textures (packed ones are counted in their atlas)
    // Used by fonts for font-file failures.
    void note_failure(const std::string& kind, const std::string& path, const std::string& message,
                      const std::string& hint);
    bool failure_logged(const std::string& kind, const std::string& path) const;
    int texture_count() const { return int(textures_.size()); }

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
    std::string missing_hint(const std::string& path, std::string_view ext) const;

    Gpu& gpu_;
    std::unordered_map<std::string, std::unique_ptr<TextureAsset>> textures_;
    std::unordered_map<std::string, std::unique_ptr<LutAsset>> luts_;
    void destroy_lut(LutAsset& l);
    std::unordered_map<std::string, std::unique_ptr<MeshAsset>> meshes_;
    std::vector<std::unique_ptr<TextureAsset>> anonymous_;  // glTF embedded images
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
    bool drawing_ = false;
    std::unique_ptr<MeshAsset> placeholderMesh_;
    std::vector<Failure> failures_;
    std::unordered_map<std::string, std::string> meshSources_;  // mesh key -> source file (for reload)
    std::map<std::string, ProceduralMesh> procedural_;          // "mesh:N" -> its GPU copy
    const MeshStore* meshStore_ = nullptr;
    std::uint64_t meshStoreSerial_ = 0;
    std::unordered_map<std::string, std::unique_ptr<MaterialAsset>> materials_;
    ShaderCompiler shaderCompiler_;
};

bool build_primitive(const std::string& name, std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx);

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
    sg_pipeline quad_pipeline(const TargetFormat& format, bool depthTest, bool lines,
                              BlendMode blend = BlendMode::Alpha, bool plain = false, bool opaque = false);
    sg_pipeline quad_pipeline(bool depthTest, bool lines, BlendMode blend = BlendMode::Alpha, bool plain = false,
                              bool opaque = false) {
        return quad_pipeline(scene_target_format(), depthTest, lines, blend, plain, opaque);
    }
    // Vertex buffer 0 = MeshVertex, buffer 1 = one model matrix per instance. A skinned variant adds a `skinned` argument,
    // a PipelineKey bit and a second per-vertex buffer for joints and weights.
    // `shader` = a program of a custom material (the pipeline is keyed by it); default = the built-in mesh program.
    sg_pipeline mesh_pipeline(const TargetFormat& format, bool blended, bool doubleSided, bool skinned = false,
                              sg_shader shader = {});
    sg_pipeline mesh_pipeline(bool blended, bool doubleSided, bool skinned = false, sg_shader shader = {}) {
        return mesh_pipeline(scene_target_format(), blended, doubleSided, skinned, shader);
    }
    sg_pipeline sky_pipeline(const TargetFormat& format);
    sg_pipeline sky_pipeline() { return sky_pipeline(scene_target_format()); }

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
    TargetFormat prepass_target_format() const { return {prepass_color_format(), SG_PIXELFORMAT_DEPTH, 1}; }
    bool prepass_ready();
    // The slots (uniform blocks, views, samplers) the built-in prepass program declares, for a draw that binds only those; after prepass_ready().
    const MaterialProgram& prepass_program(bool skinned) const { return prepassProgram_[skinned ? 1 : 0]; }
    // `shader` = a program of a custom material (its prepass or prepass_skin), default = the built-in one. The vertex layout is the
    // main program's (every attribute), the culling the main pass's: `doubleSided` as for mesh_pipeline. Invalid when the built-in
    // shader cannot be made.
    sg_pipeline prepass_pipeline(const TargetFormat& format, bool doubleSided, bool skinned = false,
                                 sg_shader shader = {});
    sg_pipeline prepass_pipeline(bool doubleSided, bool skinned = false, sg_shader shader = {}) {
        return prepass_pipeline(prepass_target_format(), doubleSided, skinned, shader);
    }
    // The debug view of the prepass (prepass_view.glsl): a full-screen triangle that draws it as a picture into `format` (the game target's).
    bool prepass_view_ready();
    sg_pipeline prepass_view_pipeline(const TargetFormat& format);

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
    sg_pipeline shadow_pipeline(const TargetFormat& format, bool skinned = false, sg_shader shader = {},
                                bool fullVertex = false);
    sg_pipeline shadow_pipeline(bool skinned = false, sg_shader shader = {}, bool fullVertex = false) {
        return shadow_pipeline(shadow_target_format(), skinned, shader, fullVertex);
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
    // cannot be created, in which case Camera.bloom is skipped instead of failing the whole renderer.
    bool bloom_ready();
    // sampleCount > 1: the composite stage can also add its glow straight into the multisampled game target.
    sg_pipeline bloom_pipeline(BloomStage stage, const TargetFormat& format);
    sg_pipeline bloom_pipeline(BloomStage stage, int sampleCount = 1) {
        return bloom_pipeline(stage, TargetFormat{sceneFormat_, SG_PIXELFORMAT_NONE, sampleCount});
    }
    // Camera.colorFilter: one program (colorfilter.glsl), created on first use like the bloom ones; false + one logged
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
    static const TargetFormat& pass_format() {
        return passFormat_;
    }  // of the pass begun last; meaningful while in_pass()

    sg_buffer quad_index_buffer() const { return quadIndices_; }
    sg_buffer fullscreen_triangle() const { return fsTriangle_; }
    // A write-transient vertex buffer of at least `bytes`, valid for this frame.
    sg_buffer acquire_transient(std::size_t bytes);
    // The pool restarts only after an sg_commit(): sokol forbids writing a buffer once it was bound in the same
    // frame, and a second draw before the commit (editor screenshots, render_now) must not reuse a bound buffer.
    // Many draws without a commit (game.step and tests in the editor, which commits once per UI frame; FB-0005) end
    // the sokol frame here, outside any pass, so the pool stays bounded without rewriting a bound buffer.
    void begin_frame() {
        if ((++pipelineTick_ & 15u) == 0 && pipelines_.size() > pipelineCap_) sweep_pipelines();
        if (!committed_ && transientUsed_ >= 16) sg_commit();
        if (committed_ || transientUsed_ >= 16) transientUsed_ = 0;
        committed_ = false;
    }
    void note_commit() { committed_ = true; }
    // False while the frame drawn last has not been submitted to the GPU by an sg_commit().
    bool committed() const { return committed_; }
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
    sg_shader bloom_shaders_[int(BloomStage::Count)]{};
    sg_shader colorfilter_shader_{};
    sg_shader post_shader_{};
    sg_shader exposure_shaders_[int(ExposureStage::Count)]{};
    sg_shader ssao_shaders_[3]{};  // ao, blur, apply (SsaoStage::View uses the last)
    sg_shader prepassShader_{}, prepassSkinShader_{}, prepassViewShader_{};
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
    int prepassState_ = 0;      // same meaning as bloomState_ (the built-in prepass programs)
    int prepassViewState_ = 0;  // same meaning as bloomState_ (the debug view)
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
    bool committed_ = true;
    std::uint64_t frame_ = 0;
    bool listening_ = false;  // count_commit is registered as a commit listener
    static void count_commit(void* gpu) { ++static_cast<Gpu*>(gpu)->frame_; }
};

// sg_make_image plus per-backend fixes (see image_gl.cpp). Every 2D image of the renderer is created through it.
sg_image make_image(const sg_image_desc& desc);

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
    // The resolve image can also be drawn into as a colour attachment (resolveColorAtt): Camera.bloom adds its glow to
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
// The same for an RGBA16F image, as floats (4 per pixel, top row first): what the HDR tests read (Renderer::Impl::read_floats).
bool readback_rgba16f(sg_image image, int width, int height, std::vector<float>& out, std::string* error);

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
