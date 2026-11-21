#include "light_atlas.h"

#include <algorithm>
#include <bit>
#include <cmath>
#include <cstring>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "local_shadows.h"
#include "ltc_tables.h"
#include "render_internal.h"

namespace fa::render {

const LightAtlasRect* LightAtlasLayout::find(const LightAtlasKey& k) const {
    auto it = std::lower_bound(entries.begin(), entries.end(), k,
                               [](const auto& e, const LightAtlasKey& key) { return e.first < key; });
    return it != entries.end() && it->first == k ? &it->second : nullptr;
}

namespace {

LightAtlasRect tile_size(LightAtlasKind kind) {
    if (kind == LightAtlasKind::CookieCube) return LightAtlasRect{0, 0, kCookieCubeW, kCookieCubeH};
    return kind == LightAtlasKind::Cookie ? LightAtlasRect{0, 0, kCookieTile, kCookieTile}
                                          : LightAtlasRect{0, 0, kIesTileW, kIesTileH};
}

int pow2_at_least(int v) {
    int p = 1;
    while (p < v) p *= 2;
    return p;
}

}  // namespace

LightAtlasLayout layout_light_atlas(std::vector<LightAtlasKey> keys) {
    std::sort(keys.begin(), keys.end());
    keys.erase(std::unique(keys.begin(), keys.end()), keys.end());
    // The tallest first (a shelf takes tiles up to its own height), ties by key: a stable order that does not depend on the
    // order the lights asked in.
    std::stable_sort(keys.begin(), keys.end(), [](const LightAtlasKey& a, const LightAtlasKey& b) {
        return tile_size(a.kind).h > tile_size(b.kind).h;
    });
    struct Shelf {
        int y, h, x;
    };
    std::vector<Shelf> shelves;
    shelves.push_back({0, kLtcTile, 2 * kLtcTile});  // the LTC block takes the start of the first shelf
    int used = kLtcTile;
    LightAtlasLayout out;
    for (const LightAtlasKey& k : keys) {
        const LightAtlasRect s = tile_size(k.kind);
        Shelf* at = nullptr;
        for (Shelf& sh : shelves)
            if (s.h <= sh.h && sh.x + s.w <= kLightAtlasWidth) {
                at = &sh;
                break;
            }
        if (!at) {
            if (used + s.h > kLightAtlasMaxHeight) {
                ++out.dropped;
                continue;
            }
            shelves.push_back({used, s.h, 0});
            used += s.h;
            at = &shelves.back();
        }
        out.entries.push_back({k, LightAtlasRect{at->x, at->y, s.w, s.h}});
        at->x += s.w;
    }
    std::sort(out.entries.begin(), out.entries.end(), [](const auto& a, const auto& b) { return a.first < b.first; });
    out.height = pow2_at_least(used);
    return out;
}

std::uint16_t light_atlas_half(float f) {
    const std::uint32_t b = std::bit_cast<std::uint32_t>(f);
    const std::uint16_t sign = std::uint16_t((b >> 16) & 0x8000u);
    const std::uint32_t expo = (b >> 23) & 0xffu;
    std::uint32_t mant = b & 0x7fffffu;
    if (expo == 0xffu) return std::uint16_t(sign | (mant ? 0x7e00u : 0x7bffu));  // NaN stays NaN, infinity saturates
    int e = int(expo) - 127 + 15;
    if (e >= 31) return std::uint16_t(sign | 0x7bffu);  // saturate at the largest finite half
    if (e <= 0) {
        if (e < -10) return sign;  // below half the smallest subnormal
        mant |= 0x800000u;
        const int shift = 14 - e;
        std::uint32_t h = mant >> shift;
        const std::uint32_t rem = mant & ((1u << shift) - 1u), half = 1u << (shift - 1);
        if (rem > half || (rem == half && (h & 1u))) ++h;
        return std::uint16_t(sign | h);
    }
    std::uint32_t h = (std::uint32_t(e) << 10) | (mant >> 13);
    const std::uint32_t rem = mant & 0x1fffu;
    if (rem > 0x1000u || (rem == 0x1000u && (h & 1u))) ++h;  // a carry into the exponent is right
    if (h >= 0x7c00u) h = 0x7bffu;
    return std::uint16_t(sign | h);
}

float light_atlas_half_to_float(std::uint16_t h) {
    const int sign = (h & 0x8000u) ? -1 : 1;
    const int e = (h >> 10) & 0x1f;
    const int m = h & 0x3ff;
    if (e == 0) return float(sign) * std::ldexp(float(m), -24);
    if (e == 31) return m ? 0.0f : float(sign) * 65504.0f;
    return float(sign) * std::ldexp(float(1024 + m), e - 25);
}

namespace {

// The inner kCookieInner x kCookieInner pixels of a cookie as floats (rgb already times alpha, alpha), by a box filter over the
// footprint of each texel when the image is larger and bilinear when it is smaller.
std::vector<float> resample_cookie(const Image& img) {
    const int n = kCookieInner;
    std::vector<float> out(std::size_t(n) * std::size_t(n) * 4, 0.0f);
    const int sw = img.width, sh = img.height;
    auto px = [&](int x, int y, float* rgba) {
        x = std::clamp(x, 0, sw - 1);
        y = std::clamp(y, 0, sh - 1);
        const std::uint8_t* p = &img.rgba[(std::size_t(y) * std::size_t(sw) + std::size_t(x)) * 4];
        const float a = float(p[3]) / 255.0f;
        rgba[0] = float(p[0]) / 255.0f * a;
        rgba[1] = float(p[1]) / 255.0f * a;
        rgba[2] = float(p[2]) / 255.0f * a;
        rgba[3] = a;
    };
    const double fx = double(sw) / double(n), fy = double(sh) / double(n);
    for (int j = 0; j < n; ++j)
        for (int i = 0; i < n; ++i) {
            float acc[4] = {0, 0, 0, 0};
            if (fx > 1.0 || fy > 1.0) {
                const double x0 = double(i) * fx, x1 = double(i + 1) * fx, y0 = double(j) * fy, y1 = double(j + 1) * fy;
                double wsum = 0.0;
                for (int sy = int(std::floor(y0)); sy < int(std::ceil(y1)) && sy < sh; ++sy) {
                    const double wy = std::min(double(sy + 1), y1) - std::max(double(sy), y0);
                    for (int sx = int(std::floor(x0)); sx < int(std::ceil(x1)) && sx < sw; ++sx) {
                        const double w = wy * (std::min(double(sx + 1), x1) - std::max(double(sx), x0));
                        float c[4];
                        px(sx, sy, c);
                        for (int k = 0; k < 4; ++k) acc[k] += float(w) * c[k];
                        wsum += w;
                    }
                }
                if (wsum > 0.0)
                    for (float& v : acc) v = float(double(v) / wsum);
            } else {
                const double sxf = (double(i) + 0.5) * fx - 0.5, syf = (double(j) + 0.5) * fy - 0.5;
                const int x0 = int(std::floor(sxf)), y0 = int(std::floor(syf));
                const float tx = float(sxf - double(x0)), ty = float(syf - double(y0));
                float c00[4], c10[4], c01[4], c11[4];
                px(x0, y0, c00);
                px(x0 + 1, y0, c10);
                px(x0, y0 + 1, c01);
                px(x0 + 1, y0 + 1, c11);
                for (int k = 0; k < 4; ++k) {
                    const float top = c00[k] + (c10[k] - c00[k]) * tx, bot = c01[k] + (c11[k] - c01[k]) * tx;
                    acc[k] = top + (bot - top) * ty;
                }
            }
            for (int k = 0; k < 4; ++k)
                out[(std::size_t(j) * std::size_t(n) + std::size_t(i)) * 4 + std::size_t(k)] = acc[k];
        }
    return out;
}

}  // namespace

std::vector<std::uint16_t> bake_cookie_tile(const Image& image) {
    const int n = kCookieInner, t = kCookieTile;
    std::vector<std::uint16_t> tile(std::size_t(t) * std::size_t(t) * 4, 0);
    if (image.empty()) return bake_white_tile(t, t);
    const std::vector<float> inner = resample_cookie(image);
    for (int y = 0; y < t; ++y)
        for (int x = 0; x < t; ++x) {
            const int sx = (x - 1 + n) % n, sy = (y - 1 + n) % n;  // the border wraps
            for (int k = 0; k < 4; ++k)
                tile[(std::size_t(y) * std::size_t(t) + std::size_t(x)) * 4 + std::size_t(k)] =
                    light_atlas_half(inner[(std::size_t(sy) * std::size_t(n) + std::size_t(sx)) * 4 + std::size_t(k)]);
        }
    return tile;
}

Vec3 cookie_cube_dir(int face, float s, float t) {
    const CubeFace b = cube_face_basis(face);
    const Vec3 right = cross(b.forward, b.up);
    return b.forward + right * s + b.up * t;
}

std::vector<std::uint16_t> bake_cookie_cube_tile(const Image& image) {
    const int n = kCookieInner, t = kCookieTile;
    std::vector<std::uint16_t> out(std::size_t(kCookieCubeW) * std::size_t(kCookieCubeH) * 4, 0);
    if (image.empty()) return bake_white_tile(kCookieCubeW, kCookieCubeH);
    const int sw = image.width, sh = image.height;
    auto px = [&](int x, int y, float* rgba) {
        x = ((x % sw) + sw) % sw;  // the picture wraps around the light
        y = std::clamp(y, 0, sh - 1);
        const std::uint8_t* p = &image.rgba[(std::size_t(y) * std::size_t(sw) + std::size_t(x)) * 4];
        const float a = float(p[3]) / 255.0f;
        rgba[0] = float(p[0]) / 255.0f * a;
        rgba[1] = float(p[1]) / 255.0f * a;
        rgba[2] = float(p[2]) / 255.0f * a;
        rgba[3] = a;
    };
    constexpr double kPiD = 3.14159265358979323846;
    for (int f = 0; f < kCubeFaces; ++f) {
        const int ox = (f % 3) * t, oy = (f / 3) * t;
        for (int y = 0; y < t; ++y)
            for (int x = 0; x < t; ++x) {
                // The tile's border (one texel) lies outside the face by one texel step, on the same plane: it continues into the
                // neighbour face, so a bilinear read at the edge blends the two.
                const double s = (double(x - 1) + 0.5) / double(n) * 2.0 - 1.0;
                const double tt = 1.0 - (double(y - 1) + 0.5) / double(n) * 2.0;
                const Vec3 d = cookie_cube_dir(f, float(s), float(tt));
                const double len = std::sqrt(double(d.x) * d.x + double(d.y) * d.y + double(d.z) * d.z);
                const double lon = std::atan2(double(d.x), -double(d.z));  // 0 straight ahead (-Z), growing toward +X
                const double lat = std::asin(std::clamp(double(d.y) / len, -1.0, 1.0));
                const double sx = (0.5 + lon / (2.0 * kPiD)) * double(sw) - 0.5;
                const double sy = (0.5 - lat / kPiD) * double(sh) - 0.5;
                const int x0 = int(std::floor(sx)), y0 = int(std::floor(sy));
                const float fx = float(sx - double(x0)), fy = float(sy - double(y0));
                float c00[4], c10[4], c01[4], c11[4];
                px(x0, y0, c00);
                px(x0 + 1, y0, c10);
                px(x0, y0 + 1, c01);
                px(x0 + 1, y0 + 1, c11);
                for (int k = 0; k < 4; ++k) {
                    const float top = c00[k] + (c10[k] - c00[k]) * fx, bot = c01[k] + (c11[k] - c01[k]) * fx;
                    out[(std::size_t(oy + y) * std::size_t(kCookieCubeW) + std::size_t(ox + x)) * 4 + std::size_t(k)] =
                        light_atlas_half(top + (bot - top) * fy);
                }
            }
    }
    return out;
}

std::vector<std::uint16_t> bake_ies_tile(const IesProfile& profile) {
    const std::vector<float> v = ies_bake(profile);
    const int w = kIesBakeWidth, h = kIesBakeHeight;
    std::vector<std::uint16_t> tile(std::size_t(kIesTileW) * std::size_t(kIesTileH) * 4, 0);
    for (int y = 0; y < kIesTileH; ++y)
        for (int x = 0; x < kIesTileW; ++x) {
            const int sx = (x - 1 + w) % w;              // horizontal: all around, the border wraps
            const int sy = std::clamp(y - 1, 0, h - 1);  // vertical: the nadir and the zenith are the ends
            const std::uint16_t value = light_atlas_half(v[std::size_t(sy) * std::size_t(w) + std::size_t(sx)]);
            std::uint16_t* p = &tile[(std::size_t(y) * std::size_t(kIesTileW) + std::size_t(x)) * 4];
            p[0] = p[1] = p[2] = value;
            p[3] = light_atlas_half(1.0f);
        }
    return tile;
}

std::vector<std::uint16_t> bake_white_tile(int w, int h) {
    return std::vector<std::uint16_t>(std::size_t(w) * std::size_t(h) * 4, light_atlas_half(1.0f));
}

void bake_ltc_tables(std::vector<std::uint16_t>& atlas, int width) {
    const int n = ltc_tables::kSize;
    static_assert(ltc_tables::kSize == kLtcTile, "the LTC block of the atlas is one table");
    for (int y = 0; y < n; ++y)
        for (int x = 0; x < n; ++x) {
            const std::size_t cell = std::size_t(y) * std::size_t(n) + std::size_t(x);
            std::uint16_t* m = &atlas[(std::size_t(y) * std::size_t(width) + std::size_t(x)) * 4];
            std::uint16_t* b = &atlas[(std::size_t(y) * std::size_t(width) + std::size_t(kLtcTile + x)) * 4];
            for (int k = 0; k < 4; ++k) m[k] = light_atlas_half(ltc_tables::kMatrix[cell * 4 + std::size_t(k)]);
            b[0] = light_atlas_half(ltc_tables::kBrdf[cell * 2 + 0]);
            b[1] = light_atlas_half(ltc_tables::kBrdf[cell * 2 + 1]);
            b[2] = 0;
            b[3] = light_atlas_half(1.0f);
        }
}

std::vector<std::uint16_t> assemble_light_atlas(const LightAtlasLayout& layout,
                                                const std::map<LightAtlasKey, std::vector<std::uint16_t>>& tiles) {
    const int width = kLightAtlasWidth;
    std::vector<std::uint16_t> atlas(std::size_t(width) * std::size_t(layout.height) * 4, 0);
    bake_ltc_tables(atlas, width);
    for (const auto& [key, rect] : layout.entries) {
        auto it = tiles.find(key);
        const std::vector<std::uint16_t> white =
            it == tiles.end() ? bake_white_tile(rect.w, rect.h) : std::vector<std::uint16_t>();
        const std::vector<std::uint16_t>& tile = it == tiles.end() ? white : it->second;
        if (tile.size() != std::size_t(rect.w) * std::size_t(rect.h) * 4) continue;
        for (int y = 0; y < rect.h; ++y)
            std::memcpy(&atlas[(std::size_t(rect.y + y) * std::size_t(width) + std::size_t(rect.x)) * 4],
                        &tile[std::size_t(y) * std::size_t(rect.w) * 4],
                        std::size_t(rect.w) * 4 * sizeof(std::uint16_t));
    }
    return atlas;
}

LightAtlasSource load_light_atlas_source(const LightAtlasKey& key) {
    LightAtlasSource s;
    const bool isCookie = key.kind != LightAtlasKind::Ies;
    const char* what = isCookie ? "light cookie" : "IES profile";
    if (!fs::exists(key.path)) {
        s.error = std::format("{} '{}' does not exist", what, key.path);
        s.hint = isCookie
                     ? "Set Light.cookie to a texture in the project (a PNG or JPG; import one with assets.import)."
                     : "Set Light.ies to an .ies file in the project (import one with assets.import).";
        return s;
    }
    if (key.kind == LightAtlasKind::Ies) {
        const std::int64_t bytes = fs::file_size(key.path);
        if (bytes > std::int64_t(kIesMaxFileBytes)) {
            s.error = std::format("IES profile '{}' is {} MB, over the {} MB an .ies file may have", key.path,
                                  bytes >> 20, kIesMaxFileBytes >> 20);
            s.hint = "Export the profile with a coarser angle step (5 degrees is plenty).";
            return s;
        }
        auto text = fs::read_text(key.path);
        if (!text) {
            s.error = std::format("IES profile '{}' could not be read: {}", key.path, text.error().message);
            s.hint = text.error().hint;
            return s;
        }
        auto parsed = parse_ies(*text, key.path);
        if (!parsed) {
            s.error = "IES profile " + parsed.error().message;
            s.hint = parsed.error().hint;
            return s;
        }
        s.ies = std::move(*parsed);
        s.ok = true;
        return s;
    }
    auto bytes = fs::read_bytes(key.path);
    if (!bytes) {
        s.error = std::format("light cookie '{}' could not be read: {}", key.path, bytes.error().message);
        s.hint = bytes.error().hint;
        return s;
    }
    auto size = image_size(bytes->data(), bytes->size());
    if (!size) {
        s.error =
            std::format("light cookie '{}' is not an image the engine decodes: {}", key.path, size.error().message);
        s.hint = "Use a PNG or JPG texture for Light.cookie.";
        return s;
    }
    if (size->width > kMaxCookieSide || size->height > kMaxCookieSide) {
        s.error = std::format("light cookie '{}' is {}x{} pixels, over the {} a cookie may have on a side", key.path,
                              size->width, size->height, kMaxCookieSide);
        s.hint =
            "A cookie is drawn into a 254 x 254 tile of the light atlas: resize the texture to 512 or 1024 pixels.";
        return s;
    }
    auto img = decode_image(bytes->data(), bytes->size());
    if (!img) {
        s.error = std::format("light cookie '{}' could not be decoded: {}", key.path, img.error().message);
        s.hint = img.error().hint;
        return s;
    }
    s.cookie = std::move(*img);
    s.ok = true;
    return s;
}

void LightAtlas::request(LightAtlasKind kind, const std::string& path) {
    if (path.empty()) return;
    LightAtlasKey k{kind, path};
    if (keys_.insert(k).second) dirty_ = true;
    lastUse_[k] = tick_;
}

void LightAtlas::end_requests() {
    ++tick_;
    if (keys_.empty() || (tick_ & 31u) != 0) return;
    bool forgot = false;
    for (auto it = keys_.begin(); it != keys_.end();) {
        if (tick_ - lastUse_[*it] > kKeyIdleTicks) {
            lastUse_.erase(*it);
            tiles_.erase(*it);
            it = keys_.erase(it);
            forgot = true;
        } else {
            ++it;
        }
    }
    if (!forgot) return;
    dirty_ = true;
    if (keys_.empty() && !needLtc_ &&
        view_.id) {  // nothing left to show: the image goes (after the frame that used it)
        retired_.push_back({image_, view_});
        image_ = {};
        view_ = {};
        layout_ = {};
        dirty_ = false;
    }
}

bool LightAtlas::invalidate(const std::string& path) {
    bool hit = false;
    for (auto kind : {LightAtlasKind::Cookie, LightAtlasKind::Ies, LightAtlasKind::CookieCube}) {
        LightAtlasKey k{kind, path};
        if (keys_.count(k)) {
            tiles_.erase(k);
            dirty_ = true;
            hit = true;
        }
    }
    return hit;
}

void LightAtlas::invalidate_all() {
    if (!keys_.empty() || needLtc_) dirty_ = true;
    tiles_.clear();
}

const LightAtlasRect* LightAtlas::rect(LightAtlasKind kind, const std::string& path) const {
    if (!view_.id) return nullptr;
    return layout_.find(LightAtlasKey{kind, path});
}

bool LightAtlas::sync(const Loader& load, const FailureFn& onFailure) {
    if (!dirty_) return view_.id != 0;
    dirty_ = false;
    if (unsupported_ || (!needLtc_ && keys_.empty())) return view_.id != 0;
    if (!sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F).filter) {
        unsupported_ = true;
        FA_WARN("render", "this GPU cannot filter RGBA16F textures, which the light atlas (area lights, cookies, IES "
                          "profiles) needs: area "
                          "lights shine like point lights and cookies and profiles are ignored.");
        return false;
    }
    // The tiles the layout needs: loaded (and baked) once each, again after invalidate().
    for (const LightAtlasKey& k : keys_) {
        if (tiles_.count(k)) continue;
        LightAtlasSource src = load(k);
        if (!src.ok) {
            if (onFailure) onFailure(k, src.error, src.hint);
            tiles_[k] = k.kind == LightAtlasKind::Cookie       ? bake_white_tile(kCookieTile, kCookieTile)
                        : k.kind == LightAtlasKind::CookieCube ? bake_white_tile(kCookieCubeW, kCookieCubeH)
                                                               : bake_white_tile(kIesTileW, kIesTileH);
        } else {
            tiles_[k] = k.kind == LightAtlasKind::Cookie       ? bake_cookie_tile(src.cookie)
                        : k.kind == LightAtlasKind::CookieCube ? bake_cookie_cube_tile(src.cookie)
                                                               : bake_ies_tile(src.ies);
        }
    }
    LightAtlasLayout layout = layout_light_atlas(std::vector<LightAtlasKey>(keys_.begin(), keys_.end()));
    if (layout.dropped > 0)
        FA_WARN("render",
                "{} light cookies or IES profiles do not fit the light atlas ({} rows of {} texels at most): the "
                "lights that "
                "use them are drawn without. Hint: use fewer different cookies and profiles.",
                layout.dropped, kLightAtlasMaxHeight, kLightAtlasWidth);
    const std::vector<std::uint16_t> pixels = assemble_light_atlas(layout, tiles_);
    sg_image_desc d{};
    d.width = kLightAtlasWidth;
    d.height = layout.height;
    d.pixel_format = SG_PIXELFORMAT_RGBA16F;
    d.data.mip_levels[0] = {pixels.data(), pixels.size() * sizeof(std::uint16_t)};
    d.label = "light-atlas";
    const sg_image image = make_image(d);
    if (sg_query_image_state(image) != SG_RESOURCESTATE_VALID) {
        if (image.id) sg_destroy_image(image);
        unsupported_ = true;
        FA_WARN("render",
                "the GPU could not make the {}x{} light atlas: area lights shine like point lights, cookies and "
                "profiles are ignored.",
                d.width, d.height);
        return false;
    }
    sg_view_desc vd{};
    vd.texture.image = image;
    vd.label = "light-atlas";
    const sg_view view = sg_make_view(&vd);
    // The image the earlier views of this frame were recorded with stays alive until the frame has run.
    if (image_.id) retired_.push_back({image_, view_});
    image_ = image;
    view_ = view;
    layout_ = std::move(layout);
    ++bakes_;
    return true;
}

void LightAtlas::free_retired() {
    for (Retired& r : retired_) {
        if (r.view.id) sg_destroy_view(r.view);
        if (r.image.id) sg_destroy_image(r.image);
    }
    retired_.clear();
}

void LightAtlas::destroy() {
    free_retired();
    if (view_.id) sg_destroy_view(view_);
    if (image_.id) sg_destroy_image(image_);
    view_ = {};
    image_ = {};
    layout_ = {};
    tiles_.clear();
    dirty_ = !keys_.empty() || needLtc_;
}

}  // namespace fa::render
