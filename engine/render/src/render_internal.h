// Private types shared by the renderer's translation units.
#pragma once

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
#include "fa/render/renderer.h"
#include "fa/scene/world.h"

namespace fa::render {

// ---------------------------------------------------------------------------
// Vertex formats
// ---------------------------------------------------------------------------
// Everything 2D (sprites, tiles, glyphs, shapes, particles, debug lines) uses
// one 32-byte vertex; `mode` selects the fragment path (see shaders/quad.glsl).
enum QuadMode : int { kModeTextured = 0, kModeCircle = 1, kModeRing = 2, kModeSoft = 3, kModeGlyph = 4 };

struct Vertex2D {
    float x, y, z;
    float u, v;
    std::uint32_t color;  // 0xAABBGGRR
    float mode, aux;
};
static_assert(sizeof(Vertex2D) == 32, "Vertex2D must be 32 bytes");

struct MeshVertex {
    float px, py, pz;
    float nx, ny, nz;
    float u, v;
};
static_assert(sizeof(MeshVertex) == 32, "MeshVertex must be 32 bytes");

constexpr int kMaxQuadsPerDraw = 16384;  // 16-bit indices
constexpr int kMaxLights = 8;

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
    int width = 0, height = 0;
    bool placeholder = false;  // magenta/black checker standing in for a missing/broken file
};

struct SubMesh {
    sg_buffer vb{};
    sg_buffer ib{};
    int vertexCount = 0;
    int indexCount = 0;
    Vec3 bmin{0, 0, 0}, bmax{0, 0, 0};
    Color baseColor{1, 1, 1, 1};
    TextureAsset* texture = nullptr;  // glTF base color texture (owned by Assets)
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
    bool valid = false;           // false: font has no such glyph
    float u0 = 0, v0 = 0, u1 = 0, v1 = 0;
    float x0 = 0, y0 = 0, x1 = 0, y1 = 0;  // pixel offsets from the pen position on the baseline, y DOWN
    float advance = 0;            // pixels
    bool empty = false;           // whitespace: no bitmap
};

struct FontMetrics {
    float ascent = 0, descent = 0, lineGap = 0;  // pixels at the requested size (descent negative)
    float lineHeight() const { return ascent - descent + lineGap; }
};

struct TextQuad {
    float x0, y0, x1, y1;  // local units, y UP, relative to the entity origin after pivot
    float u0, v0, u1, v1;
};

struct TextLayout {
    std::vector<TextQuad> quads;
    Vec2 size{0, 0};  // width/height of the laid out box in local units
};

// ---------------------------------------------------------------------------
// Pipelines
// ---------------------------------------------------------------------------
struct PipelineKey {
    std::uint32_t bits = 0;
    bool operator<(const PipelineKey& o) const { return bits < o.bits; }
};

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
};

struct QuadBatch {
    std::uint32_t firstQuad = 0;  // in the final, sorted vertex stream
    std::uint32_t quadCount = 0;
    TextureAsset* tex = nullptr;
    SamplerKind smp = SamplerKind::Nearest;
    BlendMode blend = BlendMode::Alpha;
};

// Collects quads for one render space, then sorts and flattens them.
class QuadList {
public:
    std::vector<Vertex2D> raw;
    std::vector<QuadItem> items;

    void begin_item(int layer, float secondary, TextureAsset* tex, SamplerKind smp, BlendMode blend = BlendMode::Alpha);
    void quad(const Vertex2D& a, const Vertex2D& b, const Vertex2D& c, const Vertex2D& d);  // a,b,c,d = TL,BL,BR,TR style loop
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
};

// Texture/mesh/font caches keyed by project-relative path.
class Assets {
public:
    explicit Assets(Gpu& gpu);
    ~Assets();
    TextureAsset* texture(const std::string& path);       // never null (placeholder on failure)
    TextureAsset* white();                                 // 1x1 white
    MeshAsset* mesh(const std::string& name);             // never null (cube placeholder on failure)
    bool has_loaded(const std::string& path) const;
    void reload(const std::string& path);
    void clear();
    Json report() const;
    // Used by fonts for font-file failures.
    void note_failure(const std::string& kind, const std::string& path, const std::string& message, const std::string& hint);
    bool failure_logged(const std::string& kind, const std::string& path) const;
    int texture_count() const { return int(textures_.size()); }

    // Makes a texture from CPU pixels (RGBA8) with an optional mip chain.
    TextureAsset* make_texture(const std::string& name, const Image& img, bool mips);

private:
    friend class MeshLoader;
    struct Failure { std::string kind, path, message, hint; };
    TextureAsset* load_texture(const std::string& path);
    void destroy_texture(TextureAsset& t);
    void upload_texture(TextureAsset& t, const Image& img, bool mips);
    MeshAsset* load_mesh(const std::string& name);
    void destroy_mesh(MeshAsset& m);
    std::string missing_hint(const std::string& path, std::string_view ext) const;

    Gpu& gpu_;
    std::unordered_map<std::string, std::unique_ptr<TextureAsset>> textures_;
    std::unordered_map<std::string, std::unique_ptr<MeshAsset>> meshes_;
    std::vector<std::unique_ptr<TextureAsset>> anonymous_;  // glTF embedded images
    std::unique_ptr<TextureAsset> white_;
    std::unique_ptr<TextureAsset> placeholderTex_;
    std::unique_ptr<MeshAsset> placeholderMesh_;
    std::vector<Failure> failures_;
    std::unordered_map<std::string, std::string> meshSources_;  // mesh key -> source file (for reload)
};

bool build_primitive(const std::string& name, std::vector<MeshVertex>& v, std::vector<std::uint32_t>& idx);

// Font loading, glyph atlas, text layout.
struct FontFace;
class Fonts {
public:
    Fonts(Gpu& gpu, Assets& assets);
    ~Fonts();
    // font: "" / "builtin" / "builtin:pixel" / project path to a .ttf
    FontFace* face(const std::string& font);
    TextLayout layout(const Text& t, float rasterPx, float unitsPerPx);
    // Uploads the atlas if new glyphs were rasterized. Call after layout, before drawing.
    void sync();
    TextureAsset* atlas() { return &atlasTex_; }
    int glyph_count_last() const { return glyphsLaidOut_; }
    void begin_frame() { glyphsLaidOut_ = 0; }
    void clear();
    Json report() const;

private:
    struct Impl;
    Gpu& gpu_;
    Assets& assets_;
    std::unique_ptr<Impl> impl_;
    TextureAsset atlasTex_;
    int glyphsLaidOut_ = 0;
};

// Pipelines, samplers, shaders, static buffers, transient buffer pool.
class Gpu {
public:
    Gpu() = default;
    bool init(int sampleCount, std::string* error);
    void shutdown();

    sg_sampler sampler(SamplerKind k) const { return samplers_[int(k)]; }
    sg_pipeline quad_pipeline(bool depthTest, bool lines, BlendMode blend = BlendMode::Alpha);
    sg_pipeline mesh_pipeline(bool blended, bool doubleSided);
    sg_pipeline sky_pipeline();
    sg_pipeline shadow_pipeline();
    sg_pipeline blit_pipeline(sg_pixel_format colorFormat, sg_pixel_format depthFormat, int sampleCount);
    // Bloom post-processing. The shaders are created on first use; returns false (and logs once) when they
    // cannot be created, in which case Camera.bloom is skipped instead of failing the whole renderer.
    bool bloom_ready();
    // sampleCount > 1: the composite stage can also add its glow straight into the multisampled game target.
    sg_pipeline bloom_pipeline(BloomStage stage, int sampleCount = 1);

    sg_buffer quad_index_buffer() const { return quadIndices_; }
    sg_buffer fullscreen_triangle() const { return fsTriangle_; }
    // A write-transient vertex buffer of at least `bytes`, valid for this frame.
    sg_buffer acquire_transient(std::size_t bytes);
    // The pool restarts only after an sg_commit(): sokol forbids writing a buffer once it was bound in the same
    // frame, and a second draw before the commit (editor screenshots, render_now) must not reuse a bound buffer.
    // ponytail: the cap assumes a commit happened when a caller never reports one (editor); it just bounds the pool.
    void begin_frame() {
        if (committed_ || transientUsed_ >= 16) transientUsed_ = 0;
        committed_ = false;
    }
    void note_commit() { committed_ = true; }

    bool depth_zero_to_one() const { return zeroToOne_; }
    bool is_gl() const { return isGl_; }
    int sample_count() const { return sampleCount_; }
    bool shadows_supported() const { return shadowsSupported_; }

    sg_shader quad_shader_{}, mesh_shader_{}, sky_shader_{}, shadow_shader_{}, blit_shader_{};
    sg_shader bloom_shaders_[int(BloomStage::Count)]{};

private:
        sg_pipeline find_or_make(PipelineKey key, const sg_pipeline_desc& desc);

    int sampleCount_ = 1;
    bool zeroToOne_ = false, isGl_ = true, shadowsSupported_ = false;
    int bloomState_ = 0;  // 0 = shaders not created yet, 1 = ready, -1 = creation failed
    sg_sampler samplers_[int(SamplerKind::Count)]{};
    sg_buffer quadIndices_{}, fsTriangle_{};
    std::map<PipelineKey, sg_pipeline> pipelines_;
    struct Transient { sg_buffer buf{}; std::size_t capacity = 0; };
    std::vector<Transient> transient_;
    std::size_t transientUsed_ = 0;
    bool committed_ = true;
};

// sg_make_image plus per-backend fixes (see image_gl.cpp). Every 2D image of the renderer is created through it.
sg_image make_image(const sg_image_desc& desc);

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
