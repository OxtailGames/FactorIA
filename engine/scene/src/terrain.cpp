#include "fa/scene/terrain.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstring>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/scene/world.h"

namespace fa {

namespace {

std::atomic<std::uint64_t> g_nextId{1};

bool is_power_of_two(int v) { return v > 0 && (v & (v - 1)) == 0; }

std::string valid_sizes_text() {
    std::string s;
    for (int n = kTerrainMinSamples; n <= kTerrainMaxSamples; n = (n - 1) * 2 + 1)
        s += (s.empty() ? "" : ", ") + std::to_string(n);
    return s;
}

bool ends_with_ci(std::string_view s, std::string_view suffix) {
    if (s.size() < suffix.size()) return false;
    for (std::size_t i = 0; i < suffix.size(); ++i) {
        char a = s[s.size() - suffix.size() + i], b = suffix[i];
        if (a >= 'A' && a <= 'Z') a = char(a - 'A' + 'a');
        if (a != b) return false;
    }
    return true;
}

// The grid of `n` samples per side from `src` (`w` x `w`: n == w, or n == w + 1 with the last row and column repeated).
std::shared_ptr<TerrainHeights> make_heights(const std::uint16_t* src, int w, int n) {
    auto h = std::make_shared<TerrainHeights>();
    h->samples = n;
    h->id = g_nextId.fetch_add(1);
    h->data.resize(std::size_t(n) * std::size_t(n));
    for (int r = 0; r < n; ++r) {
        const int sr = std::min(r, w - 1);
        for (int c = 0; c < n; ++c)
            h->data[std::size_t(r) * std::size_t(n) + std::size_t(c)] =
                src[std::size_t(sr) * std::size_t(w) + std::size_t(std::min(c, w - 1))];
    }
    return h;
}

}  // namespace

void TerrainRect::join(const TerrainRect& o) {
    if (o.empty()) return;
    if (empty()) {
        *this = o;
        return;
    }
    c0 = std::min(c0, o.c0);
    r0 = std::min(r0, o.r0);
    c1 = std::max(c1, o.c1);
    r1 = std::max(r1, o.r1);
}

void TerrainHeights::set(int c, int r, std::uint16_t v) {
    if (c < 0 || r < 0 || c >= samples || r >= samples) return;
    data[std::size_t(r) * std::size_t(samples) + std::size_t(c)] = v;
}

void TerrainHeights::mark_dirty(TerrainRect rect) {
    rect.c0 = std::max(rect.c0, 0);
    rect.r0 = std::max(rect.r0, 0);
    rect.c1 = std::min(rect.c1, samples - 1);
    rect.r1 = std::min(rect.r1, samples - 1);
    if (rect.empty()) return;
    ++version;
    edits_.push_back({version, rect});
    if (edits_.size() > kEditHistory) {
        oldestKept_ = edits_.front().version;
        edits_.erase(edits_.begin());
    }
}

bool TerrainHeights::dirty_since(std::uint64_t sinceVersion, TerrainRect& out) const {
    out = TerrainRect{};
    if (sinceVersion >= version) return true;
    if (sinceVersion < oldestKept_) return false;
    for (const Edit& e : edits_)
        if (e.version > sinceVersion) out.join(e.rect);
    return true;
}

std::shared_ptr<TerrainHeights> TerrainHeights::flat(int n, std::uint16_t raw) {
    auto h = std::make_shared<TerrainHeights>();
    h->samples = n;
    h->id = g_nextId.fetch_add(1);
    h->data.assign(std::size_t(n) * std::size_t(n), raw);
    return h;
}

Result<int> terrain_grid_samples(int width, int height, std::string_view what) {
    if (width != height)
        return make_error(
            std::format("Terrain heightmap '{}' is {} x {} samples, but a terrain heightmap must be square", what,
                        width, height),
            "Crop or resize the image to a square. Sizes that work: " + valid_sizes_text() +
                " (2^n + 1), or one less (a power of two: the last row and column are repeated).");
    if (width > kTerrainMaxSamples)
        return make_error(
            std::format(
                "Terrain heightmap '{}' is {} x {} samples, more than the {} x {} ({} million samples) a terrain "
                "is built from",
                what, width, width, kTerrainMaxSamples, kTerrainMaxSamples,
                std::int64_t(kTerrainMaxSamples) * kTerrainMaxSamples / 1000000),
            "Resize the heightmap to " + std::to_string(kTerrainMaxSamples) + " x " +
                std::to_string(kTerrainMaxSamples) +
                " or less (one terrain covers up to 100 km: 4097 samples are one every 24 m there), or split the world "
                "into several terrains.");
    if (width >= kTerrainMinSamples && is_power_of_two(width - 1)) return width;
    if (width >= kTerrainMinSamples - 1 && is_power_of_two(width)) return width + 1;
    return make_error(
        std::format("Terrain heightmap '{}' is {} x {} samples, but the side must be 2^n + 1 (or a power of two)", what,
                    width, width),
        "Resize the image to one of " + valid_sizes_text() +
            " (a power of two from 32 to 4096 also works: one row and column are added by repeating the last).");
}

Result<TerrainLoad> decode_terrain_heightmap(const std::uint8_t* data, std::size_t size, std::string_view name) {
    TerrainLoad out;
    if (ends_with_ci(name, ".r16")) {
        // Raw little-endian 16-bit samples, square: the side is the root of the sample count.
        if (size == 0 || size % 2 != 0)
            return make_error(
                std::format("Terrain heightmap '{}' has {} bytes, but a .r16 file holds 2 bytes per sample", name,
                            size),
                "Export the heightmap as raw 16-bit little-endian samples (a square, no header).");
        const std::uint64_t count = size / 2;
        std::uint64_t side = std::uint64_t(std::llround(std::sqrt(double(count))));
        while (side * side > count) --side;
        while ((side + 1) * (side + 1) <= count) ++side;
        if (side * side != count || side > 1000000)
            return make_error(
                std::format("Terrain heightmap '{}' holds {} samples, which is not a square", name, count),
                "A .r16 file is side x side samples (e.g. 1025 x 1025 = 1050625 samples = 2101250 bytes); its "
                "size gives the side.");
        auto n = terrain_grid_samples(int(side), int(side), name);
        if (!n) return n.error();
        std::vector<std::uint16_t> src(static_cast<std::size_t>(count));
        for (std::size_t i = 0; i < src.size(); ++i)  // little endian whatever this machine is
            src[i] = std::uint16_t(data[i * 2] | (data[i * 2 + 1] << 8));
        out.heights = make_heights(src.data(), int(side), *n);
        out.heights->source = std::string(name);
        return out;
    }
    // The budget from the header, before any sample is decoded.
    auto sz = image_size(data, size);
    if (!sz) return make_error(std::format("Terrain heightmap '{}': {}", name, sz.error().message), sz.error().hint);
    auto n = terrain_grid_samples(sz->width, sz->height, name);
    if (!n) return n.error();
    auto img = decode_gray16(data, size);
    if (!img) return make_error(std::format("Terrain heightmap '{}': {}", name, img.error().message), img.error().hint);
    if (img->width != sz->width || img->height != sz->height)
        return make_error(std::format("Terrain heightmap '{}' changed size while it was read", name),
                          "The file is damaged.");
    out.heights = make_heights(img->samples.data(), img->width, *n);
    out.heights->source = std::string(name);
    if (!img->sixteenBit) {
        out.heights->eightBit = true;
        out.warning = std::format("Terrain heightmap '{}' has 8 bits per sample: only 256 different heights, so slopes "
                                  "show as steps (terraces). "
                                  "Export it as a 16-bit greyscale PNG or a .r16 file for smooth ground.",
                                  name);
    }
    return out;
}

Result<TerrainLoad> load_terrain_heightmap(std::string_view path) {
    if (path.empty())
        return make_error("Terrain.heightmap is empty", "Set it to a 16-bit greyscale PNG or a .r16 file.");
    if (ends_with_ci(path, ".r16")) {
        const std::int64_t bytes = fs::file_size(path);
        const std::int64_t most = std::int64_t(kTerrainMaxSamples) * kTerrainMaxSamples * 2;
        if (bytes > most)
            return make_error(
                std::format("Terrain heightmap '{}' is {} bytes, more than the {} x {} samples ({} bytes) a "
                            "terrain is built from",
                            path, bytes, kTerrainMaxSamples, kTerrainMaxSamples, most),
                "Resize the heightmap to 4097 x 4097 samples or less, or split the world into several terrains.");
    }
    auto bytes = fs::read_bytes(path);
    if (!bytes)
        return make_error(
            std::format("Terrain heightmap '{}' cannot be read: {}", path, bytes.error().message),
            "Put the file in the project (for example assets/terrain/height.png) and set Terrain.heightmap to its "
            "project-relative path.");
    return decode_terrain_heightmap(bytes->data(), bytes->size(), path);
}

// ---- sampling ----

bool terrain_local_sample(const TerrainHeights& h, const Terrain3D& t, float localX, float localZ, float& height,
                          float& dhdx, float& dhdz) {
    if (!h.valid() || !(t.size.x > 0.0f) || !(t.size.y > 0.0f)) return false;
    const float cells = float(h.samples - 1);
    const float u = (localX / t.size.x + 0.5f) * cells, v = (localZ / t.size.y + 0.5f) * cells;
    if (!(u >= 0.0f && u <= cells && v >= 0.0f && v <= cells)) return false;  // also NaN
    const int c = std::min(int(u), h.samples - 2), r = std::min(int(v), h.samples - 2);
    const float fu = u - float(c), fv = v - float(r);
    const float k = t.heightScale / kTerrainRawMax;
    const float h00 = float(h.at(c, r)) * k, h01 = float(h.at(c + 1, r)) * k, h10 = float(h.at(c, r + 1)) * k,
                h11 = float(h.at(c + 1, r + 1)) * k;
    float dU, dV, y;  // metres per cell along the column and the row direction
    if (fv >= fu) {   // triangle (r, c), (r + 1, c), (r + 1, c + 1)
        dU = h11 - h10;
        dV = h10 - h00;
        y = h00 + (fv - fu) * dV + fu * (h11 - h00);
    } else {  // triangle (r, c), (r + 1, c + 1), (r, c + 1)
        dU = h01 - h00;
        dV = h11 - h01;
        y = h00 + fv * (h11 - h00) + (fu - fv) * dU;
    }
    height = t.heightOffset + y;
    dhdx = dU * cells / t.size.x;
    dhdz = dV * cells / t.size.y;
    return true;
}

bool terrain_sample(const World& world, Entity terrain, float worldX, float worldZ, TerrainSample& out) {
    const Terrain3D* t = world.get<Terrain3D>(terrain);
    if (!t) return false;
    auto heights = world.terrain().heights(world, terrain);
    if (!heights) return false;
    const Mat4 m = world.world_matrix(terrain);
    const Mat4 inv = m.inverse();
    const Vec3 local = inv.transform_point({worldX, m.translation().y, worldZ});
    float y, dx, dz;
    if (!terrain_local_sample(*heights, *t, local.x, local.z, y, dx, dz)) return false;
    const Vec3 world3 = m.transform_point({local.x, y, local.z});
    out.height = world3.y;
    // The normal of the surface y = f(x, z) is (-dx, 1, -dz); normals move with the inverse transpose of the matrix.
    const Vec3 n{-dx, 1.0f, -dz};
    Vec3 nw{inv.at(0, 0) * n.x + inv.at(0, 1) * n.y + inv.at(0, 2) * n.z,
            inv.at(1, 0) * n.x + inv.at(1, 1) * n.y + inv.at(1, 2) * n.z,
            inv.at(2, 0) * n.x + inv.at(2, 1) * n.y + inv.at(2, 2) * n.z};
    const float len = length(nw);
    out.normal = len > 1e-12f ? nw / len : Vec3{0, 1, 0};
    return true;
}

bool terrain_height_at(const World& world, Entity terrain, float worldX, float worldZ, float& height) {
    TerrainSample s;
    if (!terrain_sample(world, terrain, worldX, worldZ, s)) return false;
    height = s.height;
    return true;
}

// ---- the store ----

std::shared_ptr<TerrainHeights> TerrainStore::heights(const World& world, Entity e, std::string* problem) const {
    const Terrain3D* t = world.get<Terrain3D>(e);
    if (!t) return nullptr;
    std::lock_guard<std::mutex> lock(mutex_);
    Entry& entry = entries_[e.bits()];
    if (!entry.loaded || entry.key != t->heightmap) {
        entry = Entry{};
        entry.loaded = true;
        entry.key = t->heightmap;
        if (t->heightmap.empty()) {
            entry.heights = TerrainHeights::flat(kTerrainMinSamples);
        } else {
            auto load = load_terrain_heightmap(t->heightmap);
            if (!load) {
                entry.problem = std::format("entity '{}': Terrain.heightmap (/heightmap): {}. Hint: {}", world.id_of(e),
                                            load.error().message, load.error().hint);
                FA_ERROR("terrain", "{}", entry.problem);
            } else {
                entry.heights = load->heights;
                if (!load->warning.empty()) FA_WARN("terrain", "entity '{}': {}", world.id_of(e), load->warning);
            }
        }
    }
    if (problem) *problem = entry.problem;
    return entry.heights;
}

std::shared_ptr<TerrainHeights> TerrainStore::find(Entity e) const {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = entries_.find(e.bits());
    return it == entries_.end() ? nullptr : it->second.heights;
}

void TerrainStore::prune(const World& world) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto it = entries_.begin(); it != entries_.end();) {
        Entity e = Entity::from_bits(it->first);
        if (!world.alive(e) || !world.get<Terrain3D>(e))
            it = entries_.erase(it);
        else
            ++it;
    }
}

void TerrainStore::clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    entries_.clear();
}

std::size_t TerrainStore::size() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return entries_.size();
}

}  // namespace fa
