// The light atlas (M73.1b; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The light atlas"): ONE RGBA16F image the mesh fragment
// shader reads through the slot fa_light_atlas (view 25, the linear clamp sampler 10). It holds, in this order of the layout:
//   - the LTC tables of the area lights (ltc_tables.h) in a reserved block at the top left: the matrix (a, b, c, d of M^-1) at
//     (0, 0) and the BRDF integrals (magnitude, fresnel, 0, 0) at (64, 0), each 64 x 64 texels;
//   - a tile of kCookieTile x kCookieTile for every light cookie (a texture of the project resampled; rgb premultiplied by alpha, the
//     tile has a 1 texel border that wraps, so a directional cookie tiles without a seam);
//   - a cube of kCookieCubeW x kCookieCubeH for every point-light cookie: six face tiles of kCookieTile in 3 columns and 2 rows
//     (face f, in the order of cube_face_basis, at ((f % 3) * kCookieTile, (f / 3) * kCookieTile)), baked from an equirectangular
//     picture, each tile with a border that continues into the neighbour faces (so the filter has no seam on a cube edge);
//   - a tile of kIesTileW x kIesTileH for every IES profile (value = candela / the peak, in r, g and b; ies.h; a 1 texel border that
//     wraps horizontally and clamps vertically).
// The slots of the fragment stage are all used (16 units), so the tables share the image with the cookies instead of taking a unit.
//
// Two halves. The CPU half (layout_light_atlas, assemble_light_atlas, the bake_* functions) is free of any GPU call, deterministic
// (the layout depends only on the SET of tiles, sorted by kind and path, never on the order they were asked for) and tested without a
// window. LightAtlas wraps it with the keys the lights asked for, the baked tiles, the GPU image and its retire.
#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/math.h"
#include "fa/render/ies.h"
#include "sokol_gfx.h"

namespace fa::render {

inline constexpr int kLightAtlasWidth = 1024;
inline constexpr int kLightAtlasMaxHeight = 4096;  // 32 MB of RGBA16F: about 60 cookies
inline constexpr int kLtcTile = 64;                // the LTC tables: matrix at (0, 0), BRDF at (kLtcTile, 0)
inline constexpr int kCookieTile = 256;            // texels per side of a cookie tile, border included
inline constexpr int kCookieInner = kCookieTile - 2;
inline constexpr int kCookieCubeW = 3 * kCookieTile, kCookieCubeH = 2 * kCookieTile;
inline constexpr int kIesTileW = kIesBakeWidth + 2, kIesTileH = kIesBakeHeight + 2;
inline constexpr int kMaxCookieSide =
    4096;  // a cookie image larger than this on a side is refused before it is decoded

// Cookie: a spot light's or a directional light's picture (one tile). Ies: a profile. CookieCube: a point light's picture, an
// equirectangular image baked to the six faces of a cube (the same file as a Cookie key is another key).
enum class LightAtlasKind : std::uint8_t { Cookie = 0, Ies = 1, CookieCube = 2 };

struct LightAtlasKey {
    LightAtlasKind kind = LightAtlasKind::Cookie;
    std::string path;  // a normalized project path
    bool operator<(const LightAtlasKey& o) const { return kind != o.kind ? kind < o.kind : path < o.path; }
    bool operator==(const LightAtlasKey& o) const { return kind == o.kind && path == o.path; }
};

struct LightAtlasRect {
    int x = 0, y = 0, w = 0, h = 0;  // texels
};

struct LightAtlasLayout {
    int height = 0;  // texels, a power of two (the width is kLightAtlasWidth)
    std::vector<std::pair<LightAtlasKey, LightAtlasRect>> entries;  // in key order
    int dropped =
        0;  // tiles that did not fit under kLightAtlasMaxHeight (they get no rect: the light is drawn without it)
    const LightAtlasRect* find(const LightAtlasKey& k) const;
};

// The block of the LTC tables.
inline constexpr LightAtlasRect ltc_matrix_rect() { return {0, 0, kLtcTile, kLtcTile}; }
inline constexpr LightAtlasRect ltc_brdf_rect() { return {kLtcTile, 0, kLtcTile, kLtcTile}; }

// The layout of a set of tiles: the LTC block first, then shelves (rows) of tiles, the tallest first, ties by kind and path. Duplicate
// keys count once; the same set gives the same layout in any order.
LightAtlasLayout layout_light_atlas(std::vector<LightAtlasKey> keys);

// float <-> IEEE binary16 with signs (the LTC matrix has negative entries): round to nearest even, saturating, subnormals kept.
std::uint16_t light_atlas_half(float f);
float light_atlas_half_to_float(std::uint16_t h);

// The tile of an image: kCookieTile x kCookieTile RGBA16F (4 halves per texel), the image resampled (a box filter when it is larger,
// bilinear when smaller) into the inner kCookieInner texels, rgb times alpha, the border wrapped. Row 0 is the top of the image.
std::vector<std::uint16_t> bake_cookie_tile(const Image& image);
// The six faces of a point-light cookie from an equirectangular picture (kCookieCubeW x kCookieCubeH RGBA16F, rgb times alpha). The
// picture is seen from inside the cube in the light's own frame: its centre is straight ahead (the light's forward axis, -Z), the
// left and right edges meet behind the light, the top is up (+Y) and its right is the light's +X. Face tiles follow cube_face_basis
// and are bilinear samples of the picture (wrapping around, clamped at the poles).
std::vector<std::uint16_t> bake_cookie_cube_tile(const Image& image);
// The direction (not normalized, in the light's frame) of the point (s, t) of face `face`, both -1..1 across the face, t up: the
// face's forward plus s times its right (forward x up) plus t times its up (cube_face_basis).
Vec3 cookie_cube_dir(int face, float s, float t);
// The tile of an IES profile: kIesTileW x kIesTileH RGBA16F, value in rgb and 1 in alpha (ies_bake).
std::vector<std::uint16_t> bake_ies_tile(const IesProfile& profile);
// A tile of ones: what a cookie or profile that cannot be loaded leaves (the light is drawn as if it had none).
std::vector<std::uint16_t> bake_white_tile(int w, int h);
// The LTC tables written into an atlas image of `width` texels per row.
void bake_ltc_tables(std::vector<std::uint16_t>& atlas, int width);

// The whole image (width kLightAtlasWidth, layout.height rows, RGBA16F): the LTC block, and each entry's tile from `tiles` (an entry
// without a tile is left white).
std::vector<std::uint16_t> assemble_light_atlas(const LightAtlasLayout& layout,
                                                const std::map<LightAtlasKey, std::vector<std::uint16_t>>& tiles);

// What the loader answers for one key.
struct LightAtlasSource {
    bool ok = false;
    Image cookie;
    IesProfile ies;
    std::string error, hint;  // when !ok: what is wrong and how to fix it (the renderer logs it once)
};
// Reads and decodes a cookie image (any texture format of the project) or parses an .ies file through fa::fs.
LightAtlasSource load_light_atlas_source(const LightAtlasKey& key);

class LightAtlas {
public:
    using Loader = std::function<LightAtlasSource(const LightAtlasKey&)>;
    using FailureFn = std::function<void(const LightAtlasKey&, const std::string& message, const std::string& hint)>;
    ~LightAtlas() { destroy(); }

    // A light uses the LTC tables (an area light) or a cookie or profile: the next sync makes the image. Cheap to call every frame.
    void request_ltc() {
        if (!needLtc_) dirty_ = true;
        needLtc_ = true;
    }
    void request(LightAtlasKind kind, const std::string& path);
    // Ends one collection of the lights of a view: a key nobody asked for in the last kKeyIdleTicks collections (one
    // collect_lights call per view: several per frame with several cameras or probe captures, so not a frame count) is
    // forgotten (its tile is not baked again and the next sync lays the atlas out without it), so a project that went
    // through many cookies does not keep them all. A count of calls, never a time.
    void end_requests();
    static constexpr std::uint64_t kKeyIdleTicks = 600;
    std::size_t key_count() const { return keys_.size(); }
    // A project file changed on disk (hot reload): its tile is baked again at the next sync. Returns true when the atlas holds it.
    bool invalidate(const std::string& path);
    void invalidate_all();

    // Makes (or makes again) the image when something was requested or changed. False when there is no image (nothing requested, the
    // GPU cannot filter RGBA16F, or the GPU refused it): the lights are then drawn without the atlas. A failed tile is reported to
    // `onFailure` once and left white.
    bool sync(const Loader& load, const FailureFn& onFailure);
    // The image to bind, or an empty view while there is none.
    sg_view view() const { return view_; }
    bool ready() const { return view_.id != 0; }
    // The rect of a tile in texels, null when the key was not requested or did not fit.
    const LightAtlasRect* rect(LightAtlasKind kind, const std::string& path) const;
    int width() const { return kLightAtlasWidth; }
    int height() const { return layout_.height; }
    std::size_t bytes() const { return view_.id ? std::size_t(kLightAtlasWidth) * std::size_t(layout_.height) * 8 : 0; }
    int dropped() const { return layout_.dropped; }
    int bakes() const { return bakes_; }  // images made so far (tests)
    // Frees what an earlier sync replaced: call once a frame, when the graph of the frame before has run.
    void free_retired();
    void destroy();

private:
    struct Retired {
        sg_image image;
        sg_view view;
    };
    std::set<LightAtlasKey> keys_;
    std::map<LightAtlasKey, std::uint64_t> lastUse_;  // the tick_ of the last request of each key
    std::uint64_t tick_ = 0;
    std::map<LightAtlasKey, std::vector<std::uint16_t>> tiles_;
    LightAtlasLayout layout_;
    std::vector<Retired> retired_;
    sg_image image_{};
    sg_view view_{};
    bool needLtc_ = false, dirty_ = false, unsupported_ = false;
    int bakes_ = 0;
};

}  // namespace fa::render
