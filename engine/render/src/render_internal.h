// Private types shared by the renderer's translation units.
#pragma once

#include <algorithm>
#include <cstdint>
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
#include "fa/scene/rich_text.h"
#include "fa/scene/world.h"

namespace fa::render {

// ---------------------------------------------------------------------------
// Vertex formats
// ---------------------------------------------------------------------------
// Everything 2D (sprites, tiles, glyphs, shapes, particles, debug lines) uses
// one 32-byte vertex; `mode` selects the fragment path (see shaders/quad.glsl).
// kModeLit (+1 for a left-handed normal-map frame) is a textured quad shaded by the 2D lights; `aux` is then the angle of
// the picture's right axis in the world (radians). See set_lit() and shaders/quad.glsl.
enum QuadMode : int { kModeTextured = 0, kModeCircle = 1, kModeRing = 2, kModeSoft = 3, kModeGlyph = 4, kModeLit = 5 };

struct Vertex2D {
    float x, y, z;
    float u, v;
    std::uint32_t color;  // 0xAABBGGRR
    float mode, aux;
};
static_assert(sizeof(Vertex2D) == 32, "Vertex2D must be 32 bytes");

// Vertex buffer 0 of every mesh pipeline. Per-instance data (the model matrix) is vertex buffer 1; skinning will add
// joint indices and weights as a second per-vertex buffer (see Gpu::mesh_pipeline), leaving this struct alone.
struct MeshVertex {
    float px, py, pz;
    float nx, ny, nz;
    float u, v;
    float tx = 0, ty = 0, tz = 0, tw = 1;  // tangent (xyz) and handedness (w = +1 / -1): bitangent = cross(normal, tangent) * w
};
static_assert(sizeof(MeshVertex) == 48, "MeshVertex must be 48 bytes");

constexpr int kMaxQuadsPerDraw = 16384;  // 16-bit indices
constexpr int kMaxLights = 32;  // also the size of the light arrays in mesh.glsl (96 vec4s: within the WebGL2 minimum of 224)
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

// LinearClamp: bilinear, clamp to edge, no mipmaps (post-processing).
enum class SamplerKind : std::uint8_t { Nearest, Linear, LinearRepeat, NearestRepeat, LinearClamp, Count };

struct TextureAsset {
    std::string path;
    sg_image image{};
    sg_view view{};
    int width = 0, height = 0;  // pixels of the original file: what regions, sprite sizes and scripts work with
    bool placeholder = false;   // magenta/black checker standing in for a missing/broken file
    sg_pixel_format format = SG_PIXELFORMAT_RGBA8;  // what the GPU holds (compressed when the file is a KTX2 twin)
    std::size_t bytes = 0;                           // GPU memory of all mip levels
    // Packed into an atlas by an export: the atlas holds this texture at (atlasX, atlasY) and image/view stay empty.
    TextureAsset* atlas = nullptr;
    int atlasX = 0, atlasY = 0;

    sg_view gpu_view() const { return atlas ? atlas->view : view; }
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
const char* pixel_format_name(sg_pixel_format format);  // "RGBA8", "BC7", "ASTC_4x4", "ETC2_RGBA8"

struct SubMesh {
    sg_buffer vb{};
    sg_buffer skinVb{};               // SkinVertex per vertex when the part belongs to a skinned glTF node; else id 0
    int skin = -1;                    // index of the glTF skin that deforms it (-1 = not skinned)
    sg_buffer ib{};
    int vertexCount = 0;
    int indexCount = 0;
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};
    std::string materialName;         // glTF material name ("" = none): the key of MeshRenderer.materialColors
    Color baseColor{1, 1, 1, 1};
    TextureAsset* texture = nullptr;  // glTF base color texture (owned by Assets)
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
};

// Fonts ---------------------------------------------------------------------
struct GlyphInfo {
    float u0 = 0, v0 = 0, u1 = 0, v1 = 0;
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;  // pixel offsets from the pen position on the baseline, y DOWN
    bool empty = false;           // whitespace or a missing character: no bitmap
};

struct FontMetrics {
    float ascent = 0, descent = 0, lineGap = 0;  // pixels at the requested size (descent negative)
    float lineHeight() const { return ascent - descent + lineGap; }
};

struct TextQuad {
    float x0, y0, x1, y1;  // local units, y UP, relative to the entity origin after pivot
    float u0, v0, u1, v1;
    std::uint16_t color = 0;  // rich text: 0 = the Text's colour, k = palette[k - 1] of the layout
};

// A picture of a rich text ([icon:name]): the rectangle it fills, in the units of TextQuad.
struct IconQuad {
    float x0, y0, x1, y1;
    int def;  // index into TextLayout::iconDefs
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
struct PipelineKey {
    std::uint32_t bits = 0;
    std::uint32_t shader = 0;  // sg_shader id of a custom material program (0 = the built-in one)
    bool operator<(const PipelineKey& o) const { return bits != o.bits ? bits < o.bits : shader < o.shader; }
};

// ---------------------------------------------------------------------------
// Custom materials (MeshRenderer.material, docs/design/CUSTOM_SHADERS.md)
// ---------------------------------------------------------------------------
class Assets;
constexpr int kMaxMaterialParams = 16, kMaxMaterialTextures = 4;  // each a vec4 of the fa_material block (fa/tooling/shaders.h kMaterialMaxParams)
constexpr int kMaterialFirstView = 6, kMaterialFirstSampler = 2, kMaterialUbVertex = 4, kMaterialUbFragment = 5;

// One program of a twin (mesh, mesh_skin, shadow, shadow_skin) and what its reflection declares: a draw binds and applies
// only those slots (sokol rejects a binding the shader does not declare, and a declared uniform block left unapplied).
struct MaterialProgram {
    sg_shader shader{};                  // id 0 = the material has no such program
    std::uint32_t ubMask = 0, viewMask = 0, samplerMask = 0;  // bit n = slot n is declared
    std::uint32_t ubSize[SG_MAX_UNIFORMBLOCK_BINDSLOTS]{};   // bytes of each declared uniform block
    bool has_ub(int slot) const { return (ubMask >> slot) & 1u; }
};
enum MaterialProgramId : int { kProgMesh, kProgMeshSkin, kProgShadow, kProgShadowSkin, kProgCount };

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
    bool ok = false;      // false = drawn with the error material
    std::string error;    // the last build error (kept while an older good build still draws)
    int generation = 0;   // counts successful builds
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
    Rect clip{};  // screen-space scissor rectangle in target pixels; w <= 0 = none (ScrollList content)
    bool lit = false;                 // shaded by the 2D lights (kModeLit quads)
    TextureAsset* normal = nullptr;   // lit: the normal map laid out like `tex`; null = a flat surface
    bool plain = true;                // every quad is kModeTextured (QuadList::quad clears it)
    bool opaque = false;              // QuadList::set_opaque(): the quads hide what is under them
};

struct QuadBatch {
    std::uint32_t firstQuad = 0;  // in the final, sorted vertex stream
    std::uint32_t quadCount = 0;
    TextureAsset* tex = nullptr;
    SamplerKind smp = SamplerKind::Nearest;
    BlendMode blend = BlendMode::Alpha;
    Rect clip{};  // batches only merge with an equal clip
    bool lit = false;                // lit batches only merge with the same texture and normal map
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
    void quad(const Vertex2D& a, const Vertex2D& b, const Vertex2D& c, const Vertex2D& d);  // a,b,c,d = TL,BL,BR,TR style loop
    // Marks the item opened by begin_item() as lit: its quads are kModeLit and `normal` (may be null) is the normal map.
    void set_lit(TextureAsset* normal) { cur_.lit = true; cur_.normal = normal; }
    // Marks the item opened by begin_item() as opaque: every pixel its quads cover is replaced, at full alpha (an opaque
    // picture with an opaque tint, such as a Video's). It is drawn without blending when its blend mode is Alpha.
    void set_opaque() { cur_.opaque = true; }
    void end_item();
    bool empty() const { return items.empty(); }
    // Sorts items (layer asc, secondary desc, seq asc) and appends the vertices in
    // draw order to `out`; returns merged batches referencing `out` (quad indices
    // relative to out's start + `baseQuad`).
    void flatten(std::vector<Vertex2D>& out, std::vector<QuadBatch>& batches);
    void clear() { raw.clear(); items.clear(); open_ = false; }

private:
    bool open_ = false;
    QuadItem cur_;
    std::uint32_t seq_ = 0;
};

// ---------------------------------------------------------------------------
// Subsystems
// ---------------------------------------------------------------------------
class Gpu;
class Assets;
class Fonts;

// Camera.bloom* (flat fields on Camera), already clamped: see sanitize_bloom() in bloom.h. The defaults here are
// the fallbacks for NaN values and equal the Camera component defaults.
struct BloomSettings {
    bool enabled = false;
    float threshold = 0.7f;   // 0 .. 0.99, brightness (max of r, g, b) where the glow starts
    float intensity = 1.2f;   // 0 .. 10, multiplier of the glow added to the frame
    float radius = 20.0f;     // 1 .. 128 design pixels
    bool screenSpace = true;  // Camera.bloomScreenSpace: false = screen-space items are drawn after the bloom
};

struct CameraInfo {
    Entity entity = kNullEntity;            // the Camera entity (null for the default camera of a world without one)
    int depth = 0;                          // Camera.depth
    // Camera.viewport after sanitizing: [x, y, w, h] as fractions of the target, top-left origin, +Y down. proj maps the
    // view onto THIS rectangle (its aspect is the rectangle's), so ndc -1..1 is the viewport, not the whole target.
    Rect viewport{0, 0, 1, 1};
    bool fullViewport() const { return viewport.x == 0.0f && viewport.y == 0.0f && viewport.w == 1.0f && viewport.h == 1.0f; }
    Mat4 view, proj, viewProj, invViewProj;
    Vec3 position{0, 0, 0};
    bool perspective = false;
    bool fromEntity = false;
    float fov = 60.0f;
    float halfH = 360.0f, halfW = 640.0f;   // orthographic half extents (world units)
    float pixelsPerUnit = 1.0f;             // ortho: target pixels per world unit
    Rect visible{};                         // orthographic view rectangle in world units
    Vec3 right{1, 0, 0}, up{0, 1, 0}, forward{0, 0, -1};
    Color clearColor{0.08f, 0.08f, 0.12f, 1};
    bool clear = true;
    BloomSettings bloom;  // Camera.bloom* after clamping to the supported ranges
    int colorFilter = 0;  // Camera.colorFilter as an int (0 none, 1 greyscale, 2 highContrast, 3 protanopia, 4 deuteranopia, 5 tritanopia)
};

// Texture/mesh/font caches keyed by project-relative path.
class Assets {
public:
    explicit Assets(Gpu& gpu);
    ~Assets();
    TextureAsset* texture(const std::string& path);       // never null (placeholder on failure)
    TextureAsset* white();                                 // 1x1 white
    MeshAsset* mesh(const std::string& name);             // never null (cube placeholder on failure)
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
    void note_failure(const std::string& kind, const std::string& path, const std::string& message, const std::string& hint);
    bool failure_logged(const std::string& kind, const std::string& path) const;
    int texture_count() const { return int(textures_.size()); }

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
    struct Failure { std::string kind, path, message, hint; };
    TextureAsset* load_texture(const std::string& path);
    void destroy_texture(TextureAsset& t);
    void upload_texture(TextureAsset& t, const Image& img, bool mips);
    bool upload_ktx2(TextureAsset& t, const std::vector<std::uint8_t>& file, std::string& error);
    void use_placeholder(TextureAsset& t);
    MeshAsset* load_mesh(const std::string& name);
    void destroy_mesh(MeshAsset& m);
    void build_material(MaterialAsset& m);
    Result<void> build_material_checked(MaterialAsset& m);
    std::string missing_hint(const std::string& path, std::string_view ext) const;

    Gpu& gpu_;
    std::unordered_map<std::string, std::unique_ptr<TextureAsset>> textures_;
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
    std::unique_ptr<MeshAsset> placeholderMesh_;
    std::vector<Failure> failures_;
    std::unordered_map<std::string, std::string> meshSources_;  // mesh key -> source file (for reload)
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
    // Uploads the atlas if new glyphs were rasterized. Call after layout, before drawing.
    void sync();
    TextureAsset* atlas() { return &atlasTex_; }
    void clear();
    Json report() const;

private:
    FontFace* load(const std::string& font);  // the face of that file even when it failed to load (ok == false)
    GlyphInfo glyph(FontFace* face, int px, std::uint32_t gid, bool synthBold = false);
    FontFace* bold_face(FontFace* regular);
    void warn_missing_glyphs(FontFace* f, const std::string& text, const std::vector<char32_t>& missing);
    void warn_markup(const std::string& source, const MarkupText& m);

    struct Impl;
    Gpu& gpu_;
    Assets& assets_;
    std::unique_ptr<Impl> impl_;
    TextureAsset atlasTex_;
};

// Pipelines, samplers, shaders, static buffers, transient buffer pool.
class Gpu {
public:
    Gpu() = default;
    bool init(int sampleCount, std::string* error);
    void shutdown();

    sg_sampler sampler(SamplerKind k) const { return samplers_[int(k)]; }
    // `plain` = the lean shader of quad.glsl (quad_plain) for a batch of plain textured quads (QuadBatch::plain).
    // `opaque` = blending off (QuadBatch::opaque).
    sg_pipeline quad_pipeline(bool depthTest, bool lines, BlendMode blend = BlendMode::Alpha, bool plain = false,
                              bool opaque = false);
    // Vertex buffer 0 = MeshVertex, buffer 1 = one model matrix per instance. A skinned variant adds a `skinned` argument,
    // a PipelineKey bit and a second per-vertex buffer for joints and weights.
    // `shader` = a program of a custom material (the pipeline is keyed by it); default = the built-in mesh program.
    sg_pipeline mesh_pipeline(bool blended, bool doubleSided, bool skinned = false, sg_shader shader = {});
    sg_pipeline sky_pipeline();
    // `fullVertex` (custom shadow programs: vertex() or alphaMode "clip") also reads normal, texcoord0 and tangent from
    // vertex buffer 0, at locations 5, 6, 7 (skinned: 7, 8, 9) as shadow_vs of mesh_common.glsl declares them.
    sg_pipeline shadow_pipeline(bool skinned = false, sg_shader shader = {}, bool fullVertex = false);
    // Destroys a custom material program together with the pipelines made from it.
    void destroy_shader(sg_shader shader);
    sg_pipeline blit_pipeline(sg_pixel_format colorFormat, sg_pixel_format depthFormat, int sampleCount);
    // Bloom post-processing. The shaders are created on first use; returns false (and logs once) when they
    // cannot be created, in which case Camera.bloom is skipped instead of failing the whole renderer.
    bool bloom_ready();
    // sampleCount > 1: the composite stage can also add its glow straight into the multisampled game target.
    sg_pipeline bloom_pipeline(BloomStage stage, int sampleCount = 1);
    // Camera.colorFilter: one program (colorfilter.glsl), created on first use like the bloom ones; false + one logged
    // error when it cannot be created, and the game is then drawn unfiltered.
    bool colorfilter_ready();
    sg_pipeline colorfilter_pipeline();

    // The 2D light buffer (light.glsl). Its shader is created on first use, like the bloom ones; false + one logged error
    // when it cannot be created, and lit visuals then shade with the per-pixel path (the first kDirectLights2D lights).
    bool light_ready();
    // The format the light buffer is drawn in: RGBA16F where the GPU renders to it with blending and filtering, else RGBA8
    // (half the range, see light_range()), else NONE: no light buffer. The environment variable FA_LIGHT_FORMAT (rgba16f,
    // rgba8 or none) narrows the choice to that one, to test a path on a GPU that would pick another.
    sg_pixel_format light_format() const { return lightFormat_; }
    // How much light one texel of the light buffer holds: 1 in RGBA16F, 2 in RGBA8 (written as light / 2).
    float light_range() const { return lightFormat_ == SG_PIXELFORMAT_RGBA8 ? 2.0f : 1.0f; }
    sg_pipeline light_pipeline();

    sg_buffer quad_index_buffer() const { return quadIndices_; }
    sg_buffer fullscreen_triangle() const { return fsTriangle_; }
    // A write-transient vertex buffer of at least `bytes`, valid for this frame.
    sg_buffer acquire_transient(std::size_t bytes);
    // The pool restarts only after an sg_commit(): sokol forbids writing a buffer once it was bound in the same
    // frame, and a second draw before the commit (editor screenshots, render_now) must not reuse a bound buffer.
    // Many draws without a commit (game.step and tests in the editor, which commits once per UI frame; FB-0005) end
    // the sokol frame here, outside any pass, so the pool stays bounded without rewriting a bound buffer.
    void begin_frame() {
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

    sg_shader quad_shader_{}, quadPlainShader_{}, mesh_shader_{}, sky_shader_{}, shadow_shader_{}, blit_shader_{};
    sg_shader meshSkinShader_{}, shadowSkinShader_{};
    sg_shader bloom_shaders_[int(BloomStage::Count)]{};
    sg_shader colorfilter_shader_{};
    sg_shader light_shader_{};

private:
        sg_pipeline find_or_make(PipelineKey key, const sg_pipeline_desc& desc);

    int sampleCount_ = 1;
    bool zeroToOne_ = false, isGl_ = true, shadowsSupported_ = false;
    int bloomState_ = 0;  // 0 = shaders not created yet, 1 = ready, -1 = creation failed
    int colorfilterState_ = 0;  // same meaning as bloomState_
    int lightState_ = 0;        // same meaning as bloomState_
    sg_pixel_format lightFormat_ = SG_PIXELFORMAT_NONE;
    sg_sampler samplers_[int(SamplerKind::Count)]{};
    sg_buffer quadIndices_{}, fsTriangle_{};
    std::map<PipelineKey, sg_pipeline> pipelines_;
    struct Transient { sg_buffer buf{}; std::size_t capacity = 0; };
    std::vector<Transient> transient_;
    std::size_t transientUsed_ = 0;
    bool committed_ = true;
    std::uint64_t frame_ = 0;
    bool listening_ = false;  // count_commit is registered as a commit listener
    static void count_commit(void* gpu) { ++static_cast<Gpu*>(gpu)->frame_; }
};

// sg_make_image plus per-backend fixes (see image_gl.cpp). Every 2D image of the renderer is created through it.
sg_image make_image(const sg_image_desc& desc);

// GPU time of the drawing of a frame (profiler). One timer query in flight per frame in a small ring; results are read a few
// frames later and never waited for. D3D11 (timestamp queries) and GLCORE (GL_TIME_ELAPSED) measure; the other backends
// say why not (reason()). Backend specific: gpu_timer.cpp.
class GpuTimer {
public:
    GpuTimer();
    ~GpuTimer();
    GpuTimer(const GpuTimer&) = delete;
    GpuTimer& operator=(const GpuTimer&) = delete;
    bool supported() const;         // false once it is known that this backend/device cannot time
    std::string reason() const;     // why not, when !supported()
    void begin();                   // before the first pass of the frame
    void end();                     // after the last pass
    void poll(std::vector<double>& out);  // appends the milliseconds of every frame whose result is ready
private:
    struct State;
    std::unique_ptr<State> s_;
};

// GPU->CPU readback of an RGBA8 image (top row first). Backend specific.
bool readback_rgba8(sg_image image, int width, int height, std::vector<std::uint8_t>& out, std::string* error);

// Debug draw storage.
struct DebugLine { Vec3 a, b; Color c; float thickness; };
struct DebugRect { Rect r; Color c; bool filled; };
struct DebugCircle { Vec2 center; float radius; Color c; bool filled; };
struct DebugText { Vec2 pos; std::string text; Color c; float size; };
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
}
